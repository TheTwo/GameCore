using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using DragonReborn.CSharpReflectionTool;
using Newtonsoft.Json;
using UnityEditor;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Pipeline.Tasks;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 收集记录被隐式依赖导致进入bundle 的资源
	/// </summary>
	public class CollectImplicitDependenciesAssetsTask : IBuildTask
	{
		int IBuildTask.Version => 1;
		
		// ReSharper disable InconsistentNaming
		// ReSharper disable ArrangeTypeMemberModifiers
		[InjectContext(ContextUsage.In)] IDependencyData m_DependencyData;
		// ReSharper disable once NotAccessedField.Local
		[InjectContext(ContextUsage.Out)] IImplicitDependenciesAssets m_implicitDependenciesAssets;
		// ReSharper restore ArrangeTypeMemberModifiers

		private readonly IReadOnlyDictionary<GUID, string> _explicitAssetsGuid2BundleName;

		private CollectImplicitDependenciesAssetsTask(IReadOnlyDictionary<GUID, string> guids)
		{
			_explicitAssetsGuid2BundleName = new Dictionary<GUID, string>(guids);
		}

		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks, IReadOnlyDictionary<GUID, string> explicitAssetsGuids)
		{
			if (null == buildTasks) return false;
			if (explicitAssetsGuids?.Count <= 0) return false;
			var ret = BuildTaskHelper.AttachBuildTask<CollectImplicitDependenciesAssetsTask, PostDependencyCallback>(buildTasks,
				() => new CollectImplicitDependenciesAssetsTask(explicitAssetsGuids), false);
			return ret;
		}

		ReturnCode IBuildTask.Run()
		{
			var skipScriptType = typeof(MonoScript);
			var skipShaderType = typeof(UnityEngine.Shader);
			var unityDefaultGuid = BuildTaskHelper.GetUnityDefaultResourceGuid();
			var outPut = new WriteImplicitDependenciesAssets();
			foreach (var (refSourceAssetGuid, assetLoadInfo) in  m_DependencyData.AssetInfo)
			{
				if (unityDefaultGuid == refSourceAssetGuid) continue;
				if (!_explicitAssetsGuid2BundleName.TryGetValue(refSourceAssetGuid, out var bundleName))
				{
					continue;
				}
				var assetPath = AssetDatabase.GUIDToAssetPath(refSourceAssetGuid);
				foreach (var valueReferencedObject in assetLoadInfo.referencedObjects)
				{
					var guid = valueReferencedObject.guid;
					if (unityDefaultGuid == guid) continue;
					if (_explicitAssetsGuid2BundleName.ContainsKey(guid)) continue;
					var usageTypes = BuildTaskHelper.GetCachedTypesForObject(in valueReferencedObject);
					if (usageTypes[0] == skipScriptType || usageTypes[0] == skipShaderType) continue;
					outPut.AddAssetRefInReason(AssetDatabase.GUIDToAssetPath(guid), assetPath, bundleName, usageTypes);
				}
			}
			foreach (var (refSourceAssetGuid, sceneDependencyInfo) in  m_DependencyData.SceneInfo)
			{
				if (unityDefaultGuid == refSourceAssetGuid) continue;
				if (!_explicitAssetsGuid2BundleName.TryGetValue(refSourceAssetGuid, out var bundleName))
				{
					continue;
				}
				var assetPath = AssetDatabase.GUIDToAssetPath(refSourceAssetGuid);
				foreach (var valueReferencedObject in sceneDependencyInfo.referencedObjects)
				{
					var guid = valueReferencedObject.guid;
					if (unityDefaultGuid == guid) continue;
					if (_explicitAssetsGuid2BundleName.ContainsKey(guid)) continue;
					var usageTypes = BuildTaskHelper.GetCachedTypesForObject(in valueReferencedObject);
					if (usageTypes[0] == skipScriptType || usageTypes[0] == skipShaderType) continue;
					outPut.AddAssetRefInReason(AssetDatabase.GUIDToAssetPath(guid), assetPath, bundleName, usageTypes);
				}
			}
			m_implicitDependenciesAssets = outPut;
			return ReturnCode.Success;
		}

		private class WriteImplicitDependenciesAssets : IImplicitDependenciesAssets
		{
			private readonly Dictionary<string, Dictionary<string, Tuple<string, HashSet<Type>>>> _referencedReason =
				new(StringComparer.Ordinal);

			IReadOnlyDictionary<string, Dictionary<string, Tuple<string, HashSet<Type>>>> IImplicitDependenciesAssets.ReferencedReason =>
				_referencedReason;

			public void AddAssetRefInReason(string assetPath, string refSourceAssetPath, string refSourceBundleName, IEnumerable<Type> usageTypes)
			{
				if (!_referencedReason.TryGetValue(assetPath, out var refDic))
				{
					refDic = new Dictionary<string, Tuple<string, HashSet<Type>>>();
					_referencedReason.Add(assetPath, refDic);
				}
				if (!refDic.TryGetValue(refSourceAssetPath, out var bundleUsages))
				{
					bundleUsages = Tuple.Create(refSourceBundleName, new HashSet<Type>(usageTypes));
					refDic.Add(refSourceAssetPath, bundleUsages);
				}
				else
				{
					bundleUsages.Item2.UnionWith(usageTypes);
				}
			}

			private IEnumerable<(string, (string, string, string[])[])> SortedResult()
			{
				var tmp = new (string, (string, string, string[])[])[_referencedReason.Count];
				var tmpIndex = 0;
				foreach (var (itemPath, itemReasonDic) in _referencedReason)
				{
					var reasons = new (string, string, string[])[itemReasonDic.Count];
					var reasonIndex = 0;
					foreach (var reasonAssetAndBundleUsage in itemReasonDic)
					{
						var inBundle = reasonAssetAndBundleUsage.Value.Item1;
						var usageType =
							reasonAssetAndBundleUsage.Value.Item2.Select(t => t.TypeNameToHandWriteFormat()).ToArray();
						Array.Sort(usageType, StringComparer.Ordinal);
						reasons[reasonIndex++] = (reasonAssetAndBundleUsage.Key, inBundle, usageType);
					}
					Array.Sort(reasons, (a,b)=>string.CompareOrdinal(a.Item1, b.Item1));
					tmp[tmpIndex++] = (itemPath, reasons);
				}
				Array.Sort(tmp, (a, b)=>string.CompareOrdinal(a.Item1, b.Item1));
				return tmp;
			}

			void IImplicitDependenciesAssets.WriteToFile(string path)
			{
				var tmp = SortedResult();
				using var sw = new StreamWriter(path, false, Encoding.UTF8);
				using JsonWriter writer = new JsonTextWriter(sw);
				writer.Formatting = Formatting.Indented;
				writer.WriteStartObject();
				foreach (var valueTuple in tmp)
				{
					writer.WritePropertyName(valueTuple.Item1);
					writer.WriteStartObject();
					writer.WritePropertyName("reason");
					writer.WriteStartArray();
					foreach (var tuple in valueTuple.Item2)
					{
						writer.WriteStartObject();
						writer.WritePropertyName("asset");
						writer.WriteValue(tuple.Item1);
						writer.WritePropertyName("bundle");
						writer.WriteValue(tuple.Item2);
						writer.WritePropertyName("usageTypes");
						writer.WriteStartArray();
						foreach (var type in tuple.Item3)
						{
							writer.WriteValue(type);
						}
						writer.WriteEndArray();
						writer.WriteEndObject();
					}
					writer.WriteEndArray();
					writer.WriteEndObject();
				}
				writer.WriteEndObject();
			}
		}
	}
}
