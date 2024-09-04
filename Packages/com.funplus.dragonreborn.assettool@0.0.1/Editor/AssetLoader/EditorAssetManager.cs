using System.Collections.Generic;
using System.Linq;
using UnityEditor;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public class EditorAssetManager
	{
		private static readonly Dictionary<string, string> SceneName2Path = new Dictionary<string, string>();

		public static AssetHandle LoadAsset(string assetPath)
		{
			AssetDatabaseLoader.sFindPathCallback = AssetPathService.GetSavePath;
			// TODO 同步加载
			return AssetManager.Instance.LoadAsset(GetAssetName(assetPath));
		}

		public static bool GetSceneFullPath(string sceneName, out string fullPath)
		{
			if (AssetPathProvider.IsDirty || SceneName2Path.Count <= 0)
			{
				InitSceneName2Path();
			}
			return SceneName2Path.TryGetValue(sceneName, out fullPath);
		}

		public static UnityEngine.Object LoadSceneAsAsset(string sceneName)
		{
			if (AssetPathProvider.IsDirty || SceneName2Path.Count <= 0)
			{
				InitSceneName2Path();
			}

			if (GetSceneFullPath(sceneName, out var fullPath))
			{
				return AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(fullPath);
			}
			return null;
		}

		public static string GetAssetPath(UnityEngine.Object obj)
		{
			var path = AssetDatabase.GetAssetPath(obj);
			return GetAssetName(path);
		}

		public static string GetAssetName(string path)
		{
			if (string.IsNullOrEmpty(path)) return string.Empty;

			if (path.Contains("/") && path.Contains("."))
			{
				var idx1 = path.LastIndexOf("/");
				var idx2 = path.LastIndexOf(".");
				var name = path.Substring(idx1 + 1, idx2 - idx1 - 1);
				return name;
			}

			return path;
		}

		private static void InitSceneName2Path()
		{
			SceneName2Path.Clear();
			var sceneArray = AssetDatabase.FindAssets("t:scene", AssetBundleBuildGenerator.ScenePath.ToArray());
			foreach (var scene in sceneArray)
			{
				var path = AssetDatabase.GUIDToAssetPath(scene);
				SceneName2Path[GetAssetName(path)] = path;
			}

			SceneName2Path[
					GetAssetName("Assets/__Scene/StaticResources/TimelineDummyScene/CityTimelineSceneDummy.unity")] =
				"Assets/__Scene/StaticResources/TimelineDummyScene/CityTimelineSceneDummy.unity";
		}
	}
}
