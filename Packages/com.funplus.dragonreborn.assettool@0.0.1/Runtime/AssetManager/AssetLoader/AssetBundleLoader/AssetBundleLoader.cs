// #define USING_ORIGIN_BUNDLE_REF_COUNTER
// #define DETAIL_LOG_ON
using System;
using System.Collections.Generic;
using Object = UnityEngine.Object;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public class AssetBundleLoader : IAssetLoader
    {
        private AssetBundleCachePool _assetBundleCachePool;
        public AssetBundleCachePool AssetBundleCachePool => _assetBundleCachePool;

        public void Initialize()
        {
            _assetBundleCachePool = new AssetBundleCachePool();
            _assetBundleCachePool.Initialize();
        }

        public void Reset()
        {
			_assetBundleCachePool.Reset();
		}

        public void OnAssetCacheCreate(BundleAssetData assetData)
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
            if(!string.IsNullOrEmpty(assetData.BundleName))
            {
                var assetBundleCache = _assetBundleCachePool.GetAssetBundleCache(assetData.BundleName);
                if (assetBundleCache == null)
                {
                    assetBundleCache = _assetBundleCachePool.AllocateAssetBundleCache(assetData.BundleName);
                }
                assetBundleCache.Increase(
	                // $"increase by direct: {assetData.AssetName}"
	            );

				// 将直接依赖的AssetBundle引用计数+1（这个有问题）
				// 举例：
				// 第一步，加载A，A的AssetBundle依赖了X1, X2, X3
				// 第二步，加载B，B的AssetBundle依赖了X3, X4, X5，其中材质m在X3中，材质引用的贴图t在X5中
				// 第三步，卸载B, X3留，X4X5卸载了，那么材质m对贴图t的引用就断开了
				// 因此得出上述做法是错误的
				// 改法1: 不仅直接依赖的AssetBundle引用计数+1，间接依赖的AssetBundle引用计数也+1，但可以不直接加载到内存
				// 以为着在依赖链条中，第0层和第1层需要加载到内存，第2层及以上不需要加载到内存
				// 改法2：材质和他引用的贴图需要在一个AssetBundle中（不太容易做到）

				// 此为解法1
				var historySet = new HashSet<string>
				{
					assetBundleCache.AssetBundleName
				};
				IncreaseDepedenceRefCount(assetBundleCache, ref historySet);
            }
#else
	        if (string.IsNullOrEmpty(assetData.BundleName)) return;
	        var assetBundleCache = _assetBundleCachePool.GetOrCreateAssetBundleCache(assetData.BundleName);
	        assetBundleCache.Increase();
#endif
        }

#if USING_ORIGIN_BUNDLE_REF_COUNTER
		private void IncreaseDepedenceRefCount(AssetBundleCache mainBundleCache, ref HashSet<string> historySet)
		{
			var depData = BundleDependenceManager.Instance.GetBundleDependence(mainBundleCache.AssetBundleName);
			if (depData.HasDependence())
			{
				foreach (var dependentBundleName in depData.Dependence)
				{
					if (historySet.Contains(dependentBundleName))
					{
						continue;
					}

					historySet.Add(dependentBundleName);

					var assetBundleCache = _assetBundleCachePool.GetAssetBundleCache(dependentBundleName);
					if (assetBundleCache == null)
					{
						assetBundleCache = _assetBundleCachePool.AllocateAssetBundleCache(dependentBundleName);
					}
					assetBundleCache.Increase(
						//$"increase by depenpdence: {mainBundleCache.AssetBundleName}"
						);

					IncreaseDepedenceRefCount(assetBundleCache, ref historySet);
				}
			}
		}
#endif

        public void OnAssetCacheRelease(BundleAssetData assetData)
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
            if (!string.IsNullOrEmpty(assetData.BundleName))
            {
                var assetBundleCache = _assetBundleCachePool.GetAssetBundleCache(assetData.BundleName);
                if (assetBundleCache == null)
                {
                    throw new Exception($"{assetData.BundleName} AssetBundleCache not exist. Something must be wrong");
                }
                assetBundleCache.Decrease(
	                //$"decrease by direct: {assetData.AssetName}"
	            );

				// 将直接依赖的AssetBundle引用计数+1（这个有问题）
				// 举例：
				// 第一步，加载A，A的AssetBundle依赖了X1, X2, X3
				// 第二步，加载B，B的AssetBundle依赖了X3, X4, X5，其中材质m在X3中，材质引用的贴图t在X5中
				// 第三步，卸载B, X3留，X4X5卸载了，那么材质m对贴图t的引用就断开了
				// 因此得出上述做法是错误的
				// 改法1: 不仅直接依赖的AssetBundle引用计数+1，间接依赖的AssetBundle引用计数也+1，但可以不直接加载到内存
				// 以为着在依赖链条中，第0层和第1层需要加载到内存，第2层及以上不需要加载到内存
				// 改法2：材质和他引用的贴图需要在一个AssetBundle中（不太容易做到）

				// 此为解法1
				var historySet = new HashSet<string>
				{
					assetBundleCache.AssetBundleName
				};

				DecreaseDependenceRefCount(assetBundleCache, ref historySet);
			}
#else
	        if (string.IsNullOrEmpty(assetData.BundleName)) return;
	        var assetBundleCache = _assetBundleCachePool.GetAssetBundleCache(assetData.BundleName);
	        if (assetBundleCache == null)
	        {
		        throw new Exception($"{assetData.BundleName} AssetBundleCache not exist. Something must be wrong");
	        }
	        assetBundleCache.Decrease();
#endif
        }

#if USING_ORIGIN_BUNDLE_REF_COUNTER
		private void DecreaseDependenceRefCount(AssetBundleCache mainBundleCache, ref HashSet<string> historySet)
		{
			var depData = BundleDependenceManager.Instance.GetBundleDependence(mainBundleCache.AssetBundleName);
			if (depData.HasDependence())
			{
				foreach (var dependentBundleName in depData.Dependence)
				{
					if (historySet.Contains(dependentBundleName))
					{
						continue;
					}

					historySet.Add(dependentBundleName);

					var assetBundleCache = _assetBundleCachePool.GetAssetBundleCache(dependentBundleName);
					assetBundleCache.Decrease(
						//$"decrease by depenpdence: {mainBundleCache.AssetBundleName}"
						);

					DecreaseDependenceRefCount(assetBundleCache, ref historySet);
				}
			}
		}

		public AssetBundleCache LoadBundle(BundleAssetData data, bool isSyncRequest)
        {
            // TODO 此处bundle加载是同步方式（异步写法性价比不高，暂时不做）
            var cache = _assetBundleCachePool.GetAssetBundleCache(data.BundleName);
            if (cache == null)
            {
                cache = _assetBundleCachePool.AllocateAssetBundleCache(data.BundleName);
            }
            
            cache.Load(true, isSyncRequest);
            return cache;
        }
#else
		public AssetBundleCache LoadBundle(BundleAssetData data)
		{
			var cache = _assetBundleCachePool.GetOrCreateAssetBundleCache(data.BundleName);
            cache.Load();
            return cache;
        }
#endif

        #region 同步加载
        public Object LoadAsset(BundleAssetData data, bool isSprite)
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
            var cache = LoadBundle(data, true);
#else
            var cache = LoadBundle(data);
#endif
            return cache.LoadAsset(data.AssetName, isSprite);
        }
        #endregion


        #region 异步加载
        public bool LoadAssetAsync(BundleAssetData data, System.Action<Object> callback, bool isSprite)
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
            var cache = LoadBundle(data, false);
#else
            var cache = LoadBundle(data);
#endif
            return cache.LoadAssetAsync(data.AssetName, callback, isSprite);
        }
        #endregion
        

		/// <summary>
		/// 资源是否存在于bundle中，包括网络远端
		/// </summary>
		/// <param name="assetIndex"></param>
		/// <returns></returns>
        public bool AssetExist(string assetIndex)
        {
			return BundleAssetDataManager.Instance.ContainsAsset(assetIndex);
		}

		/// <summary>
		/// 资源是否在本地bundle中
		/// </summary>
		/// <param name="assetName"></param>
		/// <returns></returns>
        public bool IsAssetReady(string assetName)
        {
            var bundleAssetData = BundleAssetDataManager.Instance.GetAssetData(assetName);
            if (bundleAssetData == null)
            {
                NLogger.Error($"{assetName} not ready. Reason: no BundleAssetData found");
                return false;
            }

            var bundleName = bundleAssetData.BundleName;
#if !USING_ORIGIN_BUNDLE_REF_COUNTER
            var bundleCache = _assetBundleCachePool.GetAssetBundleCache(bundleName);
            if (bundleCache is { IsReadyForLoadAsset: true })
            {
	            return true;
            }
#endif
            var relativePath = PathHelper.GetBundleRelativePath(bundleName);
            if (!VersionControl.IsFileReady(relativePath))
            {
#if DETAIL_LOG_ON
	            NLogger.Warn($"{assetName} not ready. Reason: AssetBundle {bundleName} not ready.");
#endif
	            return false;
            }

            var depData = BundleDependenceManager.Instance.GetBundleDependence(bundleName);
            if (depData.HasDependence())
            {
                foreach (var dep in depData.Dependence)
                {
                    relativePath = PathHelper.GetBundleRelativePath(dep);
					if (!VersionControl.IsFileReady(relativePath))
					{
#if DETAIL_LOG_ON
                        NLogger.Warn($"{assetName} not ready. Reason: dependence AssetBundle {dep} not ready");
#endif
                        return false;
                    }
                }
            }

            return true;
        }
    }
}
