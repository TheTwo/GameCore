using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public static class PathHelper
    {
        public const string BUNDLE_END_FIX = ".ab";
        public static readonly string DataPath;
        public static readonly string StreamingAssetsPath;
        public static readonly string PersistentDataPath;
        public static readonly string TemporaryCachePath;
        public static bool Init { get; private set; }
		private static Dictionary<string, string> _bundlePathMap = new();

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSplashScreen)]
        private static void RuntimeInit()
        {
	        Init = true;
        }

        static PathHelper()
        {
            DataPath = Application.dataPath;
            StreamingAssetsPath = Application.streamingAssetsPath;
            PersistentDataPath = Application.persistentDataPath;
            TemporaryCachePath = Application.temporaryCachePath;
            VersionControl.GetBundleRelativePath = GetBundleRelativePath;
        }

        public static string FormatStreamingAssetsBundleFolder(string bundleFolderRevPath)
        {
            return string.Format("GameAssets/AssetBundle/{0}/{1}", GetBundlePlatformFolderName(), bundleFolderRevPath);
        }

        public static string GetBundleRelativePath(string bundleName)
        {
			if (_bundlePathMap.ContainsKey(bundleName))
			{
				return _bundlePathMap[bundleName];
			}

			var fullpath = $"GameAssets/AssetBundle/{GetBundlePlatformFolderName()}/{bundleName}.ab";
			_bundlePathMap.Add(bundleName, fullpath);
			return fullpath;
        }

        public static string GetBundlePlatformFolderName()
        {
#if UNITY_EDITOR
#if USE_BUNDLE_ANDROID
            return "Android";
#elif USE_BUNDLE_IOS
            return "IOS";
#elif USE_BUNDLE_WIN
	        return "Windows";
#endif
	        
#endif
            switch (Application.platform)
            {
                case RuntimePlatform.Android:
                    return "Android";
                case RuntimePlatform.IPhonePlayer:
                    return "IOS";
                case RuntimePlatform.OSXEditor:
                case RuntimePlatform.OSXPlayer:
                    return "OSX";
                case RuntimePlatform.WindowsEditor:
                case RuntimePlatform.WindowsPlayer:
                    return "Windows";
                default:
                    throw new System.NotImplementedException();
            }
        }
    }
}
