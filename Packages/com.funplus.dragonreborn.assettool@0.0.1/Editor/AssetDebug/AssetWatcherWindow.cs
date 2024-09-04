using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
    public class AssetWatcherWindow : OdinEditorWindow
    {
        private StringBuilder _sb = new();

        [MenuItem("DragonReborn/资源工具箱/资源规范/资源监视工具")]
        private static void OpenWindow()
        {
            var window = GetWindow<AssetWatcherWindow>();
            window.titleContent = new GUIContent("资源监视工具");
            window.Show();
        }

        [Button("刷新")]
        [HorizontalGroup("Asset", 0.5f)]
        public void ClickRefreshAsset()
        {
            AssetDebugInfo = GenerateAssetDebugInfo();
            AssetBundleDebugInfo = GenerateAssetBundleDebugInfo();

            var dstPath = Path.Combine(Application.dataPath, "../Logs/AssetDebugDump.txt");
            File.WriteAllText(dstPath, AssetDebugInfo, Encoding.UTF8);
            File.AppendAllText(dstPath, AssetBundleDebugInfo, Encoding.UTF8);
        }

        [Button("清除")]
        [HorizontalGroup("Asset", 0.5f)]
        public void ClickClearAsset()
        {
            AssetDebugInfo = string.Empty;
            AssetBundleDebugInfo = string.Empty;
        }

        [Title("Asset")]
        [HideLabel]
        [DisplayAsString(false)]
        public string AssetDebugInfo = string.Empty;

        [Title("AssetBundle")]
        [HideLabel]
        [DisplayAsString(false)]
        public string AssetBundleDebugInfo = string.Empty;

        private const string EMPTY_BUNDLE = "@Resources";

        private string GenerateAssetDebugInfo()
        {
            var allAssetCache = AssetManager.Instance.AssetCachePool.AllAssetCache;
            if (allAssetCache == null)
            {
                return string.Empty;
            }

            if (AssetManager.Instance.IsBundleMode())
            {
                _sb.Clear();
                _sb.AppendLine($"加载的Asset总数: {allAssetCache.Count}");

                // build bundle and assets map
                var bundleAssetsDict = new Dictionary<string, List<AssetCache>>();
                foreach (var (_, assetCache) in allAssetCache)
                {
                    var bundleName = assetCache.BundleAssetData.BundleName;
                    if (bundleName == string.Empty)
                    {
                        bundleName = EMPTY_BUNDLE;
                    }
                    bundleAssetsDict.TryGetValue(bundleName, out var assetCacheList);
                    if (assetCacheList == null)
                    {
                        assetCacheList = new List<AssetCache>();
                        bundleAssetsDict.Add(bundleName, assetCacheList);
                    }

                    assetCacheList.Add(assetCache);
                }

                var allAssetBundleCache = AssetManager.Instance.AssetCachePool.AssetLoaderProxy.AssetBundleLoader.AssetBundleCachePool.AllAssetBundleCache;
                foreach (var (bundleName, assetCacheList) in bundleAssetsDict)
                {
					if (bundleName.Equals(EMPTY_BUNDLE))
					{
						_sb.AppendLine($"{EMPTY_BUNDLE}:");
					}
					else
					{
						allAssetBundleCache.TryGetValue(bundleName, out var assetBundleCache);
						_sb.AppendLine($"{assetBundleCache.ToDebugString()}:");
					}

                    assetCacheList.Sort((x, y) => -x.GetRefCount().CompareTo(y.GetRefCount()));
                    foreach (var assetCache in assetCacheList)
                    {
                        _sb.AppendLine($"\t{assetCache.ToDebugString(false)}");
                    }
                }

                return _sb.ToString();
            }
            else
            {
                _sb.Clear();
                _sb.AppendLine($"加载的Asset总数: {allAssetCache.Count}");
                var assetCacheList = allAssetCache.Values.ToList();
                assetCacheList.Sort((x, y) => -x.GetRefCount().CompareTo(y.GetRefCount()));
                foreach (var assetCache in assetCacheList)
                {
                    _sb.AppendLine(assetCache.ToDebugString());
                }

                return _sb.ToString();
            }
        }

        private string GenerateAssetBundleDebugInfo()
        {
            if (!AssetManager.Instance.IsBundleMode())
            {
                return "仅在AssetBundle模式下使用";
            }

            var allAssetBundleCache = AssetManager.Instance.AssetCachePool.AssetLoaderProxy.AssetBundleLoader.AssetBundleCachePool.AllAssetBundleCache;
            if (allAssetBundleCache == null)
            {
                return string.Empty;
            }

            _sb.Clear();
            _sb.AppendLine($"加载的AssetBundle总数: {allAssetBundleCache.Count}");
            var assetCacheBundleList = allAssetBundleCache.Values.ToList();
            assetCacheBundleList.Sort((x, y) => -x.GetRefCount().CompareTo(y.GetRefCount()));
            foreach (var assetBundleCache in assetCacheBundleList)
            {
                _sb.AppendLine(assetBundleCache.ToDebugString(true));
            }

            return _sb.ToString();
        }
    }
}
