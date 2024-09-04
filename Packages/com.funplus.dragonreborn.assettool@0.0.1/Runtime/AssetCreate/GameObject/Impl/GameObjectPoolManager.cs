using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn.AssetTool
{
	/// <summary>
	/// 管理对象池
	/// </summary>
	public class GameObjectPoolManager : Singleton<GameObjectPoolManager>, IManager, ITimeScaleIgnoredTicker
	{
		private GameObject _rootNode;
		private readonly Dictionary<string, GameObjectPool> _pools = new();
		private readonly List<GameObjectPool> _ticking = new();
		private int _cachedGameObjectLimit = 20;
		private int _defaultPoolCacheSize = 50;

		internal int AccumulatedUnusedCacheCount;

		public int UnusedCacheLimit { get; set; } = 20;

		public int CachedGameObjectLimit
		{
			get => _cachedGameObjectLimit;

			set
			{
				if (_cachedGameObjectLimit != value)
				{
					_cachedGameObjectLimit = value;

					foreach (var pair in _pools)
					{
						pair.Value.UpdateCachedGameObjectLimit();
					}
				}
			}
		}

		public int DefaultPoolCacheSize
		{
			get => _defaultPoolCacheSize;
			set => _defaultPoolCacheSize = Mathf.Max(value, 1);
		}

		public void OnGameInitialize(object configParam)
		{
			if (Application.isPlaying)
			{
				_rootNode = new GameObject("GameObjectPoolManager");
				Object.DontDestroyOnLoad(_rootNode);
			}
			else
			{
				_rootNode = GameObject.Find("GameObjectPoolManager");
				if (!_rootNode)
				{
					_rootNode = new GameObject("GameObjectPoolManager");
				}
			}
		}
		
		public void Reset()
		{
			foreach (var pair in _pools)
			{
				pair.Value.ClearCache();
			}
			
			_pools.Clear();

			AccumulatedUnusedCacheCount = 0;

			Object.DestroyImmediate(_rootNode);
		}

		internal GameObjectPool GetPool(string usage)
		{
			_pools.TryGetValue(usage, out var pool);
			if (pool != null)
			{
				return pool;
			}
			
			pool = new GameObjectPool(usage, DefaultPoolCacheSize, _rootNode.transform);
			_pools.Add(usage, pool);

			return pool;
		}

		public void Clear(string usage)
		{
			TryGetPool(usage, out var pool);
			pool?.ClearCache();
		}

		internal bool TryGetPool(string usage, out GameObjectPool pool)
		{
			return _pools.TryGetValue(usage, out pool);
		}

		public void SetCacheSizesOfAllPools(int cacheSize)
		{
			foreach (var pair in _pools)
			{
				pair.Value.CacheSize = cacheSize;
			}
		}

		public bool SetPoolCacheSize(string usage, int cacheSize)
		{
			if (!TryGetPool(usage, out var pool))
			{
				return false;
			}
			
			pool.CacheSize = cacheSize;
			return true;
		}

		public bool GetPoolCacheSize(string usage, out int cacheSize)
		{
			if (TryGetPool(usage, out var pool))
			{
				cacheSize = pool.CacheSize;
				return true;
			}

			cacheSize = default;
			return false;
		}

		public bool SetPoolProcessMsPerFrame(string usage, long processMsPerFrame)
		{
			if (!TryGetPool(usage, out var pool))
			{
				return false;
			}
			
			pool.ProcessMsPerFrame = processMsPerFrame;
			return true;
		}
		
		public bool GetPoolProcessMsPerFrame(string usage, out long processMsPerFrame)
		{
			if (TryGetPool(usage, out var pool))
			{
				processMsPerFrame = pool.ProcessMsPerFrame;
				return true;
			}

			processMsPerFrame = default;
			return false;
		}

		public void Tick(float delta)
		{
			_ticking.AddRange(_pools.Values);
			
			foreach (var pool in _ticking)
			{
				//池子的请求回调可能会修改池子列表
				pool.Tick(delta);
			}
			
			_ticking.Clear();
			
			ProcessUnloadUnusedAssets();
		}
		
		private void ProcessUnloadUnusedAssets()
		{
			if (AccumulatedUnusedCacheCount < UnusedCacheLimit)
			{
				return;
			}
			
#if DEBUG_GAME_OBJECT_POOL_LRU
			NLogger.ErrorChannel("GameObjectPoolManager", "ProcessUnloadUnusedAssets");
#endif

			AssetManager.Instance.UnloadUnused();
			AccumulatedUnusedCacheCount = 0;
		}

		public void OnLowMemory()
		{
			foreach (var pair in _pools)
			{
				pair.Value.OnLowMemory();
			}
		}
	}
}
