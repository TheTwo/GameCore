using System;
using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn.AssetTool
{
	public class PooledGameObjectCreateHelper
	{
		private static readonly Dictionary<string, PooledGameObjectCreateHelper> AllCreateHelpers = new();

		public static PooledGameObjectCreateHelper Create(string pool)
		{
			AllCreateHelpers.TryGetValue(pool, out var helper);
			if (helper == null)
			{
				helper = new PooledGameObjectCreateHelper(pool);
				AllCreateHelpers.Add(pool, helper);
			}

			return helper;
		}

		public static void Clear()
		{
			foreach (var (_, helper) in AllCreateHelpers)
			{
				helper.DeleteAll();
				helper._markedNotTraced = true;
			}

			AllCreateHelpers.Clear();
		}

		private PooledGameObjectCreateHelper(string pool)
		{
			_allHandlers = new HashSet<PooledGameObjectHandle>();
			_pool = pool;
		}

		private readonly HashSet<PooledGameObjectHandle> _allHandlers;
		private readonly string _pool;
		private bool _markedNotTraced;
		public bool MarkedNotTraced => _markedNotTraced;

		/// <summary>
		/// 预加载prefab
		/// </summary>
		/// <param name="prefabName">资源名</param>
		/// <param name="count">个数</param>
		/// <param name="warmUpSingle">warmUp单个回调</param>
		/// <param name="warmUpDone">warmUp结束回调</param>
		/// <param name="warmUpInstTickCount">每一帧创建的个数</param>
		public void WarmUp(string prefabName, int count, Action<GameObject> warmUpSingle = null,
			Action warmUpDone = null, int warmUpInstTickCount = 1)
		{
			var pool = GameObjectPoolManager.Instance.GetPool(_pool);
			pool.WarmUp(prefabName, count, warmUpSingle, warmUpDone, warmUpInstTickCount);
		}

		/// <summary>
		/// 每次调用会返回一个新的PooledGameObjectHandle
		/// </summary>
		/// <param name="prefabName">资源名，无后缀</param>
		/// <param name="parent">挂载父节点</param>
		/// <param name="action">创建回调</param>
		/// <param name="userData">userData</param>
		/// <param name="priority">优先级</param>
		/// <param name="syncCreate">同步创建（尽量，不保证一定，比如依赖的ab需要下载的情况会转为异步）</param>
		/// <param name="syncLoad">同步加载预设</param>
		/// <returns></returns>
		public PooledGameObjectHandle Create(string prefabName, Transform parent,
			PooledGameObjectRequestCallback action, object userData = null, int priority = 0, bool syncCreate = false, bool syncLoad = false)
		{
			var handle = new PooledGameObjectHandle(_pool);
			handle.Create(prefabName, parent, action, userData, priority, syncCreate, syncLoad);
			_allHandlers.Add(handle);
			return handle;
		}

		/// <summary>
		/// 清理动作（单个）
		/// 如果申请中，取消创建
		/// 如果已创建，则还到Pool
		/// </summary>
		/// <param name="handle"></param>
		/// <param name="delay">延迟</param>
		public void Delete(PooledGameObjectHandle handle, float delay = 0f)
		{
			handle.Delete(delay);
			_allHandlers.Remove(handle);
		}

		/// <summary>
		/// 清理动作（全部）
		/// </summary>
		public void DeleteAll()
		{
			foreach (var handle in _allHandlers)
			{
				handle.Delete();
			}

			_allHandlers.Clear();
		}
	}
}
