using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Player;
using UnityEngine.Build.Pipeline;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 从SBP构建流程中获取正确的Bundle 间的依赖关系(patch for sbp, unity changed manifest dep)
	/// </summary>
	public class OutPutAssetDependenceBundleMapTask : IBuildTask
	{
		int IBuildTask.Version => 1;
		
		// ReSharper disable InconsistentNaming
		// ReSharper disable ArrangeTypeMemberModifiers
		[InjectContext(ContextUsage.In)] IBuildParameters m_Parameters;
		[InjectContext(ContextUsage.In)] IDependencyData m_DependencyData;
		[InjectContext(ContextUsage.In, true)] IBundleExplictObjectLayout m_Layout;
		[InjectContext(ContextUsage.In)] IBundleWriteData m_WriteData;
		[InjectContext(ContextUsage.In)] IBundleBuildContent m_BuildContent;
		[InjectContext(ContextUsage.In, true)] IBuildLogger m_Log;
#if UNITY_2019_3_OR_NEWER
		[InjectContext(ContextUsage.In, true)] ICustomAssets m_CustomAssets;
#endif
		[InjectContext(ContextUsage.In, true)] IMarkedAsDryRun m_MarkedAsDryRun;
		// ReSharper disable once NotAccessedField.Local
		[InjectContext(ContextUsage.Out)] IDetailManifest m_DetailManifest;
		// ReSharper restore ArrangeTypeMemberModifiers
		// ReSharper restore InconsistentNaming

		private OutPutAssetDependenceBundleMapTask()
		{ }

		private static readonly Type MonoScriptType = typeof(MonoScript);
		private static readonly Type SpriteAtlasType = typeof(UnityEngine.U2D.SpriteAtlas);
        
		ReturnCode IBuildTask.Run()
		{
			var object2Bundle = new Dictionary<ObjectIdentifier, string>();
			var bundle2Object = new Dictionary<string, HashSet<ObjectIdentifier>>();
			var unityDefaultGuid = BuildTaskHelper.GetUnityDefaultResourceGuid();
			var copyInDifferentBundleObjects = new Dictionary<ObjectIdentifier, HashSet<string>>();

			var typeDb = m_Parameters.ScriptInfo;
			var buildTarget = m_Parameters.Target;

			var assetInfos = m_DependencyData.AssetInfo;
			var sceneInfos = m_DependencyData.SceneInfo;
	        
			var asset2Bundle = new Dictionary<GUID, string>();

			HashSet<GUID> customAssets = new HashSet<GUID>();
#if UNITY_2019_3_OR_NEWER
			if (m_CustomAssets != null)
				customAssets.UnionWith(m_CustomAssets.Assets);
#endif

			using (m_Log.ScopedStep(LogLevel.Info, $"collect info from {nameof(m_BuildContent.BundleLayout)}"))
			{
				foreach (var (bundleName, includeAssetsGuid) in m_BuildContent.BundleLayout)
				{
					if (BuildTaskHelper.ValidAssetBundle(includeAssetsGuid, customAssets))
					{
						foreach (var guid in includeAssetsGuid)
						{
							asset2Bundle.Add(guid, bundleName);
						}

						foreach (var guid in includeAssetsGuid)
						{
							if (!assetInfos.TryGetValue(guid, out var assetLoadInfo)) continue;
							foreach (var objectIdentifier in assetLoadInfo.includedObjects)
							{
								if (copyInDifferentBundleObjects.TryGetValue(objectIdentifier, out var bundleNames))
								{
									bundleNames.Add(bundleName);
									continue;
								}

								if (object2Bundle.TryGetValue(objectIdentifier, out var existedBundleName))
								{
									bundleNames = new HashSet<string>() { existedBundleName, bundleName };
									object2Bundle.Remove(objectIdentifier);
									copyInDifferentBundleObjects.Add(objectIdentifier, bundleNames);
								}
								else
								{
									object2Bundle.Add(objectIdentifier, bundleName);
								}
							}
						}
					}
					else if (BuildTaskHelper.ValidSceneBundle(includeAssetsGuid))
					{
						foreach (var guid in includeAssetsGuid)
						{
							asset2Bundle.Add(guid, bundleName);
						}
					}
				}
			}

			foreach (var (identifier, bundleName) in object2Bundle)
			{
				if (!bundle2Object.TryGetValue(bundleName, out var set))
				{
					set = new HashSet<ObjectIdentifier>();
					bundle2Object.Add(bundleName, set);
				}
				set.Add(identifier);
			}

			using (m_Log.ScopedStep(LogLevel.Info, $"collect info from {nameof(m_Layout.ExplicitObjectLocation)}"))
			{
				if (null != m_Layout && null != m_Layout.ExplicitObjectLocation &&
				    m_Layout.ExplicitObjectLocation.Count > 0)
				{
					m_Log.AddEntrySafe(LogLevel.Info, $"m_Layout.ExplicitObjectLocation.Count:{m_Layout.ExplicitObjectLocation.Count}");
					foreach (var (objectIdentifier, bundleName) in m_Layout.ExplicitObjectLocation)
					{
						copyInDifferentBundleObjects.Remove(objectIdentifier);
						if (object2Bundle.TryGetValue(objectIdentifier, out var oldBundleName))
						{
							if (bundle2Object.TryGetValue(oldBundleName, out var set))
							{
								set.Remove(objectIdentifier);
							}
						}

						if (!bundle2Object.TryGetValue(bundleName, out var objectIdentifiers))
						{
							objectIdentifiers = new HashSet<ObjectIdentifier>();
							bundle2Object.Add(bundleName, objectIdentifiers);
						}

						objectIdentifiers.Add(objectIdentifier);
						object2Bundle[objectIdentifier] = bundleName;
					}
				}
			}

			var bundleDepMap = new Dictionary<string, HashSet<string>>();

			using (m_Log.ScopedStep(LogLevel.Info, $"collect info from {nameof(m_DependencyData)}{nameof(m_DependencyData.SceneInfo)}"))
			{
				foreach (var (guid, sceneDependencyInfo) in sceneInfos)
				{
					if (!asset2Bundle.TryGetValue(guid, out var bundleName)) continue;
					var set = new HashSet<string>();
					bundleDepMap.Add(bundleName, set);
					foreach (var objectIdentifier in sceneDependencyInfo.referencedObjects)
					{
						if (objectIdentifier.guid == unityDefaultGuid) continue;
						if (copyInDifferentBundleObjects.ContainsKey(objectIdentifier)) continue;
						if (!object2Bundle.TryGetValue(objectIdentifier, out var depBundleName))
						{
							if (!CheckIsAllowedNoBundleAsset(in objectIdentifier, out var t, out var path))
							{
								//		UnityEngine.Debug.LogWarningFormat("objectIdentifier:{0}, type:{1}, path:{2} has no bundle, skip!", objectIdentifier, t, path);
							}

							continue;
						}

						set.Add(depBundleName);
					}

					var bundleDepObjects =
						ContentBuildInterface.GetPlayerDependenciesForObjects(
							sceneDependencyInfo.referencedObjects.ToArray(), buildTarget, typeDb,
							DependencyType.DefaultDependencies);
					foreach (var objectIdentifier in bundleDepObjects)
					{
						if (objectIdentifier.guid == unityDefaultGuid) continue;
						if (copyInDifferentBundleObjects.ContainsKey(objectIdentifier)) continue;
						if (!object2Bundle.TryGetValue(objectIdentifier, out var depBundleName))
						{
							if (!CheckIsAllowedNoBundleAsset(in objectIdentifier, out var t, out var path))
							{
								//		UnityEngine.Debug.LogWarningFormat("objectIdentifier:{0}, type:{1}, path:{2} has no bundle, skip!", objectIdentifier, t, path);
							}

							continue;
						}

						set.Add(depBundleName);
					}

					set.Remove(bundleName);
				}
			}

			using (m_Log.ScopedStep(LogLevel.Info, $"collect info from {nameof(bundle2Object)}"))
			{
				foreach (var (bundleName, objectIdentifiers) in bundle2Object)
				{
					var set = new HashSet<string>();
					bundleDepMap.Add(bundleName, set);
					var bundleDepObjects =
						ContentBuildInterface.GetPlayerDependenciesForObjects(objectIdentifiers.ToArray(), buildTarget,
							typeDb, DependencyType.DefaultDependencies);
					foreach (var objectIdentifier in bundleDepObjects)
					{
						if (objectIdentifier.guid == unityDefaultGuid) continue;
						if (copyInDifferentBundleObjects.ContainsKey(objectIdentifier)) continue;
						if (!object2Bundle.TryGetValue(objectIdentifier, out var depBundleName))
						{
							if (!CheckIsAllowedNoBundleAsset(in objectIdentifier, out var t, out var path))
							{
								//		UnityEngine.Debug.LogWarningFormat("objectIdentifier:{0}, type:{1}, path:{2} has no bundle, skip!", objectIdentifier, t, path);
							}

							continue;
						}

						set.Add(depBundleName);
					}

					set.Remove(bundleName);
				}
			}

			var detailManifest = new DetailManifest(m_MarkedAsDryRun!= null);
			foreach (var (bundleName, bundleDepBundleNames) in bundleDepMap)
			{
				detailManifest.GetOrAddBundleDepSet(bundleName).UnionWith(bundleDepBundleNames);
			}
			using (m_Log.ScopedStep(LogLevel.Info, $"PopDependenceInfos: {nameof(m_DependencyData)}.{nameof(m_DependencyData.AssetInfo)}"))
			{
				foreach (var (guid, info) in m_DependencyData.AssetInfo)
				{
					PopDependenceInfos(in guid, info.referencedObjects,
						detailManifest, buildTarget, typeDb, object2Bundle, m_Log);
				}
			}
			using (m_Log.ScopedStep(LogLevel.Info, $"PopDependenceInfos: {nameof(m_DependencyData)}.{nameof(m_DependencyData.SceneInfo)}"))
			{
				foreach (var (guid, info) in m_DependencyData.SceneInfo)
				{
					PopDependenceInfos(in guid, info.referencedObjects,
						detailManifest, buildTarget, typeDb, object2Bundle, m_Log);
				}
			}
			m_DetailManifest = detailManifest;
			return ReturnCode.Success;

			static void PopDependenceInfos(in GUID target
				, IReadOnlyCollection<ObjectIdentifier> refObjects
				, DetailManifest detailManifest
				, BuildTarget buildTarget
				, TypeDB typeDB
				, IReadOnlyDictionary<ObjectIdentifier, string> object2Bundle
				, IBuildLogger logger
			)
			{
				if (null == refObjects || refObjects.Count <= 0) return;
				using (logger.ScopedStep(LogLevel.Info, $"PopDependenceInfos for:{target}"))
				{
					var refObjectsArray = refObjects.ToArray();
					var assetPath = AssetDatabase.GUIDToAssetPath(target);
					var depBundleSet = detailManifest.GetOrAddAssetDepBundleSet(assetPath);
					var assetDepMap = detailManifest.GetOrAddAssetDepAssetsSet(assetPath);
					foreach (var objectIdentifier in refObjects)
					{
						if (object2Bundle.TryGetValue(objectIdentifier, out var bundleName))
						{
							depBundleSet.Add(bundleName);
						}

						assetDepMap.Add(AssetDatabase.GUIDToAssetPath(objectIdentifier.guid));
					}
					var reDepObjects = ContentBuildInterface.GetPlayerDependenciesForObjects(refObjectsArray,
						buildTarget, typeDB, DependencyType.DefaultDependencies);
					foreach (var objectIdentifier in reDepObjects)
					{
						if (object2Bundle.TryGetValue(objectIdentifier, out var bundleName))
						{
							depBundleSet.Add(bundleName);
						}
					}
				}
			}

			static bool CheckIsAllowedNoBundleAsset(in ObjectIdentifier objectIdentifier, out Type type, out string assetPath)
			{
				var t = BuildTaskHelper.GetCachedTypesForObject(in objectIdentifier);
				type = t[0];
				assetPath = AssetDatabase.GUIDToAssetPath(objectIdentifier.guid);
				if (type == MonoScriptType || type == SpriteAtlasType) return true;
				if (string.IsNullOrWhiteSpace(assetPath)) return true;
				if (assetPath.EndsWith(".spriteatlasv2", StringComparison.OrdinalIgnoreCase) 
				    || assetPath.EndsWith(".spriteatlas", StringComparison.Ordinal)) return true;
				return false;
			}
		}

		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks)
		{
			if (null == buildTasks) 
			{
				return false;
			}
			var ret =  BuildTaskHelper.AttachBuildTask<OutPutAssetDependenceBundleMapTask, UnityEditor.Build.Pipeline.Tasks.WriteSerializedFiles>(buildTasks,
				() => new OutPutAssetDependenceBundleMapTask(), false);
			return ret;
		}

		private class DetailManifest : IDetailManifest
		{
			private readonly Dictionary<string, HashSet<string>> _bundle2Dep = new Dictionary<string, HashSet<string>>();

			private readonly Dictionary<string, IReadOnlyCollection<string>> _outPutMap =
				new Dictionary<string, IReadOnlyCollection<string>>();

			private readonly bool _dryRunMode;

			IReadOnlyDictionary<string, IReadOnlyCollection<string>> IDetailManifest.Bundle2Dep => _outPutMap;

			private readonly Dictionary<string, HashSet<string>> _asset2DepBundle =
				new Dictionary<string, HashSet<string>>();
			private readonly Dictionary<string, IReadOnlyCollection<string>> _outPutAsset2DepBundle =
				new Dictionary<string, IReadOnlyCollection<string>>();
			IReadOnlyDictionary<string, IReadOnlyCollection<string>> IDetailManifest.Asset2DepBundle => _outPutAsset2DepBundle;
            
			private readonly Dictionary<string, HashSet<string>> _asset2DepAsset =
				new Dictionary<string, HashSet<string>>();
			private readonly Dictionary<string, IReadOnlyCollection<string>> _outPutAsset2DepAsset =
				new Dictionary<string, IReadOnlyCollection<string>>();
			IReadOnlyDictionary<string, IReadOnlyCollection<string>> IDetailManifest.Asset2DepAsset => _outPutAsset2DepAsset;

			public DetailManifest(bool dryRunMode)
			{
				_dryRunMode = dryRunMode;
			}
            
			public ISet<string> GetOrAddBundleDepSet(string bundleName)
			{
				if (_bundle2Dep.TryGetValue(bundleName, out var ret)) return ret;
				ret = new HashSet<string>();
				_bundle2Dep.Add(bundleName, ret);
				_outPutMap.Add(bundleName, ret);
				return ret;
			}
            
			public ISet<string> GetOrAddAssetDepAssetsSet(string assetPath)
			{
				if (_asset2DepAsset.TryGetValue(assetPath, out var ret)) return ret;
				ret = new HashSet<string>();
				_asset2DepAsset.Add(assetPath, ret);
				_outPutAsset2DepAsset.Add(assetPath, ret);
				return ret;
			}

			public ISet<string> GetOrAddAssetDepBundleSet(string assetPath)
			{
				if (_asset2DepBundle.TryGetValue(assetPath, out var ret)) return ret;
				ret = new HashSet<string>();
				_asset2DepBundle.Add(assetPath, ret);
				_outPutAsset2DepBundle.Add(assetPath, ret);
				return ret;
			}

			Dictionary<string, BundleDetails> IDetailManifest.PatchForManifest(
				Dictionary<string, BundleDetails> bundleDetailsMap)
			{
				var ret = new Dictionary<string, BundleDetails>();
				if (_dryRunMode)
				{
					foreach (var kv in _outPutMap)
					{
						var detail = new BundleDetails();
						var array = kv.Value.ToArray();
						Array.Sort(array, StringComparer.Ordinal);
						detail.Dependencies = array;
						ret[kv.Key] = detail;
					}
				}
				else
				{
					var sb = new StringBuilder();
					foreach (var (bundleName, bundleDetails) in bundleDetailsMap)
					{
						var detail = bundleDetails;
						if (_outPutMap.TryGetValue(bundleName, out var set))
						{
							var array = set.ToArray();
							if (array.Length != bundleDetails.Dependencies.Length)
							{
								sb.AppendFormat("PatchForManifest:Bundle {0} Dependencies:{1}->{2}\n", bundleName, bundleDetails.Dependencies.Length, array.Length);
							}
							Array.Sort(array, StringComparer.Ordinal);
							detail.Dependencies = array;
						}

						ret[bundleName] = detail;
					}
					UnityEngine.Debug.LogFormat("PatchForManifest List:\n{0}", sb.ToString());
				}
				return ret;
			}
		}
	}
}
