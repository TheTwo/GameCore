using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Player;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	// ReSharper disable once UnusedType.Global
	public static class AssetsDependenciesGetter
	{
		public static IReadOnlyDictionary<string, IEnumerable<string>> GenerateForAssets(IEnumerable<string> guids, BuildTarget? buildTarget = null)
		{
			var target = buildTarget ?? EditorUserBuildSettings.activeBuildTarget;
			var workDic = new Dictionary<string, HashSet<string>>();
			var result = PlayerBuildInterface.CompilePlayerScripts(new ScriptCompilationSettings()
			{
				target = target,
				group = BuildPipeline.GetBuildTargetGroup(target),
				options = ScriptCompilationOptions.None,
			}, "Library/tempBuild");
			foreach (var guidStr in guids)
			{
				var guid = new GUID(guidStr);
				var assetFullPath = AssetDatabase.GUIDToAssetPath(guid);
				if (!workDic.TryGetValue(assetFullPath, out var set))
				{
					set = new HashSet<string>();
					workDic.Add(assetFullPath, set);
				}
				var includedObjects = ContentBuildInterface.GetPlayerObjectIdentifiersInAsset(guid, target);
				var dependenciesForObjects = ContentBuildInterface.GetPlayerDependenciesForObjects(includedObjects, target, result.typeDB,
					DependencyType.DefaultDependencies);
				foreach (var dependenciesForObject in dependenciesForObjects)
				{
					var dependenceAssetFullPath = AssetDatabase.GUIDToAssetPath(dependenciesForObject.guid);
					if (string.CompareOrdinal(assetFullPath, dependenceAssetFullPath) == 0) continue;
					set.Add(dependenceAssetFullPath);
				}
			}
			return workDic.ToDictionary<KeyValuePair<string, HashSet<string>>, string, IEnumerable<string>>(d => d.Key,
				d =>
				{
					var l = d.Value.ToArray();
					Array.Sort(l, StringComparer.Ordinal);
					return l;
				});
		}
	}
}
