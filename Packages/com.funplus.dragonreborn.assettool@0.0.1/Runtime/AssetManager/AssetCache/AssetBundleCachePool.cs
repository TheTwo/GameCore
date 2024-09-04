// #define USING_ORIGIN_BUNDLE_REF_COUNTER
using System;
using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public class AssetBundleCachePool
    {
        private Dictionary<string, AssetBundleCache> _allAssetBundleCache;
        public Dictionary<string, AssetBundleCache> AllAssetBundleCache => _allAssetBundleCache;
#if USING_ORIGIN_BUNDLE_REF_COUNTER
		private HashSet<string> _allRemainedBundles = new HashSet<string>();
#endif

		public void Initialize()
        {
            _allAssetBundleCache = new Dictionary<string, AssetBundleCache>();
#if USING_ORIGIN_BUNDLE_REF_COUNTER
			InitRemainedBundles();
#endif
        }
        
        public void Reset()
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
			foreach (var (_, assetBundleCache) in _allAssetBundleCache)
			{
				assetBundleCache.Reset();
			}
			_allAssetBundleCache.Clear();
			_allRemainedBundles.Clear();
#else
            using (UnityEngine.Pool.ListPool<AssetBundleCache>.Get(out var tempList))
            {
                tempList.AddRange(_allAssetBundleCache.Values);
                foreach (var  assetBundleCache in tempList)
                {
                    assetBundleCache.Reset();
                }
                _allAssetBundleCache.Clear();
            }
#endif
		}
        
#if USING_ORIGIN_BUNDLE_REF_COUNTER
		// 记录重启后残留的asset bundle
		public void InitRemainedBundles()
		{
			_allRemainedBundles.Clear();
			var bundles = AssetBundle.GetAllLoadedAssetBundles();
			foreach (var bundle in bundles)
			{
				_allRemainedBundles.Add(bundle.name);
			}
		}

		// 记录卸载掉的asset bundle
		public void UnloadRemainedBundles(string bundleName)
		{
			if (_allRemainedBundles.Contains(bundleName))
			{
				_allRemainedBundles.Remove(bundleName);
			}
		}

		// 残留的asset bundle，如果要重新加载，做检查
		public void CheckReloadRemainedBundle(string bundleName)
		{
			if (_allRemainedBundles.Contains(bundleName))
			{
				_allRemainedBundles.Remove(bundleName);

				var bundles = AssetBundle.GetAllLoadedAssetBundles();
				foreach (var bundle in bundles)
				{
					if (bundleName == bundle.name)
					{
						bundle.Unload(false);
						UnityEngine.Object.Destroy(bundle);
					}
				}
			}
		}
#endif
        public AssetBundleCache GetOrCreateAssetBundleCache(string bundleName)
        {
            if (!_allAssetBundleCache.TryGetValue(bundleName, out var bundle))
            {
                bundle = AllocateAssetBundleCache(bundleName);
            }
            return bundle;
        }

		public AssetBundleCache GetAssetBundleCache(string bundleName)
        {
            _allAssetBundleCache.TryGetValue(bundleName, out var bundle);
            return bundle;
        }

        public AssetBundleCache AllocateAssetBundleCache(string bundleName)
        {
            if (_allAssetBundleCache.ContainsKey(bundleName))
            {
                throw new Exception($"{bundleName} already cached");
            }
            
            var bundle = new AssetBundleCache(bundleName, this);
            _allAssetBundleCache.Add(bundleName, bundle);
            bundle.Initialize();
            return bundle;
        }

#if USING_ORIGIN_BUNDLE_REF_COUNTER
        public void CleanZeroBundle()
        {
            var removeKeys = new List<string>(16);

            foreach (var pair in _allAssetBundleCache)
            {
                if (pair.Value.GetRefCount() <= 0)
                {
                    removeKeys.Add(pair.Key);
                }
            }

            foreach (var key in removeKeys)
            {
                _allAssetBundleCache.Remove(key);
            }

        }
#else
        public bool RemoveFromCache(string bundleName)
        {
            if (!_allAssetBundleCache.Remove(bundleName, out var cache)) return false;
            if (cache.GetRefCount() > 0 || cache.ByRefCount > 0)
            {
                Debug.LogErrorFormat("RemoveFromCache:{0}, but still has ref:{1},{2}", bundleName, cache.GetRefCount(), cache.ByRefCount);
            }
            return false;
        }
#endif

	    internal void DumpBundleCacheInfo(List<BundleCacheInfo> toWrite)
	    {
		    foreach (var assetBundleCache in _allAssetBundleCache)
		    {
			    toWrite.Add(assetBundleCache);
		    }
	    }
    }
}
