#if UNITY_DEBUG || UNITY_EDITOR
#define ASSET_DEBUG
#endif

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Unity.Collections.LowLevel.Unsafe;
using UnityEngine;

namespace DragonReborn.AssetTool
{
	public class AssetManager : Singleton<AssetManager>, IManager, ITicker
	{
		public enum SyncLoadReason
		{
			None,
			OptimizeForAsyncLoad,
			ResourceLoad,
			GMGUILoad,
		}

		private class AssetHandleWrap
		{
			public bool NeedRemove;
			public readonly AssetHandle AssetHandle;
			public AssetHandleWrap(AssetHandle handle)
			{
				AssetHandle = handle;
			}
		}

		private class AssetHandleList
		{
			public readonly List<AssetHandleWrap> HandleList = new(8);
		}

		private struct AsyncWaitUnloadUnused
		{
			public AsyncOperation Operation;
			public Action Callback;
		}

		public const string Channel = "AssetManager";
		
		private static readonly AssetHandle EmptyAssetHandle = new();
		private readonly Dictionary<string, AssetHandleList> _allAssetRequests = new();
		private readonly HashSet<AsyncWaitUnloadUnused> _operations = new();
		private readonly List<AsyncWaitUnloadUnused> _looping = new();

		public AssetCachePool AssetCachePool { get; } = new();
		public bool Initialized { get; private set; }
		
		private Dictionary<string, bool> _assetSyncLoadEnsureHistory;

#if ASSET_DEBUG
		private HashSet<string> _loadedAssets;
		private HashSet<string> _syncLoadAssets;
		private bool _logInit;
		private AssetWhiteList _assetWhiteList;

		private void InitLog()
		{
			_loadedAssets = new HashSet<string>();
			_syncLoadAssets = new HashSet<string>();
			_logInit = true;
		}

		private void RecordSyncLoad(string assetName)
		{
			if (!_logInit)
			{
				return;
			}

			if (!Application.isPlaying)
			{
				return;
			}

			if (string.IsNullOrEmpty(assetName))
			{
				return;
			}

			_syncLoadAssets.Add(assetName);
		}

		public void RecordAssetLoad(string assetName)
		{
			if (!Application.isPlaying)
			{
				return;
			}

			if (string.IsNullOrEmpty(assetName))
			{
				return;
			}
			
			IOAccessRecorder.RecordAsset(assetName);

			_assetWhiteList?.CheckAsset(assetName);

			_loadedAssets.Add(assetName);
		}

		public void ClearDebugInfo()
		{
			_loadedAssets.Clear();
			_syncLoadAssets.Clear();
		}

		public void DumpDebugInfo()
		{
			var path = Path.Combine(Application.persistentDataPath, "assets_sync_load.json");
			File.WriteAllText(path, DataUtils.ToJson(_syncLoadAssets.ToList()));

			path = Path.Combine(Application.persistentDataPath, "assets_load_order.json");
			File.WriteAllText(path, DataUtils.ToJson(_loadedAssets.ToList()));

			IOAccessRecorder.WriteDumpFile();
		}
		
		private void InitializeInEditor()
		{
			if (AssetCachePool == null)
			{
				OnGameInitialize(null);
			}
		}
		#else
		[System.Diagnostics.Conditional("DUMMY_FAKE_DISABLED")]
		public void RecordAssetLoad(string _)
		{
		}
		[System.Diagnostics.Conditional("DUMMY_FAKE_DISABLED")]
		public void ClearDebugInfo()
		{
		}
		[System.Diagnostics.Conditional("DUMMY_FAKE_DISABLED")]
		public void DumpDebugInfo()
		{
		}
#endif

		/// <summary>
		/// 游戏开始
		/// </summary>
		/// <param name="configParam"></param>
		public void OnGameInitialize(object configParam)
		{
			AssetCachePool.Initialize();

			AsyncRequestManager.Instance.Initialize();
			AsyncRequestManager.Instance.RequestMaxCount = 4;

			ObjectInstantiateManager.Instance.Initialize();
			ObjectInstantiateManager.Instance.ProcessMsPerFrame = 20;

			_assetSyncLoadEnsureHistory = new();

			ReloadAssetBundleConfig();
			
			Initialized = true;

#if ASSET_DEBUG
			InitLog();
			_assetWhiteList = new AssetWhiteList();
			_assetWhiteList.Initialize();
#endif
		}

		/// <summary>
		/// 游戏重启
		/// </summary>
		public void Reset()
		{
			Initialized = false;
			_allAssetRequests.Clear();
			_assetSyncLoadEnsureHistory.Clear();
			AssetCachePool.Reset();

			_operations.Clear();
			_looping.Clear();

			AsyncRequestManager.Instance.Reset();
			ObjectInstantiateManager.Instance.Reset();

#if ASSET_DEBUG
			_assetWhiteList.Reset();
			_assetWhiteList = null;
#endif
		}

		public void Tick(float delta)
		{
			UnloadUnusedTick();

			AsyncRequestManager.Instance.Tick(delta);
			ObjectInstantiateManager.Instance.Tick(delta);

#if ASSET_DEBUG
			_assetWhiteList?.Tick(delta);
#endif
		}

		public bool IsBundleMode()
		{
#if UNITY_EDITOR
#if USE_BUNDLE_IOS || USE_BUNDLE_ANDROID || USE_BUNDLE_STANDALONE
			return true;
#else
            return false;
#endif
#else
            return true;
#endif
		}

		/// <summary>
		/// 是否可以不通过网络下载直接加载
		/// </summary>
		/// <param name="assetName"></param>
		/// <returns></returns>
		public bool CanLoadSync(string assetName)
		{
			return ExistsInAssetSystem(assetName) && AssetCachePool.CheckCanSyncLoad(assetName);
		}

		public List<string> GetAllDependencyAssetBundles(string assetName)
		{
			var list = new List<string>();
			FillAllDependencyAssetBundles(assetName, list);
			return list;
		}

		public List<string> GetAllDependencyAssetBundlesByAssets(HashSet<string> assetNames)
		{
			var list = new List<string>();
			var result = new List<string>();
			foreach (var asset in assetNames)
			{
				list.Clear();
				FillAllDependencyAssetBundles(asset, list);

				// 去重
				foreach (var bundle in list)
				{
					if (!result.Contains(bundle))
					{
						result.Add(bundle);
					}
				}
			}

			return result;
		}

		private void FillAllDependencyAssetBundles(string assetName, List<string> dependentBundles)
		{
			if (!ExistsInAssetSystem(assetName))
			{
				return;
			}
			
			var assetData = BundleAssetDataManager.Instance.GetAssetData(assetName);
			if (assetData == null)
			{
				return;
			}

			dependentBundles.Add(assetData.BundleName);

			var dependencies = BundleDependenceManager.Instance.GetBundleDependence(assetData.BundleName);
			if (dependencies == null || !dependencies.HasDependence())
			{
				return;
			}

			dependentBundles.AddRange(dependencies.Dependence);
		}

		/// <summary>
		/// 检查资源是否存在于资源体系中
		/// </summary>
		/// <param name="assetName"></param>
		/// <param name="showError"></param>
		/// <returns></returns>
		public bool ExistsInAssetSystem(string assetName,
#if UNITY_DEBUG
			bool showError = true
#else
			bool showError = false
#endif
		)
		{
#if ASSET_DEBUG
			InitializeInEditor();
#endif

			if (string.IsNullOrEmpty(assetName))
			{
				if (showError) NLogger.ErrorChannel(Channel, "非法资源名，空字符串");
				return false;
			}

			if (AssetCachePool == null)
			{
				if (showError) NLogger.ErrorChannel(Channel, "状态异常：_assetCachePool == null");
				return false;
			}

			if (!AssetCachePool.IsAssetExist(assetName))
			{
				if (showError) NLogger.ErrorChannel(Channel, $"资源{assetName}不存在");
				return false;
			}

			return true;
		}

		public void CheckSyncLoadAssetsReady(HashSet<string> assetReady, List<string> readyAsset, List<string> needDownload, List<string> inValid)
		{
			foreach (var assetName in assetReady)
			{
				if (!ExistsInAssetSystem(assetName))
				{
					inValid.Add(assetName);
				}
				else if (AssetCachePool.CheckCanSyncLoad(assetName))
				{
					readyAsset.Add(assetName);
				}
				else
				{
					needDownload.Add(assetName);
				}
			}
		}

		/// <summary>
		/// 主动声明资源需要同步加载，并且给同步加载的资源做准备
		/// </summary>
		/// <param name="assetSet">需要同步加载的资源集合</param>
		/// <param name="needAssetsReady">是否等待资源准备完成</param>
		/// <param name="onAssetsReady">资源准备完成的回调</param>
		public void EnsureSyncLoadAssets(HashSet<string> assetSet, bool needAssetsReady, Action<bool> onAssetsReady)
		{
			foreach (var asset in assetSet)
			{
				NLogger.Log($"EnsureSyncLoadAssets {asset}");
				_assetSyncLoadEnsureHistory[asset] = true;
#if ASSET_DEBUG
				RecordSyncLoad(asset);
#endif
			}

			if (!needAssetsReady)
			{
				return;
			}

			EnsureAssets(assetSet, onAssetsReady);
		}

		public void EnsureAssets(HashSet<string> assetSet, Action<bool> onAssetsReady)
		{
			if (IsBundleMode())
			{
				var bundleList = GetAllDependencyAssetBundlesByAssets(assetSet);
				AssetBundleSyncManager.Instance.SyncAssetBundles(bundleList, onAssetsReady, null, (int)DownloadPriority.High);
			}
			else
			{
				onAssetsReady?.Invoke(true);
			}
		}

		public bool IsAssetEnsuredForSyncLoad(string assetName)
		{
			return _assetSyncLoadEnsureHistory.ContainsKey(assetName);
		}

		#region 同步加载
		/// <summary>
		/// 每一次LoadAsset，会得到一个新的AssetHandle
		/// AssetHandle获取到AssetCache后，AssetCache引用计数+1
		/// 同步加载使用规范：
		/// 1，同步加载是可选的，需要用CanSyncLoad判断
		/// 2, 同步加载是必须的，需要用EnsureSyncLoadAssets
		/// </summary>
		/// <param name="assetName">资产名称</param>
		/// <param name="isSprite">是否加载sprite</param>
		/// <param name="reason">同步加载的理由</param>
		/// <returns></returns>
		public AssetHandle LoadAsset(string assetName, bool isSprite = false, SyncLoadReason reason = SyncLoadReason.None)
		{
#if ASSET_DEBUG
			if (reason == SyncLoadReason.None)
			{
				//NLogger.WarnChannel(LOG_CHANNEL, $"LoadAssetSync {assetName}");
				RecordSyncLoad(assetName);
			}

			RecordAssetLoad(assetName);
#endif

			// 同步加载的规范检查
			if (reason == SyncLoadReason.None)
			{
				if (Application.isPlaying && !IsAssetEnsuredForSyncLoad(assetName))
				{
					NLogger.Error($"同步加载规范：同步加载{assetName}前，需要调用 AssetManager.Instance.EnsureSyncLoadAssets");
				}
			}

			// 资源体系中不存在，提前判定失败
			if (!ExistsInAssetSystem(assetName))
			{
				return EmptyAssetHandle;
			}

			var cacheIndex = assetName;
			var assetCache = AssetCachePool.GetAssetCache(cacheIndex);
			if (assetCache == null)
			{
				assetCache = AssetCachePool.AllocateAssetCache(cacheIndex);
			} 
			assetCache.Load(isSprite);

			var handle = new AssetHandle();
			assetCache.Increase();
			handle.SetAssetCache(assetCache);
			handle.cacheIndex = cacheIndex;
			handle.callback = null;

			if (!handle.Asset)
			{
				NLogger.ErrorChannel(Channel, $"LoadAsset: Failed to sync load {cacheIndex}.");
			}

			return handle;
		}

		public string LoadText(string textPath, SyncLoadReason reason = SyncLoadReason.None)
		{
			var handle = LoadAsset(textPath, false, reason);
			if (handle.Asset)
			{
				var textAsset = handle.Asset as TextAsset;
				if (textAsset == null)
				{
					NLogger.ErrorChannel(Channel, $"{textPath} is not TextAsset");
					return string.Empty;
				}

				var text = textAsset.text;
				UnloadAsset(handle);
				return text;
			}

			return string.Empty;
		}

		public byte[] LoadTextBytes(string textPath)
		{
			var handle = LoadAsset(textPath);
			if (handle.Asset)
			{
				var textAsset = handle.Asset as TextAsset;
				if (textAsset == null)
				{
					NLogger.ErrorChannel(Channel, $"{textPath} is not TextAsset");
					return null;
				}

				var text = textAsset.bytes;
				UnloadAsset(handle);
				return text;
			}
			return null;
		}

		public void LoadTextWithCallback(string textPath, Action<IntPtr, int> callback)
		{
			var handle = LoadAsset(textPath);
			if (handle.Asset == null)
			{
				return;
			}

			var textAsset = handle.Asset as TextAsset;
			if (textAsset == null)
			{
				NLogger.ErrorChannel(Channel, $"{textPath} is not TextAsset");
				return;
			}

			var array = textAsset.GetData<byte>();
			unsafe
			{
				var ptr = array.GetUnsafeReadOnlyPtr();
				callback((IntPtr)ptr, array.Length);
			}
			UnloadAsset(handle);
		}
		
		#endregion

		#region 智能加载

		public AssetHandle LoadAssetSmart(string assetName, bool sync = false, Action<bool, AssetHandle> callback = null, int priority = 0, bool isSprite = false)
		{
			if (sync && CanLoadSync(assetName))
			{
				var handle = LoadAsset(assetName, isSprite, SyncLoadReason.OptimizeForAsyncLoad);
				callback?.Invoke(handle.IsValid, handle);
				return handle;
			}

			return LoadAssetAsync(assetName, callback, isSprite, priority);
		}
		
		#endregion

		#region 异步加载
		/// <summary>
		/// 每一次LoadAssetAsync，会得到一个新的AssetHandle
		/// AssetHandle获取到AssetCache后，AssetCache引用计数+1
		/// </summary>
		/// <param name="assetName">资源名，无后缀</param>
		/// <param name="callback"></param>
		/// <returns></returns>
		public AssetHandle LoadAssetAsync(string assetName, Action<bool, AssetHandle> callback, bool isSprite = false, int priority = 0)
		{
#if ASSET_DEBUG
			RecordAssetLoad(assetName);
#endif

			if (!ExistsInAssetSystem(assetName))
			{
				var failedHandle = new AssetHandle
				{
					cacheIndex = assetName
				};
				callback?.Invoke(false, failedHandle);
				return failedHandle;
			}

			var cacheIndex = assetName;

			var handle = new AssetHandle();
			handle.cacheIndex = cacheIndex;
			handle.callback = callback;

			var assetCache = AssetCachePool.GetAssetCache(cacheIndex);
			// 资源已缓存
			if (assetCache != null && assetCache.AssetCacheState == AssetCacheState.complete)
			{
				assetCache.Increase();
				handle.SetAssetCache(assetCache);
				handle.callback?.Invoke(assetCache.Asset != null, handle);
				handle.callback = null;
				return handle;
			}

			// 有相同的Asset在请求中
			if (_allAssetRequests.TryGetValue(handle.cacheIndex, out var list))
			{
				list.HandleList.Add(new AssetHandleWrap(handle));
				return handle;
			}

			// 发起资源异步请求
			list = new AssetHandleList();
			list.HandleList.Add(new AssetHandleWrap(handle));
			_allAssetRequests.Add(cacheIndex, list);

			if (assetCache == null)
			{
				assetCache = AssetCachePool.AllocateAssetCache(cacheIndex);
			}

			assetCache.LoadAsync(OnAssetAsyncLoadCallback, isSprite, priority);

			return handle;
		}
		
		private readonly HashSet<AssetHandle> _currentAsyncCallbackHandles = new();
		private readonly Queue<AssetHandle> _delayUnloadAfterAsyncCallbackHandles = new();
		private int _onAssetAsyncLoadCallbackStackCount = 0;

		private void OnAssetAsyncLoadCallback(AssetCache assetCache)
		{
			++_onAssetAsyncLoadCallbackStackCount;
			try
			{
				DoOnAssetAsyncLoadCallback(assetCache);
			}
			finally
			{
				--_onAssetAsyncLoadCallbackStackCount;
				if (_onAssetAsyncLoadCallbackStackCount == 0)
				{
					while (_delayUnloadAfterAsyncCallbackHandles.TryDequeue(out var handle))
					{
						AssetCachePool.UnloadAsset(handle.cacheIndex);
					}
				}
			}
		}

		private void DoOnAssetAsyncLoadCallback(AssetCache assetCache)
		{
			if (_allAssetRequests.TryGetValue(assetCache.BundleAssetData.AssetName, out var list))
			{
				foreach (var handleWrapper in list.HandleList)
				{
					if (!handleWrapper.NeedRemove && handleWrapper.AssetHandle.callback != null)
					{
						var handle = handleWrapper.AssetHandle;
						_currentAsyncCallbackHandles.Add(handle);
						try
						{
							// 请求完成，返回资源
							assetCache.Increase();
							handleWrapper.AssetHandle.SetAssetCache(assetCache);
							handleWrapper.AssetHandle.callback(handleWrapper.AssetHandle.IsValid, handleWrapper.AssetHandle);
							handleWrapper.AssetHandle.callback = null;
						}
						finally
						{
							_currentAsyncCallbackHandles.Remove(handle);
						}
					}
				}

				_allAssetRequests.Remove(assetCache.BundleAssetData.AssetName);
			}
		}
		
		#endregion

		public void UnloadAsset(AssetHandle handle)
		{
			if (handle == null)
			{
				return;
			}

			// 请求中的资源取消请求
			if (handle.callback != null)
			{
				if (_allAssetRequests.TryGetValue(handle.cacheIndex, out var list))
				{
					var wrap = list.HandleList.Find(x => x.AssetHandle == handle);
					if (wrap != null)
					{
						wrap.NeedRemove = true;
					}
				}

				handle.callback = null;
				if (_currentAsyncCallbackHandles.Contains(handle))
				{
					_delayUnloadAfterAsyncCallbackHandles.Enqueue(handle);
				}
			}
			// 已经取得的资源卸载
			else
			{
				AssetCachePool.UnloadAsset(handle.cacheIndex);
			}
		}

		// 卸载引用计数为0的资源
		public void UnloadUnused(Action callback = null)
		{
			AssetCachePool.ClearUnused();
			var operation = Resources.UnloadUnusedAssets(); //Resources.UnloadUnusedAssets()是异步处理的
			_operations.Add(new AsyncWaitUnloadUnused
			{
				Operation = operation,
				Callback = callback
			});
			
			//https://stackoverflow.com/questions/17538570/sequence-of-gc-and-unloading-assets-in-unity3d
			// GC.Collect();
		}

		private void UnloadUnusedTick()
		{
			_looping.AddRange(_operations);

			foreach (var unused in _looping)
			{
				if (unused.Operation.isDone)
				{
					unused.Callback?.Invoke();
					_operations.Remove(unused);
				}
			}

			_looping.Clear();
		}

		/// <summary>
		/// 加载AssetBundle配置信息
		/// </summary>
		public void ReloadAssetBundleConfig()
		{
			if (!IsBundleMode())
			{
				return;
			}

			BundleDependenceManager.Instance.LoadBundleDependence();
			BundleAssetDataManager.Instance.LoadAssetBundleConfig();
		}

		public static string[] DumpAllLoadedBundleName()
		{
			var allLoadedBundle = AssetBundle.GetAllLoadedAssetBundles();
			var names = System.Linq.Enumerable.Select(allLoadedBundle, a => a.name);
			var ret = System.Linq.Enumerable.ToArray(names);
			Array.Sort(ret, StringComparer.Ordinal);
			return ret;
		}

		public void OnLowMemory()
		{

		}

		internal void DumpCurrentAssetCacheInfo(List<AssetCacheInfo> writeTo, List<BundleCacheInfo> bundleWriteTo)
		{
			AssetCachePool.DumpCurrentAssetCacheInfo(writeTo, bundleWriteTo);
		}
	}
}
