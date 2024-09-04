using System;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;
using Object = UnityEngine.Object;

namespace DragonReborn.AssetTool
{
	/// <summary>
	/// 对象池支持同步和异步创建对象
	/// 对象池使用需要先AddRouteMapping注册，或者WarmUp调用
	/// 之后才可以使用Create函数
	/// </summary>
	internal class GameObjectPool
	{
		private static readonly Comparison<GameObjectRequest> RequestComparer = RequestCompare;
		private static readonly Comparison<GameObjectPoolDelayRecycle> RecycleComparer = RecycleCompare;

		private readonly string _name;
		private readonly FrequencyCache<GameObjectCache> _cacheDict;
		private readonly List<GameObjectCache> _looping = new();
		private readonly List<GameObjectRequest> _usedRequests = new();
		private readonly ObjectPool<GameObjectRequest> _freeRequests = new();
		private readonly Transform _rootNode;
		private readonly List<GameObjectPoolDelayRecycle> _recycles = new();
		private readonly Stopwatch _stopwatch = new();

		public long ProcessMsPerFrame { get; set; } = 5;

		public GameObjectPool(string name, int poolCacheSize, Transform rootNode)
		{
			_name = name;
			_cacheDict = new FrequencyCache<GameObjectCache>(poolCacheSize, OnDelete);
			_rootNode = rootNode;
		}

		public int CacheSize
		{
			get => _cacheDict.CacheSize;
			set => _cacheDict.CacheSize = Mathf.Max(value, 1);
		}
		
		public void ClearCache()
		{
			CancelAll();

			_cacheDict.Clear();
			_usedRequests.Clear();
			_freeRequests.Clear();
			
			foreach (var recycle in _recycles)
			{
				recycle.Destroy();
			}

			_recycles.Clear();
		}

		public void WarmUp(string prefabName, int count, Action<GameObject> warmUpSingle = null,
			Action warmUpDone = null, int warmUpInstTickCount = 1)
		{
			var cacheInfo = EnsureGameObjectCache(prefabName);
			cacheInfo.WarmUpSingle = warmUpSingle;
			cacheInfo.WarmUpDone = warmUpDone;
			cacheInfo.WarmUpCount = count;
			cacheInfo.WarmUpCountPerTick = warmUpInstTickCount;

			if (cacheInfo.State == GameObjectCacheState.NotReady)
			{
				cacheInfo.State = GameObjectCacheState.Loading;
				cacheInfo.Handle = AssetManager.Instance.LoadAssetAsync(prefabName, CreateLoadedCallback(cacheInfo, "Warmup"));
			}
		}

		public void Create(string prefabName, Transform parent, Vector3 pos, Quaternion rot, Vector3 scale,
			out GameObjectRequest request, GameObjectRequestCallback callback, object userData = null, int priority = 0,
			bool syncCreate = false, bool syncLoad = false)
		{
			var cacheInfo = EnsureGameObjectCache(prefabName);
			request = AllocateRequest(cacheInfo, parent, pos, rot, scale, priority, syncCreate, callback, userData);

			if (cacheInfo == null)
			{
				SafeCall(prefabName, callback, null, userData);
				ReleaseRequest(request);
				return;
			}

			if (syncCreate)
			{
				if (cacheInfo.Prefab != null)
				{
					var go = InternalSpawnGameObject(cacheInfo, parent, pos, rot, scale);
					SafeCall(prefabName, callback, go, userData);
					ReleaseRequest(request);
				}
				else
				{
					if (syncLoad &&
					    cacheInfo.State == GameObjectCacheState.NotReady &&
					    AssetManager.Instance.CanLoadSync(prefabName))
					{
						cacheInfo.State = GameObjectCacheState.Loading;
						cacheInfo.Handle = AssetManager.Instance.LoadAsset(prefabName, false, AssetManager.SyncLoadReason.OptimizeForAsyncLoad);
						var loaded = CreateLoadedCallback(cacheInfo, "Sync");
						loaded(cacheInfo.Handle.IsValid, cacheInfo.Handle);

						var go = InternalSpawnGameObject(cacheInfo, parent, pos, rot, scale);
						SafeCall(prefabName, callback, go, userData);
						ReleaseRequest(request);
					}
					else
					{
						cacheInfo.Increase();
						_usedRequests.Add(request);
					}
				}
			}
			else
			{
				cacheInfo.Increase();
				_usedRequests.Add(request);
			}
		}

		public void Destroy(GameObjectCache pending, GameObject go, float delay)
		{
			if (!go)
			{
				return;
			}

			_cacheDict.TryGet(pending.PrefabName, out var cacheInfo);
			if (cacheInfo == null || pending != cacheInfo)
			{
#if UNITY_EDITOR
				if (Application.isPlaying)
				{
					Object.Destroy(go, delay);
				}
				else
				{
					Object.DestroyImmediate(go);
				}
#else
				Object.Destroy(go, delay);
#endif
			}
			else
			{
				if (delay <= 0)
				{
					cacheInfo.Recycle(go);
				}
				else
				{
					_recycles.Add(new GameObjectPoolDelayRecycle
					{
						Cache = cacheInfo,
						Instance = go,
						Remaining = delay
					});
				}
			}
		}
		
		private void CancelAll()
		{
			foreach (var request in _usedRequests)
			{
				request.Cancel = true;
				request.Cache.Decrease();
				ReleaseRequest(request);
			}

			_usedRequests.Clear();
		}

		public void Tick(float delta)
		{
			ProcessSingleRequest();
			ProcessDelayRecycle(delta);
		}

		private GameObjectRequest AllocateRequest(GameObjectCache cacheInfo, Transform parent, Vector3 pos,
			Quaternion rot, Vector3 scale, int priority, bool syncCreate, GameObjectRequestCallback callback,
			object userData)
		{
			var request = _freeRequests.Allocate();
			request.Cache = cacheInfo;
			request.Callback = callback;
			request.UserData = userData;
			request.Parent = parent;
			request.Priority = priority;
			request.SyncCreate = syncCreate;
			request.Position = pos;
			request.Rotation = rot;
			request.Scale = scale;
			return request;
		}

		private void ReleaseRequest(GameObjectRequest request)
		{
			if (request == null)
			{
				return;
			}
			
			request.Reset(); // 防止闭包引起的内存泄露
			_freeRequests.Release(request);
		}

		private GameObjectCache EnsureGameObjectCache(string prefabName)
		{
			if (string.IsNullOrEmpty(prefabName))
			{
				return null;
			}

			_cacheDict.TryGet(prefabName, out var cacheInfo);
			if (cacheInfo != null)
			{
				if (cacheInfo.Corrupted)
				{
					NLogger.ErrorChannel("GameObjectPool", $"EnsureGameObjectCache: Prefab was corrupted. Prefab = {cacheInfo.PrefabName}, State = {cacheInfo.State}");
					_cacheDict.Remove(prefabName, true);
				}
				else
				{
					return cacheInfo;
				}
			}
			
			cacheInfo = new GameObjectCache { PrefabName = prefabName };
			cacheInfo.Increase();
			_cacheDict.Add(prefabName, cacheInfo);

			return cacheInfo;
		}

		private void ProcessSingleRequest()
		{
			// Warm Up
			foreach (var pair in _cacheDict)
			{
				_looping.Add(pair.Value);
			}

			foreach (var cacheInfo in _looping)
			{
				InternalWarmUp(cacheInfo); // WarmUp的回调函数可能会操作_cacheDict
			}

			_looping.Clear();

			_usedRequests.Sort(RequestComparer);

			// 删除尾部的被取消的请求
			while (_usedRequests.Count > 0)
			{
				var lastIndex = _usedRequests.Count - 1;
				var request = _usedRequests[lastIndex];
				if (request.Cancel)
				{
					_usedRequests.RemoveAt(lastIndex);
					request.Cache.Decrease();
					ReleaseRequest(request);
				}
				else
				{
					break;
				}
			}

			// 启动尾部未开始的请求
			for (var i = _usedRequests.Count - 1; i >= 0; --i)
			{
				var request = _usedRequests[i];
				if (request.Cache.State == GameObjectCacheState.NotReady)
				{
					request.Cache.State = GameObjectCacheState.Loading;
					request.Cache.Handle = AssetManager.Instance.LoadAssetAsync(request.Cache.PrefabName, CreateLoadedCallback(request.Cache, "Async"));
				}
				else
				{
					break;
				}
			}

			// 如果头部有已经失败的请求，则先将头部所有失败的请求删掉
			var failureCount = CalculateFailureCount(_usedRequests);
			if (failureCount > 0)
			{
				for (var index = 0; index < failureCount; ++index)
				{
					var request = _usedRequests[index];
					SafeCall(request.Cache.PrefabName, request.Callback, null, request.UserData);
					request.Cache.Decrease();
					ReleaseRequest(request);
				}

				_usedRequests.RemoveRange(0, failureCount);
			}

			// 如果头部有已经就绪并且需要立即实例化的请求，则处理所有需要立即实例化的请求
			var syncCreateCount = CalculateSyncCreationCount(_usedRequests);
			if (syncCreateCount > 0)
			{
				for (var index = 0; index < syncCreateCount; ++index)
				{
					var request = _usedRequests[index];
					var go = InternalSpawnGameObject(request.Cache, request.Parent, request.Position, request.Rotation, request.Scale);
					SafeCall(request.Cache.PrefabName, request.Callback, go, request.UserData);
					request.Cache.Decrease();
					ReleaseRequest(request);
				}

				_usedRequests.RemoveRange(0, syncCreateCount);
			}

			// 如果头部有已经就绪并且需要分帧实例化的请求，则处理所有需要分帧实例化的请求
			var readyCount = CalculateReadyCount(_usedRequests);
			if (readyCount > 0)
			{
				_stopwatch.Start();
				var creationCount = 0;
				while (creationCount < readyCount)
				{
					var request = _usedRequests[creationCount];
					var go = InternalSpawnGameObject(request.Cache, request.Parent, request.Position, request.Rotation, request.Scale);
					SafeCall(request.Cache.PrefabName, request.Callback, go, request.UserData);
					request.Cache.Decrease();
					ReleaseRequest(request);
					++creationCount;
				
					var elapsedMilliseconds = _stopwatch.ElapsedMilliseconds;
					if (elapsedMilliseconds >= ProcessMsPerFrame)
					{
						break;
					}
				}
			
				_usedRequests.RemoveRange(0, creationCount);
				_stopwatch.Reset();
			}
		}

		private static int CalculateFailureCount(IReadOnlyList<GameObjectRequest> requests)
		{
			var index = 0;
			while (index < requests.Count)
			{
				var request = requests[index];
				if (request.Cache.State == GameObjectCacheState.Failure)
				{
					++index;
				}
				else
				{
					break;
				}
			}

			return index;
		}

		private static int CalculateSyncCreationCount(IReadOnlyList<GameObjectRequest> requests)
		{
			var index = 0;
			while (index < requests.Count)
			{
				var request = requests[index];
				if (request.SyncCreate && request.Cache.State == GameObjectCacheState.Ready)
				{
					++index;
				}
				else
				{
					break;
				}
			}

			return index;
		}
		
		private static int CalculateReadyCount(IReadOnlyList<GameObjectRequest> requests)
		{
			var index = 0;
			while (index < requests.Count)
			{
				var request = requests[index];
				if (request.Cache.State == GameObjectCacheState.Ready)
				{
					++index;
				}
				else
				{
					break;
				}
			}

			return index;
		}
		
		private void ProcessDelayRecycle(float dt)
		{
			// 更新剩余时间
			var loops = _recycles.Count;
			for (var i = 0; i < loops; i++)
			{
				var recycle = _recycles[i];
				recycle.Remaining -= dt;
				_recycles[i] = recycle;
			}
            
			// 根据剩余时间降序排序
			_recycles.Sort(RecycleComparer);

			// 回收过期的GameObject
			while (_recycles.Count > 0)
			{
				var lastIndex = _recycles.Count - 1;
				var lastRecycle = _recycles[lastIndex];
				if (lastRecycle.Remaining > 0)
				{
					break;
				}
                
				lastRecycle.Cache.Recycle(lastRecycle.Instance);
				_recycles.RemoveAt(lastIndex);
			}
		}
        
		private static int RecycleCompare(GameObjectPoolDelayRecycle x, GameObjectPoolDelayRecycle y)
		{
			return Math.Sign(y.Remaining - x.Remaining);
		}

		private static int RequestCompare(GameObjectRequest x, GameObjectRequest y)
		{
			// 取消的请求排在最后面
			var xCancel = x.Cancel ? 1 : 0;
			var yCancel = y.Cancel ? 1 : 0;
			
			var cancelDiff = Comparer<int>.Default.Compare(xCancel, yCancel);
			if (cancelDiff != 0)
			{
				return cancelDiff;
			}

			// 排列顺序：Failure > Ready > Loading > NotReady
			var xState = (int)x.Cache.State;
			var yState = (int)y.Cache.State;
			var stateDiff = Comparer<int>.Default.Compare(yState, xState);
			if (stateDiff != 0)
			{
				return stateDiff;
			}

			// 同步实例化的排在前面
			var xImmediately = x.SyncCreate ? 1 : 0;
			var yImmediately = y.SyncCreate ? 1 : 0;
			var immediatelyDiff = Comparer<int>.Default.Compare(yImmediately, xImmediately);
			if (immediatelyDiff != 0)
			{
				return immediatelyDiff;
			}

			// 优先级数值大的排在前面
			return Comparer<int>.Default.Compare(y.Priority, x.Priority);
		}

		private Action<bool, AssetHandle> CreateLoadedCallback(GameObjectCache cacheInfo, string reason)
		{
			void Callback(bool ret, AssetHandle handle)
			{
				var prefabName = handle.cacheIndex;
				if (cacheInfo != null)
				{
					var prefab = handle.Asset as GameObject;
					if (prefab)
					{
						if (cacheInfo.State == GameObjectCacheState.Loading)
						{
							cacheInfo.Initialize(handle, _rootNode);
							cacheInfo.State = GameObjectCacheState.Ready;	
						}
						else
						{
							NLogger.ErrorChannel("GameObjectPool", $"CreateLoadedCallback: Prefab is not in Loading state. PrefabName = {prefabName}, Reason = {reason}, State = {cacheInfo.State}, RefCount = {cacheInfo.RefCount}");
							AssetManager.Instance.UnloadAsset(handle);
						}
					}
					else
					{
						NLogger.ErrorChannel("GameObjectPool", $"CreateLoadedCallback: Prefab '{prefabName}' may be broken.");
						cacheInfo.State = GameObjectCacheState.Failure;
						AssetManager.Instance.UnloadAsset(handle);
					}
				}
				else
				{
					NLogger.ErrorChannel("GameObjectPool", $"CreateLoadedCallback: Cache for {prefabName} doesn't exist.");
					AssetManager.Instance.UnloadAsset(handle);
				}
			}

			return Callback;
		}

		private static GameObject InternalSpawnGameObject(GameObjectCache cacheInfo, Transform parent, Vector3 pos,
			Quaternion rot, Vector3 scale)
		{
			var go = cacheInfo.Allocate();
			if (go)
			{
				go.transform.SetParent(parent);
				go.transform.localPosition = pos;
				go.transform.localRotation = rot;
				go.transform.localScale = scale;	
			}
			return go;
		}

		private void InternalWarmUp(GameObjectCache cacheInfo)
		{
			switch (cacheInfo.State)
			{
				case GameObjectCacheState.Ready:
				{
					if (cacheInfo.WarmUpCount > 0)
					{
						for (var i = 0; i < cacheInfo.WarmUpCountPerTick; i++)
						{
							var go = cacheInfo.Instantiate();
							if (go)
							{
								SafeCall(cacheInfo.PrefabName, cacheInfo.WarmUpSingle, go);
								cacheInfo.Recycle(go);
							}

							--cacheInfo.WarmUpCount;

							if (cacheInfo.WarmUpCount == 0)
							{
								SafeCall(cacheInfo.PrefabName, cacheInfo.WarmUpDone);
								cacheInfo.WarmUpDone = null;
								cacheInfo.WarmUpSingle = null;
								break;
							}
						}
					}
					else
					{
						SafeCall(cacheInfo.PrefabName, cacheInfo.WarmUpDone);
						cacheInfo.WarmUpDone = null;
						cacheInfo.WarmUpSingle = null;
					}

					break;
				}

				case GameObjectCacheState.Failure:
					SafeCall(cacheInfo.PrefabName, cacheInfo.WarmUpDone);
					cacheInfo.WarmUpDone = null;
					cacheInfo.WarmUpSingle = null;
					cacheInfo.WarmUpCount = 0;
					break;
			}
		}
		
		private void SafeCall(string prefabName, GameObjectRequestCallback callback, GameObject go, object userData)
		{
			try
			{
				callback?.Invoke(go, userData);
			}
			catch (Exception e)
			{
				NLogger.ErrorChannel("GameObjectPool", $"SafeCall: Pool = {_name}, Prefab = {prefabName}, Exception = {e}");
			}
		}

		private void SafeCall(string prefabName, Action<GameObject> callback, GameObject go)
		{
			try
			{
				callback?.Invoke(go);
			}
			catch (Exception e)
			{
				NLogger.ErrorChannel("GameObjectPool", $"SafeCall: Pool = {_name}, Prefab = {prefabName}, Exception = {e}");
			}
		}

		private void SafeCall(string prefabName, Action callback)
		{
			try
			{
				callback?.Invoke();
			}
			catch (Exception e)
			{
				NLogger.ErrorChannel("GameObjectPool", $"SafeCall: Pool = {_name}, Prefab = {prefabName}, Exception = {e}");
			}
		}

		private void OnDelete(string name, GameObjectCache cacheInfo)
		{
#if DEBUG_GAME_OBJECT_POOL_LRU
			NLogger.ErrorChannel("GameObjectPool", $"OnDelete: Pool = {_name}, Prefab = {name}");
#endif
			
			cacheInfo.ClearStack();
			cacheInfo.Decrease();
		}

		public void OnLowMemory()
		{
			_cacheDict.Clear();
		}

		public void UpdateCachedGameObjectLimit()
		{
			foreach (var pair in _cacheDict)
			{
				pair.Value.UpdateCachedGameObjectLimit();
			}
		}
	}
}
