using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.CSharpReflectionTool
{
	public static class CsTypeInUnityIdentifierGetter
	{
		private static readonly Type BaseClassType = typeof(UnityEngine.Object);
		
		public static IReadOnlyList<CsTypeInUnityIdentifierQueryResult> QueryInCurrentBuildRuntime(IEnumerable<Type> typesToQuery)
		{
			var allRuntimeMono = MonoImporter.GetAllRuntimeMonoScripts();
			var classToMonoScriptDic = new Dictionary<Type, CsTypeInUnityIdentifierQueryResult>();
			var currentTarget = EditorUserBuildSettings.activeBuildTarget;
			foreach (var monoScript in allRuntimeMono)
			{
				var classType = monoScript.GetClass();
				if (null == classType || !BaseClassType.IsAssignableFrom(classType)) continue;
				var assetPath = AssetDatabase.GetAssetPath(monoScript);
				if (string.IsNullOrWhiteSpace(assetPath)) continue;
				if (AssetImporter.GetAtPath(assetPath) is PluginImporter pluginImporter && (!pluginImporter.ShouldIncludeInBuild() || !pluginImporter.GetCompatibleWithPlatform(currentTarget))) continue;
				if (!AssetDatabase.TryGetGUIDAndLocalFileIdentifier(monoScript, out var guid, out long fileId) || !GUID.TryParse(guid, out var guidStruct))
				{
					Debug.LogWarning($"UnSupported class type not found guid and fileId:{classType.TypeNameToHandWriteFormat()} at:{assetPath}");
					continue;
				}
				if (classToMonoScriptDic.TryAdd(classType,
					    new CsTypeInUnityIdentifierQueryResult(classType, true, guidStruct, fileId, assetPath)))
					continue;
				var existed = classToMonoScriptDic[classType];
				Debug.LogWarning(string.CompareOrdinal(existed.AssetPath, assetPath) == 0
					? $"Duplicate class type found in runtime mono scripts: {classType.TypeNameToHandWriteFormat()} [{fileId}] with [{existed.FileId}] {assetPath}"
					: $"Duplicate class type found in runtime mono scripts: {classType.TypeNameToHandWriteFormat()} {assetPath} with {existed.AssetPath}");
			}
			return typesToQuery.Select(type => !classToMonoScriptDic.TryGetValue(type, out var queryResult)
					? new CsTypeInUnityIdentifierQueryResult(type, false, default, default, default)
					: queryResult)
				.ToList();
		}
	}

	public readonly struct CsTypeInUnityIdentifierQueryResult
	{
		public readonly Type Type;
		public readonly bool IsFound;
		public readonly GUID Guid;
		public readonly long FileId;
		public readonly string AssetPath;

		internal CsTypeInUnityIdentifierQueryResult(Type type, bool isFound, GUID guid, long fileId, string assetPath)
		{
			Type = type;
			IsFound = isFound;
			Guid = guid;
			FileId = fileId;
			AssetPath = assetPath;
		}
		
		public override string ToString()
		{
			return $"Type:{Type} IsFound:{IsFound} Guid:{Guid} FileId:{FileId} at:{AssetPath}";
		}
	}
}
