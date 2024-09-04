using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Pipeline.Tasks;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 记录SpriteAtlas 里sprite 被外部以非Sprite形式引用的情况
	/// 依照资源管理规划 作为图集成员的资源不能以其他形式被使用
	/// </summary>
	public class RecordSpriteTextureReferenceTask : IBuildTask
	{
		int IBuildTask.Version => 1;
		
		private readonly IReadOnlyDictionary<GUID, string> _spriteAssignedWithBundle;
	    
		// ReSharper disable ArrangeTypeMemberModifiers
		// ReSharper disable InconsistentNaming
		[InjectContext(ContextUsage.In)] IDependencyData m_DependencyData;
		[InjectContext(ContextUsage.In)] IBuildParameters m_Parameters;
		// ReSharper disable NotAccessedField.Local
		[InjectContext(ContextUsage.Out)] ISpriteTextureReferenceRecord m_outPut;
		// ReSharper restore NotAccessedField.Local
		// ReSharper restore InconsistentNaming
		// ReSharper restore ArrangeTypeMemberModifiers

		private readonly Dictionary<AssetLoadInfo, ObjectIdentifier[]> _cachedDepMap = new();

		private RecordSpriteTextureReferenceTask(IReadOnlyDictionary<GUID, string> spriteAssignedWithBundle)
		{
			_spriteAssignedWithBundle = spriteAssignedWithBundle;
		}

		ReturnCode IBuildTask.Run()
		{
			var record = new SpriteTextureReferenceRecord();
			m_outPut = record;
			if (_spriteAssignedWithBundle.Count <= 0) return ReturnCode.MissingRequiredObjects;
			var needRemoveTextureInBundle = new HashSet<GUID>(_spriteAssignedWithBundle.Keys);
			var checkTextureTypeUsage = typeof(UnityEngine.Sprite);
			foreach (var (guid, assetLoadInfo) in m_DependencyData.AssetInfo)
			{
				if (needRemoveTextureInBundle.Contains(guid)) continue;
				foreach (var referencedObject in assetLoadInfo.referencedObjects)
				{
					if (!needRemoveTextureInBundle.Contains(referencedObject.guid)) continue;
					var usageTypes = BuildTaskHelper.GetCachedTypesForObject(in referencedObject);
					if (usageTypes[0] == checkTextureTypeUsage) continue;
					if (!IsMatchTarget(assetLoadInfo, referencedObject.guid, checkTextureTypeUsage)) continue;
					if (!record.Data.TryGetValue(referencedObject.guid, out var set))
					{
						set = new Dictionary<GUID, ObjectIdentifierInfo>();
						record.Data.Add(referencedObject.guid, set);
					}
					var usageInfo = new ObjectIdentifierInfo(guid);
					set.Add(guid, usageInfo);
					usageInfo.UsageType.Add(usageTypes[0]);
				}
			}
			foreach (var (guid, sceneDependencyInfo) in m_DependencyData.SceneInfo)
			{
				if (needRemoveTextureInBundle.Contains(guid)) continue;
				foreach (var referencedObject in sceneDependencyInfo.referencedObjects)
				{
					if (!needRemoveTextureInBundle.Contains(referencedObject.guid)) continue;
					var usageTypes = BuildTaskHelper.GetCachedTypesForObject(in referencedObject);
					if (usageTypes[0] == checkTextureTypeUsage) continue;
					if (!record.Data.TryGetValue(referencedObject.guid, out var set))
					{
						set = new Dictionary<GUID, ObjectIdentifierInfo>();
						record.Data.Add(referencedObject.guid, set);
					}
					var usageInfo = new ObjectIdentifierInfo(guid);
					set.Add(guid, usageInfo);
					usageInfo.UsageType.Add(usageTypes[0]);
				}
			}
			return ReturnCode.Success;
		}

		private bool IsMatchTarget(AssetLoadInfo assetLoadInfo, GUID matchGuid, Type matchType)
		{
			if (!_cachedDepMap.TryGetValue(assetLoadInfo, out var objectIdentifiers))
			{
				objectIdentifiers = ContentBuildInterface.GetPlayerDependenciesForObjects(
					assetLoadInfo.includedObjects.ToArray(), m_Parameters.Target, m_Parameters.ScriptInfo, DependencyType.ValidReferences);
				_cachedDepMap.Add(assetLoadInfo, objectIdentifiers);
			}
			foreach (var objectIdentifier in objectIdentifiers)
			{
				if (objectIdentifier.guid != matchGuid) continue;
				var usageType = BuildTaskHelper.GetCachedTypesForObject(objectIdentifier);
				if (usageType[0] != matchType)
				{
					return true;
				}
			}
			return false;
		}

		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks,
			IReadOnlyDictionary<GUID, string> spriteToBundleName)
		{
			return BuildTaskHelper.AttachBuildTask<RecordSpriteTextureReferenceTask, PostDependencyCallback>(buildTasks,
				() => new RecordSpriteTextureReferenceTask(new Dictionary<GUID, string>(spriteToBundleName)), false);
		}
		
		private class SpriteTextureReferenceRecord : ISpriteTextureReferenceRecord
		{
			public IReadOnlyDictionary<GUID, Dictionary<GUID, ObjectIdentifierInfo>> Detail { get; }

			public readonly Dictionary<GUID, Dictionary<GUID, ObjectIdentifierInfo>> Data = new();

			public SpriteTextureReferenceRecord()
			{
				Detail = Data;
			}

			void ISpriteTextureReferenceRecord.WriteToFile(string path)
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
					writer.WritePropertyName("ref by");
					writer.WriteStartArray();
					foreach (var tuple in valueTuple.Item2)
					{
						writer.WriteStartObject();
						writer.WritePropertyName("asset");
						writer.WriteValue(tuple.Item1);
						writer.WritePropertyName("usageTypes");
						writer.WriteStartArray();
						foreach (var type in tuple.Item2)
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

			private IEnumerable<(string, (string, string[])[])> SortedResult()
			{
				var ret = new List<(string, (string, string[])[])>(Data.Count);
				foreach (var (guid, v) in Data)
				{
					var spriteAssetPath = AssetDatabase.GUIDToAssetPath(guid);
					var refList = v.Select(t =>
					{
						var refSourcePath = t.Value.TargetPath;
						var types = t.Value.UsageType.Select(type => type.FullName).ToArray();
						Array.Sort(types, string.CompareOrdinal);
						return (refSourcePath, types);
					}).ToArray();
					Array.Sort(refList, (a,b)=>string.CompareOrdinal(a.Item1, b.Item1));
					ret.Add((spriteAssetPath, refList));
				}
				return ret;
			}
		}
	}
	
	public class ObjectIdentifierInfo
	{
		public readonly GUID Guid;
		public readonly HashSet<Type> UsageType = new();
		public readonly string TargetPath;

		public ObjectIdentifierInfo(GUID guid)
		{
			Guid = guid;
			TargetPath = AssetDatabase.GUIDToAssetPath(guid);
		}
	}
}
