using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{

	[InitializeOnLoad]
	public class AssetDatabaseLoaderHelper
	{
		static AssetDatabaseLoaderHelper()
		{
			EditorApplication.playModeStateChanged += delegate (PlayModeStateChange change)
			{
				if (change == PlayModeStateChange.EnteredPlayMode)
				{
					AssetDatabaseLoader.sFindPathCallback = AssetPathService.GetSavePath;
					RegisterGitPrecommitHooks();
				}
			};
		}

		public static void RegisterGitPrecommitHooks()
		{
			var sourceFile = Path.Combine(Application.dataPath, "../../../tools/git_hooks/pre-commit");
			if (!File.Exists(sourceFile))
			{
				return;
			}


			var targetFile = Path.Combine(Application.dataPath, "../../../.git/hooks/pre-commit");
			var targetDir = Path.GetDirectoryName(targetFile);
			if (!Directory.Exists(targetDir))
			{
				return;
			}

			FileUtil.ReplaceFile(sourceFile, targetFile);
			NLogger.Log("git检查逻辑已更新");
		}
	}

	public static class AssetPathProvider
	{
		public static bool IsDirty = true;
		private static Dictionary<string, string> _allAssetDataPath = new Dictionary<string, string>();

		private const string ArtBundleFindPath = "Assets/__Art/_Resources";
		private const string UiDataBundleFindPath = "Assets/__UI/_Resources";
		private const string ShaderFindPath = "Assets/__Shader";
		private const string LuacFindPath = "Assets/StreamingAssets/GameAssets/Luac";
		private const string ArtStaticResourcesFindPath = "Assets/__Art/StaticResources";
		private const string UIStaticResourcesFindPath = "Assets/__UI/StaticResources";
		private const string SpineResourcesFindPath = "Packages/com.esotericsoftware.spine.spine-unity/Runtime/spine-unity";

		public static readonly string AssetsNameCheckerPath;

		static AssetPathProvider()
		{
			AssetsNameCheckerPath = Path.Combine(Application.dataPath, "../Logs/AssetChecker_DuplicateNames.csv");
			AssetsNameCheckerPath = Path.GetFullPath(AssetsNameCheckerPath);
		}

		public static List<string> GetCheckFolders(bool includeLuacFindPath = true)
		{
			List<string> assetFolders = new List<string>();
			assetFolders.AddRange(new[]
			{
				ArtBundleFindPath,
				UiDataBundleFindPath,
				ShaderFindPath
			});
			if (includeLuacFindPath)
			{
				assetFolders.Add(LuacFindPath);
			}
			return assetFolders;
		}

		public static List<string> GetStaticResourcesFolders()
		{
			List<string> assetFolders = new List<string>();
			assetFolders.AddRange(new[]
			{
				ArtStaticResourcesFindPath,
				UIStaticResourcesFindPath,
				SpineResourcesFindPath
			});
			return assetFolders;
		}

		public static string GetFileNameWithoutExtension(string localPath)
		{
			if (string.IsNullOrEmpty(localPath))
			{
				return string.Empty;
			}

			return Path.GetFileNameWithoutExtension(localPath);
		}

		public static Dictionary<string, string> GetAllAssetDatabasePath()
		{
			var databaseMap = new Dictionary<string, string>();
			var assetFolders = GetCheckFolders();
			var allAssets = AssetDatabase.FindAssets(null, assetFolders.ToArray());
			//var check = 8;
			foreach (var find in allAssets)
			{
				var localPath = AssetDatabase.GUIDToAssetPath(find);
				var extension = Path.GetExtension(localPath);
				if (string.IsNullOrEmpty(extension))
				{
					continue;
				}

				var fileName = GetFileNameWithoutExtension(localPath);
				if (string.IsNullOrEmpty(fileName))
				{
					continue;
				}

				databaseMap[fileName] = localPath;
			}
			return databaseMap;
		}

		public static void PrepareAssetPath()
		{
			EditorUtility.DisplayProgressBar("prepare path", "now loading", 0.31415926535f);
			_allAssetDataPath = GetAllAssetDatabasePath();
			IsDirty = false;
			EditorUtility.ClearProgressBar();
		}

		public static string InternalGetSavedPath(string fileName)
		{
			_allAssetDataPath.TryGetValue(fileName, out var ret);
			return ret;
		}

		private static List<string> _sceneBakeFolders;
		private static bool IsSceneBakedAsset(string localPath)
		{
			CollectSceneInfoIfNeed();

			foreach (var folderPath in _sceneBakeFolders)
			{
				if (localPath.StartsWith(folderPath))
				{
					return true;
				}
			}

			return false;
		}

		private static void CollectSceneInfoIfNeed()
		{
			if (_sceneBakeFolders != null)
			{
				return;
			}

			_sceneBakeFolders = new();
			var assetFolders = GetCheckFolders();
			var allSceneAssets = AssetDatabase.FindAssets("t:scene", assetFolders.ToArray());
			foreach (var sceneAssetGUID in allSceneAssets)
			{
				var localPath = AssetDatabase.GUIDToAssetPath(sceneAssetGUID);
				var extension = Path.GetExtension(localPath);
				var folderPath = localPath.Substring(0, localPath.Length - extension.Length);
				_sceneBakeFolders.Add(folderPath);
			}
		}

		//[MenuItem("DragonReborn/资源工具箱/资源规范/日常检查/2, 资源重名检查", false, 2)]
		//public static void RunAssetNameChecker()
		//{
		//	EditorUtility.DisplayProgressBar("prepare path", "now loading", 0.31415926535f);

		//	CheckAssetNames();

		//	EditorUtility.ClearProgressBar();
		//}

		//public const string MENI_DIDABLE_ASSET_CHECK_KEY = "DragonReborn/资源检查/关闭资源重名检查";
		//[MenuItem(MENI_DIDABLE_ASSET_CHECK_KEY, true)]
		//private static bool Check_disable_assets_name_check()
		//{
		//	var disable = EditorPrefs.GetBool(MENI_DIDABLE_ASSET_CHECK_KEY, false);
		//	Menu.SetChecked(MENI_DIDABLE_ASSET_CHECK_KEY, disable);
		//	return !EditorApplication.isPlaying && !EditorApplication.isCompiling && !EditorApplication.isPaused && !EditorApplication.isPlayingOrWillChangePlaymode;
		//}

		//[MenuItem(MENI_DIDABLE_ASSET_CHECK_KEY, false)]
		//private static void Flip_disable_assets_name_check()
		//{
		//	var b = EditorPrefs.GetBool(MENI_DIDABLE_ASSET_CHECK_KEY, false);
		//	EditorPrefs.SetBool(MENI_DIDABLE_ASSET_CHECK_KEY, !b);
		//}

		//public static int CheckAssetNames()
		//{
		//	var databaseMap = new Dictionary<string, List<string>>();
		//	var allAssets = AssetDatabase.FindAssets(null, new[] { ArtBundleFindPath, UiDataBundleFindPath});
		//	_sceneBakeFolders = null;
		//	foreach (var find in allAssets)
		//	{
		//		var localPath = AssetDatabase.GUIDToAssetPath(find);
		//		var extension = Path.GetExtension(localPath);
		//		if (string.IsNullOrEmpty(extension))
		//		{
		//			continue;
		//		}

		//		var fileName = GetFileNameWithoutExtension(localPath);
		//		if (string.IsNullOrEmpty(fileName))
		//		{
		//			continue;
		//		}

		//		// 例外：场景烘焙资源，不检查重名
		//		if (IsSceneBakedAsset(localPath))
		//		{
		//			continue;
		//		}

		//		var lowercaseFilename = fileName.ToLower();

		//		if (!databaseMap.ContainsKey(lowercaseFilename))
		//		{
		//			databaseMap.Add(lowercaseFilename, new List<string>());
		//		}

		//		databaseMap[lowercaseFilename].Add(localPath);
		//	}

		//	var errCount = 0;
		//	var results = new StringBuilder();
		//	foreach (var (lowerName, fullPathList) in databaseMap)
		//	{
		//		if (fullPathList.Count > 1)
		//		{
		//			errCount++;
		//			var sb = new StringBuilder();
		//			fullPathList.ForEach(x => sb.Append(x).Append(','));
		//			results.AppendLine(sb.ToString());
		//		}
		//	}

		//	if (errCount > 0)
		//	{
		//		try
		//		{
		//			var path = AssetsNameCheckerPath;
		//			File.WriteAllText(path, results.ToString());
		//			NLogger.Error($"发现存在{errCount}组重名的资源，请前往<a href=\"file:///{path}\">{path}</a>查看");
		//		}
		//		catch (Exception e)
		//		{
		//			NLogger.Error(e.ToString());
		//		}
		//	}
		//	else
		//	{
		//		NLogger.Log("资源重名检查完毕");
		//	}

		//	return errCount;
		//}

        public static IAssetChecker GetAssetChecker()
        {
	        return new AssetChecker();
        }

        private class AssetChecker : IAssetChecker
        {
	        private static int _usingRef;
	        private bool _disposed;

	        public AssetChecker()
	        {
		        if (_usingRef++ > 0) return;
		        _sceneBakeFolders = null;
		        CollectSceneInfoIfNeed();
	        }

	        bool IAssetChecker.IsSceneBakedAsset(string localPath)
	        {
		        return IsSceneBakedAsset(localPath);
	        }

	        void IDisposable.Dispose()
	        {
		        if (_disposed) return;
		        _disposed = true;
		        if (--_usingRef <= 0)
		        {
			        _usingRef = 0;
			        _sceneBakeFolders = null;
		        }
	        }
        }

        public interface IAssetChecker : IDisposable
        {
	        bool IsSceneBakedAsset(string localPath);
        }
    }
}
