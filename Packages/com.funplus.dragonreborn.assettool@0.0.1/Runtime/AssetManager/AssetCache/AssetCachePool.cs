using System.Collections.Generic;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public class AssetCachePool
    {
        private Dictionary<string, AssetCache> _allAssetCache;
        private AssetLoaderProxy _assetLoaderProxy;

        public AssetLoaderProxy AssetLoaderProxy => _assetLoaderProxy;
        public Dictionary<string, AssetCache> AllAssetCache => _allAssetCache;

        public void Initialize()
        {
            _allAssetCache = new Dictionary<string, AssetCache>();

            _assetLoaderProxy = new AssetLoaderProxy();
            _assetLoaderProxy.Initialize();
        }

		public void Reset()
        {
			// 清理缓存
			foreach (var pair in _allAssetCache)
			{
				pair.Value.Release();
			}
			_allAssetCache.Clear();

			_assetLoaderProxy.Reset();
		}

		/// <summary>
		/// 当前版本资源是否存在（包含不在本地的网络资源）
		/// </summary>
		/// <param name="assetIndex"></param>
		/// <returns></returns>
		public bool IsAssetExist(string assetIndex)
		{
			if (_assetLoaderProxy == null)
			{
				return false;
			}
			
			return _assetLoaderProxy.IsAssetExist(assetIndex);
		}

        public bool CheckCanSyncLoad(string assetIndex)
        {
            if (_allAssetCache.TryGetValue(assetIndex, out var assetCache))
            {
                return assetCache.CanSyncLoad();
            }
            var (loaderType, assetData) = AssetCache.GetLoaderTypeAndBundleAssetData(assetIndex, _assetLoaderProxy);
            return null != assetData && AssetCache.CanSyncLoadCheck(loaderType, _assetLoaderProxy, assetData.AssetName);
        }

        // 获得一个资源，不存在不会创建
        // 引用计数是否+1，看调用的地方是否用了这个AssetCache
        public AssetCache GetAssetCache(string assetIndex)
        {
            return _allAssetCache.GetValueOrDefault(assetIndex);
        }

        public AssetCache AllocateAssetCache(string assetIndex)
        {
            var newCache = new AssetCache(assetIndex, _assetLoaderProxy);
            _allAssetCache.Add(assetIndex, newCache);
            return newCache;
        }

        public void UnloadAsset(string assetIndex)
        {
            if (string.IsNullOrEmpty(assetIndex))
            {
                return;
            }
            
            if (_allAssetCache.TryGetValue(assetIndex, out var asset))
            {
                // 还在加载中的资源先不处理
                if (asset.AssetCacheState != AssetCacheState.complete)
                {
                    return;
                }

                // 引用计数-1
                var isZero = asset.Decrease();
                if (isZero)
                {
                    asset.Release();
                    _allAssetCache.Remove(assetIndex);
                }
            }
        }

        public void ClearAll()
        {
            var resIt = _allAssetCache.GetEnumerator();
            while (resIt.MoveNext())
            {
                resIt.Current.Value.Release();
            }
            resIt.Dispose();
            _allAssetCache.Clear();
        }

        /// <summary>
        /// 使用情形：
        /// 需要卸载所有AssetBundle资源的时候（AssetBundle.Unload(true)）
        /// 避免重复卸载
        /// </summary>
        public void ClearAllNotRelease()
        {
            _allAssetCache.Clear();
        }

        public void ClearUnused()
        {
            var deleteList = new List<string>(16);
            foreach (var pair in _allAssetCache)
            {
                if (pair.Value.CanRemove())
                {
                    deleteList.Add(pair.Key);
                    pair.Value.Release();
                }
            }

            foreach (var assetIndex in deleteList)
            {
                _allAssetCache.Remove(assetIndex);
            }
        }
        
        internal void DumpCurrentAssetCacheInfo(List<AssetCacheInfo> writeTo, List<BundleCacheInfo> bundleWriteTo)
        {
            foreach (var pair in _allAssetCache)
            {
                writeTo.Add(pair);
            }
            _assetLoaderProxy.AssetBundleLoader.AssetBundleCachePool.DumpBundleCacheInfo(bundleWriteTo);
        }
	}
}
