using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEngine;
using PostDependencyCallback = UnityEditor.Build.Pipeline.Tasks.PostDependencyCallback;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 对于 StaticResource 路径下的资源， 若其被显式指定入bundle的资源依赖且其被依赖的数量大于1 则为其分配一个基于其资源路径的bundle
	/// </summary>
	public class AutoGenerateStaticBundleByReferencesTask : IBuildTask
	{
		int IBuildTask.Version => 2;
	    
		// ReSharper disable ArrangeTypeMemberModifiers
		// ReSharper disable InconsistentNaming
		[InjectContext(ContextUsage.In)] IBuildParameters m_Parameters;
		[InjectContext(ContextUsage.In, true)] IMarkStaticBundleProcessRule m_StaticBundleGenerateRule;
		[InjectContext(ContextUsage.In, true)] IBuildLogger m_Log;
		// ReSharper disable once RedundantArgumentDefaultValue
		[InjectContext(ContextUsage.InOut)] IBundleBuildContent m_BuildContent;
		// ReSharper disable once RedundantArgumentDefaultValue
		[InjectContext(ContextUsage.InOut)] IDependencyData m_DependencyData;
		[InjectContext(ContextUsage.InOut, true)] IBundleExplictObjectLayout m_Layout;
		// ReSharper restore InconsistentNaming
		// ReSharper restore ArrangeTypeMemberModifiers

		private readonly Func<string, AssetBundleBuildGenerator.SourceType, bool?, string> _bundleNameGetter;
		private readonly IReadOnlyDictionary<GUID, string> _mappedAssets;
		private readonly bool _splitInPackAndOta;

		private AutoGenerateStaticBundleByReferencesTask(Func<string, AssetBundleBuildGenerator.SourceType, bool?, string> bundleNameGetter, IReadOnlyDictionary<GUID, string> mappedAssets, bool splitInPackAndOta)
		{
			_bundleNameGetter = bundleNameGetter;
			_mappedAssets = mappedAssets;
			_splitInPackAndOta = splitInPackAndOta;
		}
	    
		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks, Func<string, AssetBundleBuildGenerator.SourceType, bool?, string> bundleNameGetter, IReadOnlyDictionary<GUID, string> mappedAssets, bool splitInPackAndOta)
		{
			if (null == buildTasks) return false;
			if (null == bundleNameGetter) return false;
			var ret = BuildTaskHelper.AttachBuildTask<AutoGenerateStaticBundleByReferencesTask, PostDependencyCallback>(buildTasks,
				() => new AutoGenerateStaticBundleByReferencesTask(bundleNameGetter, mappedAssets, splitInPackAndOta), true);
			return ret;
		}

		ReturnCode IBuildTask.Run()
		{
			var generateRule = m_StaticBundleGenerateRule?.UseRule ?? default;
			var refLog = m_StaticBundleGenerateRule?.RefDetail ?? new Dictionary<string, StaticBundleIncludedDetail>();
			var guid2Bundle = new Dictionary<GUID, string>();
			ISet<GUID> byRefInPack = null;
			if (_splitInPackAndOta)
			{
				var needInPackGuids = new HashSet<GUID>();
				byRefInPack = new HashSet<GUID>();

				foreach (var (bundleName,inBundleAssets) in m_BuildContent.BundleLayout)
				{
					foreach (var inBundleAsset in inBundleAssets)
					{
						guid2Bundle[inBundleAsset] = bundleName;
					}
					if (!bundleName.StartsWith(AssetBundleBuildGenerator.InPackPreFix)) continue;
					needInPackGuids.UnionWith(inBundleAssets);
				}
				foreach (var needInPackGuid in needInPackGuids)
				{
					if (m_DependencyData.AssetInfo.TryGetValue(needInPackGuid, out var info))
					{
						byRefInPack.UnionWith(ContentBuildInterface.GetPlayerDependenciesForObjects(info.includedObjects.ToArray(), m_Parameters.Target, m_Parameters.ScriptInfo).Select(t=>t.guid));
					}
					if (m_DependencyData.SceneInfo.TryGetValue(needInPackGuid, out var sceneInfo))
					{
						var guidArray = sceneInfo.referencedObjects.ToArray();
						byRefInPack.UnionWith(byRefInPack);
						byRefInPack.UnionWith(ContentBuildInterface.GetPlayerDependenciesForObjects(guidArray, m_Parameters.Target, m_Parameters.ScriptInfo).Select(t=>t.guid));
					}
				}
			}
			else
			{
				foreach (var (bundleName,inBundleAssets) in m_BuildContent.BundleLayout)
				{
					foreach (var inBundleAsset in inBundleAssets)
					{
						guid2Bundle[inBundleAsset] = bundleName;
					}
				}
			}

			var staticResourcePaths = AssetPathProvider.GetStaticResourcesFolders().Select(t =>
			{
				if (!t.EndsWith('/')) return t + '/';
				return t;
			}).ToArray();
			var allGuids = new HashSet<GUID>();
			using (m_Log.ScopedStep(LogLevel.Info, "collect all guids"))
			{
				using (m_Log.ScopedStep(LogLevel.Info, "collect from m_DependencyData AssetInfo and SceneInfo"))
				{
					allGuids.UnionWith(m_DependencyData.AssetInfo.Keys);
					allGuids.UnionWith(m_DependencyData.SceneInfo.Keys);
				}
				m_Log.AddEntrySafe(LogLevel.Info, $"collect all guids count:{allGuids.Count}");//0
				using (m_Log.ScopedStep(LogLevel.Info, "collect from m_DependencyData AssetInfo.includedObjects"))
				{
					allGuids.UnionWith(m_DependencyData.AssetInfo.SelectMany(t=>t.Value.includedObjects.Select(r=>r.guid)));
				}
				m_Log.AddEntrySafe(LogLevel.Info, $"collect all guids count:{allGuids.Count}");//1
				using (m_Log.ScopedStep(LogLevel.Info, "collect from m_DependencyData AssetInfo.referencedObjects"))
				{
					allGuids.UnionWith(m_DependencyData.AssetInfo.SelectMany(t=>t.Value.referencedObjects.Select(r=>r.guid)));
				}
				m_Log.AddEntrySafe(LogLevel.Info, $"collect all guids count:{allGuids.Count}");//2
				using (m_Log.ScopedStep(LogLevel.Info, "collect from m_DependencyData SceneInfo.referencedObjects"))
				{
					allGuids.UnionWith(m_DependencyData.SceneInfo.SelectMany(t=>t.Value.referencedObjects.Select(r=>r.guid)));
				}
				m_Log.AddEntrySafe(LogLevel.Info, $"collect all guids count:{allGuids.Count}");//3
				allGuids.ExceptWith(_mappedAssets.Keys);
				m_Log.AddEntrySafe(LogLevel.Info, $"collect all guids, ExceptWith {nameof(_mappedAssets)}:{_mappedAssets.Count}  count:{allGuids.Count}");//4
			}

			foreach (var mappedAsset in _mappedAssets)
			{
				guid2Bundle[mappedAsset.Key] = mappedAsset.Value;
			}

			if (null != m_Layout)
			{
				foreach (var (identifier, bundleName) in m_Layout.ExplicitObjectLocation)
				{
					guid2Bundle[identifier.guid] = bundleName;
				}
			}

			var referenceAssetsMap = new Dictionary<GUID, HashSet<string>>();
			using (m_Log.ScopedStep(LogLevel.Info, "prepare referenceAssetsMap"))
			{
				foreach (var guid in allGuids)
				{
					var assetPath = AssetDatabase.GUIDToAssetPath(guid);
					if (string.IsNullOrWhiteSpace(assetPath)) continue;
					if (!staticResourcePaths.Any(p => assetPath.StartsWith(p, StringComparison.OrdinalIgnoreCase)))
						continue;
					referenceAssetsMap[guid] = new HashSet<string>();
				}

				foreach (var (guid, assetLoadInfo) in m_DependencyData.AssetInfo)
				{
					foreach (var referencedObject in assetLoadInfo.referencedObjects)
					{
						if (!referenceAssetsMap.TryGetValue(referencedObject.guid, out var refCount)) continue;
						if (!guid2Bundle.TryGetValue(guid, out var bundleName)) continue;
						refCount.Add(bundleName);
					}
				}

				foreach (var (guid, sceneDependencyInfo) in m_DependencyData.SceneInfo)
				{
					foreach (var referencedObject in sceneDependencyInfo.referencedObjects)
					{
						if (!referenceAssetsMap.TryGetValue(referencedObject.guid, out var refCount)) continue;
						if (!guid2Bundle.TryGetValue(guid, out var bundleName)) continue;
						refCount.Add(bundleName);
					}
				}
			}

			m_Layout ??= new BundleExplictObjectLayout();
			
			int refCountLimit;
			switch (generateRule)
			{
				case BundleProcessRule.OnlyReferencedAndRefAboveOneAssetGenerateBundleByFolder:
					Debug.Log("===== static bundle 生成规则, 复引用模式");
					refCountLimit = 2;
					break;
				case BundleProcessRule.OnlyReferencedAssetGenerateBundleByFolder:
					Debug.Log("===== static bundle 生成规则, 仅引用模式");
					refCountLimit = 1;
					break;
				case BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset:
					Debug.Log("===== static bundle 生成规则, 连带模式");
					refCountLimit = 1;
					break;
				default:
					throw new ArgumentOutOfRangeException();
			}

			using (m_Log.ScopedStep(LogLevel.Info, $"generateRule static bundle by rule:{generateRule}"))
			{
				switch (generateRule)
				{
					case BundleProcessRule.OnlyReferencedAndRefAboveOneAssetGenerateBundleByFolder:
					case BundleProcessRule.OnlyReferencedAssetGenerateBundleByFolder:
					{
						foreach (var (guid, refCount) in referenceAssetsMap)
						{
							if (refCount.Count < refCountLimit) continue;
							var assetPath = AssetDatabase.GUIDToAssetPath(guid);
							var bundleName = _bundleNameGetter(assetPath,
								AssetBundleBuildGenerator.SourceType.StaticResources,
								_splitInPackAndOta ? byRefInPack?.Contains(guid) : null);
							if (string.IsNullOrWhiteSpace(bundleName)) continue;
							var includedObjects =
								ContentBuildInterface.GetPlayerObjectIdentifiersInAsset(guid, m_Parameters.Target);
							foreach (var infoIncludedObject in includedObjects)
							{
								if (m_Layout.ExplicitObjectLocation.ContainsKey(infoIncludedObject)) continue;
								m_Layout.ExplicitObjectLocation.Add(infoIncludedObject, bundleName);
							}

							if (!m_BuildContent.BundleLayout.TryGetValue(bundleName, out var inBundleGuids))
							{
								inBundleGuids = new List<GUID>();
								m_BuildContent.BundleLayout.Add(bundleName, inBundleGuids);
							}

							if (!inBundleGuids.Contains(guid)) inBundleGuids.Add(guid);
							if (!m_BuildContent.Addresses.ContainsKey(guid))
								m_BuildContent.Addresses[guid] = string.Empty;
							AppendToAssetInfoDic(guid, includedObjects);
							if (!refLog.TryGetValue(bundleName, out var detail))
							{
								detail = new StaticBundleIncludedDetail();
								refLog.Add(bundleName, detail);
							}

							detail.ReferencedAssets.TryGetValue(assetPath, out var sourceRefCount);
							sourceRefCount += refCount.Count;
							detail.ReferencedAssets[assetPath] = sourceRefCount;
						}
					}
						break;
					case BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset:
					{
						var willPackBundle = new HashSet<string>();
						var assetGroupByPreSetBundleNameDic = new Dictionary<string, HashSet<GUID>>();
						var staticResourceAllGuids = AssetDatabase.FindAssets(string.Empty,
							staticResourcePaths.Select(f => f.TrimEnd('/')).ToArray()).Select(g => new GUID(g));
						var refSourceGuids = new HashSet<GUID>();
						foreach (var guid in staticResourceAllGuids)
						{
							var assetPath = AssetDatabase.GUIDToAssetPath(guid);
							if (AssetDatabase.IsValidFolder(assetPath)) continue;
							var bundleName = _bundleNameGetter(assetPath,
								AssetBundleBuildGenerator.SourceType.StaticResources,
								_splitInPackAndOta ? byRefInPack?.Contains(guid) : null);
							if (string.IsNullOrWhiteSpace(bundleName)) continue;
							if (!assetGroupByPreSetBundleNameDic.TryGetValue(bundleName, out var set))
							{
								set = new HashSet<GUID>();
								assetGroupByPreSetBundleNameDic.Add(bundleName, set);
							}

							set.Add(guid);
							if (!referenceAssetsMap.TryGetValue(guid, out var refSet) || refSet.Count < refCountLimit)
								continue;
							willPackBundle.Add(bundleName);
							if (!refLog.TryGetValue(bundleName, out var detail))
							{
								detail = new StaticBundleIncludedDetail();
								refLog.Add(bundleName, detail);
							}

							detail.ReferencedAssets.TryGetValue(assetPath, out var refCount);
							refCount += refSet.Count;
							detail.ReferencedAssets[assetPath] = refCount;
							refSourceGuids.Add(guid);
						}

						var refSourceGuidsIncludeObjectIdentifier = new HashSet<ObjectIdentifier>();
						foreach (var refSourceGuid in refSourceGuids)
						{
							refSourceGuidsIncludeObjectIdentifier.UnionWith(
								ContentBuildInterface.GetPlayerObjectIdentifiersInAsset(refSourceGuid,
									m_Parameters.Target));
						}

						var skipRefByHasRefCountStaticAsset = new HashSet<GUID>();
						skipRefByHasRefCountStaticAsset.UnionWith(ContentBuildInterface
							.GetPlayerDependenciesForObjects(refSourceGuidsIncludeObjectIdentifier.ToArray(),
								m_Parameters.Target, m_Parameters.ScriptInfo).Select(t => t.guid));
						var shaderType = typeof(Shader);
						var scriptType = typeof(MonoScript);
						foreach (var bundleName in willPackBundle)
						{
							var assetsGuids = assetGroupByPreSetBundleNameDic[bundleName];
							if (!m_BuildContent.BundleLayout.TryGetValue(bundleName, out var inBundleGuids))
							{
								inBundleGuids = new List<GUID>();
								m_BuildContent.BundleLayout.Add(bundleName, inBundleGuids);
							}

							refLog.TryGetValue(bundleName, out var detail);
							foreach (var guid in assetsGuids)
							{
								var includedObjects =
									ContentBuildInterface.GetPlayerObjectIdentifiersInAsset(guid, m_Parameters.Target);
								foreach (var infoIncludedObject in includedObjects)
								{
									if (m_Layout.ExplicitObjectLocation.ContainsKey(infoIncludedObject)) continue;
									m_Layout.ExplicitObjectLocation.Add(infoIncludedObject, bundleName);
								}

								if (!inBundleGuids.Contains(guid)) inBundleGuids.Add(guid);
								if (!m_BuildContent.Addresses.ContainsKey(guid))
									m_BuildContent.Addresses[guid] = string.Empty;
								AppendToAssetInfoDic(guid, includedObjects);
								if (detail == null || refSourceGuids.Contains(guid)) continue;
								var usageTypes = BuildTaskHelper.GetMainTypeForObjects(includedObjects);
								if (usageTypes is { Length: > 0 } &&
								    ((usageTypes[0] == shaderType) || (usageTypes[0] == scriptType))) continue;
								var path = AssetDatabase.GUIDToAssetPath(guid);
								if (string.IsNullOrEmpty(path)) continue;
								if (skipRefByHasRefCountStaticAsset.Contains(guid))
								{
									detail.ReferencedByAssets.Add(path);
								}
								else
								{
									detail.NotReferencedAssets.Add(path);
								}
							}
						}
					}
						break;
				}
			}
			if (m_Layout.ExplicitObjectLocation.Count <= 0)
				m_Layout = null;
			return ReturnCode.Success;
		}
		
		private void AppendToAssetInfoDic(GUID guid, ObjectIdentifier[] includedObjects)
		{
			if (m_DependencyData.AssetInfo.ContainsKey(guid)) return;
			using (m_Log.ScopedStep(LogLevel.Info, $"AppendToAssetInfoDic:{guid}, includedObjects.Count:{includedObjects?.Length ?? 0}"))
			{
				var assetInfo = new AssetLoadInfo();
				assetInfo.asset = guid;
				assetInfo.includedObjects = new List<ObjectIdentifier>(includedObjects);
				ObjectIdentifier[] referencedObjects;
				if (m_Parameters.NonRecursiveDependencies)
				{
					referencedObjects = ContentBuildInterface.GetPlayerDependenciesForObjects(includedObjects,
						m_Parameters.Target, m_Parameters.ScriptInfo, DependencyType.ValidReferences);
					referencedObjects = BuildTaskHelper.FilterReferencedObjectIDs(guid, referencedObjects,
						m_Parameters.Target, m_Parameters.ScriptInfo, new HashSet<GUID>(m_BuildContent.Assets));
				}
				else
				{
					referencedObjects = ContentBuildInterface.GetPlayerDependenciesForObjects(includedObjects,
						m_Parameters.Target, m_Parameters.ScriptInfo);
				}

				assetInfo.referencedObjects = new List<ObjectIdentifier>(referencedObjects);
				m_DependencyData.AssetInfo.Add(guid, assetInfo);
				if (m_DependencyData.AssetUsage.ContainsKey(guid)) return;
				using (m_Log.ScopedStep(LogLevel.Info, "create AssetUsage includedObjects"))
				{
					var usageTags = new BuildUsageTagSet();
					var allObjects = new List<ObjectIdentifier>(includedObjects);
					allObjects.AddRange(referencedObjects);
					ContentBuildInterface.CalculateBuildUsageTags(allObjects.ToArray(), includedObjects,
						m_DependencyData.GlobalUsage, usageTags, m_DependencyData.DependencyUsageCache);
					m_DependencyData.AssetUsage.Add(guid, usageTags);
				}
			}
		}
	}
}
