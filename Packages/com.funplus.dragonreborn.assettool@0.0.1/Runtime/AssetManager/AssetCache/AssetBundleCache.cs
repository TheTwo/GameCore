// #define USING_ORIGIN_BUNDLE_REF_COUNTER
using System;
using UnityEngine;
using UnityEngine.Profiling;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
#if !USING_ORIGIN_BUNDLE_REF_COUNTER
	[Flags]
#endif
    public enum AssetBundleLoadingState
    {
	    // ReSharper disable InconsistentNaming
	    // ReSharper disable UnusedMember.Global
#if USING_ORIGIN_BUNDLE_REF_COUNTER
        none,
        loading,
        complete,
#else
	    none = 0,
	    depLoaded = 1 << 0,
        selfLoaded = 1 << 1,
        complete = depLoaded | selfLoaded,
#endif
	    // ReSharper restore UnusedMember.Global
	    // ReSharper restore InconsistentNaming
    }

	public class AssetBundleCache : BaseRefCounter
	{
		private AssetBundle _assetBundle;
#if UNITY_DEBUG
		public string AssetBundleFullPath { get; private set; }
#endif
		private readonly string _bundleName;
		private string _cacheHashName;
		private ulong _cacheOffset;
		private BundleDependenceData _dependenceData;
		private AssetBundleLoadingState _state = AssetBundleLoadingState.none;
		public AssetBundleLoadingState State => _state;
#if USING_ORIGIN_BUNDLE_REF_COUNTER
		private AssetBundleLoadingState LoadingState => _state;
		private bool _allDependenceLoaded = false;
		private AssetBundleCachePool _assetBundleCachePool;
#else
		private readonly AssetBundleCachePool _assetBundleCachePool;
		public int ByRefCount { get; private set; }
		public bool IsReadyForLoadAsset => (_state & AssetBundleLoadingState.complete) != 0;
		private bool _assetLoadFlag;
#endif

		public AssetBundleCache(string bundleName, AssetBundleCachePool pool)
		{
			_bundleName = bundleName;
			_assetBundleCachePool = pool;
		}

		public string AssetBundleName => _bundleName;

		public void Initialize()
		{
			_dependenceData = BundleDependenceManager.Instance.GetBundleDependence(_bundleName);
		}

		public void Reset()
		{
#if USING_ORIGIN_BUNDLE_REF_COUNTER
			Release();
			ResetRefCount();
#else
			ReleaseLoadedDep();
			ReleaseSelf();
			ResetRefCount();
			_assetLoadFlag = false;
			ByRefCount = 0;
			_assetBundleCachePool.RemoveFromCache(_bundleName);
#endif
		}

#if USING_ORIGIN_BUNDLE_REF_COUNTER
        // 由引用计数管理卸载
        private void Release()
        {
            if (_assetBundle != null)
            {
                // 销毁AssetBundle加载出来的资源
                _assetBundle.Unload(true);
				_assetBundle = null;
#if UNITY_DEBUG
				AssetBundleFullPath = string.Empty;
#endif
				_assetBundleCachePool.UnloadRemainedBundles(_bundleName);

				//if (_bundleName.Contains("mat_v") ||
				//	_bundleName.Contains("daoguang"))
				//{
				//	NLogger.ErrorChannel(LOG_CHANNEL, $"AssetBundle Unload {Time.frameCount} {_bundleName} true");
				//}
				//else
				{
					NLogger.Log($"AssetBundle Unload {Time.frameCount} {_bundleName} true");
				}
            }

            _dependenceData = null;
        }
#else
		private void ReleaseLoadedDep()
		{
			if ((_state & AssetBundleLoadingState.depLoaded) == 0) return;
			_state &= ~AssetBundleLoadingState.depLoaded;
			if (!_dependenceData.HasDependence()) return;
			foreach (var dependenceBundleName in _dependenceData.Dependence)
			{
				var bundleCache = _assetBundleCachePool.GetAssetBundleCache(dependenceBundleName);
				bundleCache?.RemoveByRefCount();
			}
		}
		
        private void ReleaseSelf()
        {
			_state &= ~AssetBundleLoadingState.selfLoaded;
			if (_assetBundle != null)
            {
				// 销毁AssetBundle加载出来的资源
				_assetBundle.Unload(true);
				_assetBundle = null;
#if UNITY_DEBUG
				AssetBundleFullPath = string.Empty;
#endif
				NLogger.Log($"AssetBundle Unload {Time.frameCount} {_bundleName} true");
            }
			_dependenceData = null;
			_assetLoadFlag = false;
		}
#endif
		
        public override void Increase(string log = "")
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
            //_behaviorLog.Add(log);

            base.Increase();

			//if (!string.IsNullOrEmpty(log))
			//{
			//	if (_bundleName.Contains("mat_v") ||
			//		_bundleName.Contains("daoguang"))
			//	{
			//		NLogger.ErrorChannel(LOG_CHANNEL, $"{_bundleName} {log}, count {GetRefCount()}");
			//	}
			//}
#else
	        var oldCount = GetRefCount();
            base.Increase(log);
            if (oldCount > 0) return;
            LoadDep();
#endif
		}

        public override bool Decrease(string log = "")
        {
#if USING_ORIGIN_BUNDLE_REF_COUNTER
            //_behaviorLog.Add(log);

			var isZero = base.Decrease();
            if (isZero)
            {
                Release();
                
                _assetBundleCachePool.CleanZeroBundle();
            }

			//if (!string.IsNullOrEmpty(log))
			//{
			//	if (_bundleName.Contains("mat_v") ||
			//		_bundleName.Contains("daoguang"))
			//	{
			//		NLogger.ErrorChannel(LOG_CHANNEL, $"{_bundleName} {log}, count {GetRefCount()}");
			//	}
			//}

			return isZero;
#else
			var isZero = base.Decrease(log);
			if (!isZero) return false;
			if (ByRefCount > 0)
			{
				if (!_assetLoadFlag) ReleaseLoadedDep();
				return false;
			}
			ReleaseLoadedDep();
            ReleaseSelf();
            _assetBundleCachePool.RemoveFromCache(_bundleName);
            return true;
#endif
        }
#if !USING_ORIGIN_BUNDLE_REF_COUNTER
        private void AddByRefCount()
        {
	        ++ByRefCount;
        }

        private void RemoveByRefCount()
        {
	        --ByRefCount;
	        if (ByRefCount > 0) return;
	        ByRefCount = 0;
	        if (GetRefCount() > 0) return;
	        ReleaseLoadedDep();
	        ReleaseSelf();
	        _assetBundleCachePool.RemoveFromCache(_bundleName);
        }
#endif

        #region 同步加载Asset
        public UnityEngine.Object LoadAsset(string assetName, bool isSprite)
        {
            if (_assetBundle == null)
            {
                // EventManager.Instance.TriggerEvent(new LoadExistBundleFail(_bundleName, assetName));
                Debug.LogError($"Load {assetName} from AssetBundle {_bundleName} failed.");
                return null;
            }

            if (string.IsNullOrEmpty(assetName))
            {
                throw new Exception("AssetBundleCache Load Asset error, assetName is empty string");
            }

            if (isSprite)
            {
                return _assetBundle.LoadAsset<Sprite>(assetName);
            }
            _assetLoadFlag = true;
            return _assetBundle.LoadAsset(assetName);
        }
        #endregion

        #region 异步加载Asset
        public bool LoadAssetAsync(string assetName, Action<UnityEngine.Object> callback, bool isSprite)
        {
            if (_assetBundle == null)
            {
                callback(null);
                return false;
            }

            if (string.IsNullOrEmpty(assetName))
            {
                callback(null);
                return false;
            }
            
            AssetBundleRequest request;
            if (isSprite)
            {
                request = _assetBundle.TrackedAsyncLoad<Sprite>(assetName);
            }
            else
            {
	            _assetLoadFlag = true;
                request = _assetBundle.TrackedAsyncLoad(assetName);    
            }
            
            var task = AsyncRequest<AssetBundleRequest>.Create(request, OnAssetBundleRequestDone, callback);
            AsyncRequestManager.Instance.AddTask(task);
            return request != null;
        }
        
        private void OnAssetBundleRequestDone(AssetBundleRequest req, object userData)
        {
            if (userData is Action<UnityEngine.Object> callback)
            {
                callback(req.asset);
            }
        }
        #endregion

        #region 同步加载AssetBundle
#if USING_ORIGIN_BUNDLE_REF_COUNTER
        public void Load(bool loadDependence, bool isSyncRequest)
        {
            if (_state == AssetBundleLoadingState.none)
            {
                if (_dependenceData.HasDependence() && loadDependence)
                {
                    var tempFlag = true;
                    foreach (var dependenceBundleName in _dependenceData.Dependence)
                    {
                        var bundleCache = _assetBundleCachePool.GetAssetBundleCache(dependenceBundleName);
                        if (bundleCache == null)
                        {
                            bundleCache = _assetBundleCachePool.AllocateAssetBundleCache(dependenceBundleName);
                        }
                        bundleCache.Load(false, isSyncRequest);
                        
                        if (bundleCache.LoadingState != AssetBundleLoadingState.complete)
                        {
                            tempFlag = false;
                        }
                    }
                    _allDependenceLoaded = tempFlag;
                }

                var hashName = _dependenceData.BundleName;
                if (hashName != _cacheHashName)
                {
                    _cacheHashName = hashName;
					_cacheOffset = AssetBundleConfig.Instance.GetHeadOffset(hashName);
				}

                var bundleRelPath = PathHelper.GetBundleRelativePath(_bundleName);
                var fullPath = IOUtils.GetGameAssetPath(bundleRelPath);
                if (!string.IsNullOrEmpty(fullPath))
                {
	                _assetBundleCachePool.CheckReloadRemainedBundle(_bundleName);

                    try
                    {
	                    IOAccessRecorder.RecordFile(bundleRelPath);

#if UNITY_DEBUG
	                    Profiler.BeginSample($"Load Bundle: Path = {fullPath}");
	                    AssetBundleFullPath = fullPath;
#endif
	                    
						_assetBundle = AssetBundle.LoadFromFile(fullPath, 0, _cacheOffset);

#if UNITY_DEBUG
	                    Profiler.EndSample();
#endif

						if (isSyncRequest)
						{
							NLogger.Log($"[LogForDebug] load {fullPath} by sync request");
						}
                    }
                    catch (Exception e)
                    {
						NLogger.ErrorChannel("AssetBundle", $"load AssetBundle {fullPath} hashName {hashName} offset {_cacheOffset}, Error: {e.Message}");
                    }

                    if (_assetBundle != null)
                    {
                        _state = AssetBundleLoadingState.complete;

	                    NLogger.Log($"AssetBundle Load {Time.frameCount} {_bundleName} complete");
                    }
                    else
                    {
                        // 加载失败，ab应该是损坏了
						IOUtils.DeleteGameAsset(PathHelper.GetBundleRelativePath(_bundleName));
						NLogger.ErrorChannel("AssetBundle", "asset bundle full path {0}-{1} create failed will delete damaged", fullPath, _bundleName);
					}
                }
                else
                {
                    Debug.LogError($"asset bundle {_bundleName}-{hashName} file not exist");
                }
            }
            //如果自身加载完毕，还需要检查依赖项是否完全加载完毕
            else if (_state == AssetBundleLoadingState.complete)
            {
                if (_dependenceData.HasDependence() && loadDependence && !_allDependenceLoaded)
                {
                    var tempFlag = true;
                    foreach (var dependenceBundleName in _dependenceData.Dependence)
                    {
                        var bundleCache = _assetBundleCachePool.GetAssetBundleCache(dependenceBundleName);
                        if (bundleCache == null)
                        {
                            bundleCache = _assetBundleCachePool.AllocateAssetBundleCache(dependenceBundleName);
                        }
                        
                        bundleCache.Load(false, isSyncRequest);
                        if (bundleCache.LoadingState != AssetBundleLoadingState.complete)
                        {
                            tempFlag = false;
                        }
                    }
                    _allDependenceLoaded = tempFlag;
                }
            }
        }
#else
        public void Load()
        {
	        LoadDep();
	        LoadSelf();
        }

        private void LoadDep()
        {
	        if ((_state & AssetBundleLoadingState.depLoaded) != 0) return;
	        _state |= AssetBundleLoadingState.depLoaded;
	        if (!_dependenceData.HasDependence()) return;
	        foreach (var dependenceBundleName in _dependenceData.Dependence)
	        {
		        var bundleCache = _assetBundleCachePool.GetOrCreateAssetBundleCache(dependenceBundleName);
		        bundleCache.LoadSelf();
		        bundleCache.AddByRefCount();
	        }
        }

        private void LoadSelf()
        {
	        if ((_state & AssetBundleLoadingState.selfLoaded) != 0) return;
	        var hashName = _dependenceData.BundleName;
	        if (hashName != _cacheHashName)
	        {
		        _cacheHashName = hashName;
		        _cacheOffset = AssetBundleConfig.Instance.GetHeadOffset(hashName);
	        }
	        var bundleRelPath = PathHelper.GetBundleRelativePath(_bundleName);
	        var fullPath = IOUtils.GetGameAssetPath(bundleRelPath);
	        if (!string.IsNullOrEmpty(fullPath))
	        {
		        try
		        {
			        IOAccessRecorder.RecordFile(bundleRelPath);

#if UNITY_DEBUG
			        Profiler.BeginSample($"Load Bundle: Path = {fullPath}");
			        AssetBundleFullPath = fullPath;
#endif
			        _assetBundle = AssetBundle.LoadFromFile(fullPath, 0, _cacheOffset);

#if UNITY_DEBUG
			        Profiler.EndSample();
#endif
		        }
		        catch (Exception e)
		        {
			        NLogger.ErrorChannel("AssetBundle", $"load AssetBundle {fullPath} hashName {hashName} offset {_cacheOffset}, Error: {e.Message}");
		        }

		        if (_assetBundle != null)
		        {
			        _state |= AssetBundleLoadingState.selfLoaded;

			        NLogger.Log($"AssetBundle Load {Time.frameCount} {_bundleName} complete");
		        }
		        else
		        {
			        // 加载失败，ab应该是损坏了
			        IOUtils.DeleteGameAsset(PathHelper.GetBundleRelativePath(_bundleName));
			        NLogger.ErrorChannel("AssetBundle", "asset bundle full path {0}-{1} create failed will delete damaged", fullPath, _bundleName);
		        }
	        }
	        else
	        {
		        Debug.LogError($"asset bundle {_bundleName}-{hashName} file not exist");
	        }
        }
#endif
        #endregion

        public string ToDebugString(bool showLog = false)
        {
			//_sb.Clear();
			//_sb.Append($"{_bundleName}\tRef:{GetRefCount()}");
			//if (showLog)
			//{
			//    _sb.AppendLine();
			//    foreach (var log in _behaviorLog)
			//    {
			//        _sb.AppendLine($"\t{log}");
			//    }
			//}
			//return _sb.ToString();
			return string.Empty;
        }
    }
}
