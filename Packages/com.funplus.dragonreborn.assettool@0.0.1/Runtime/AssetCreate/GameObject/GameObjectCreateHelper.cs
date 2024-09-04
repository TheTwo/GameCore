using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    /// <summary>
    /// 提供GameObject加载功能（非池，池子用PoolGameObjectCreateHelper）
    /// </summary>
    public class GameObjectCreateHelper
    {
        private static readonly HashSet<WeakReference<GameObjectCreateHelper>> AllCreateHelpers = new();
        
        public static GameObjectCreateHelper Create()
        {
            var helper = new GameObjectCreateHelper();
            AllCreateHelpers.Add(new WeakReference<GameObjectCreateHelper>(helper));
            return helper;
        }
        
        private readonly HashSet<AssetHandle> _allLoadingHandler = new();
        private readonly HashSet<ulong> _waitInstantiateHandler = new();
        private ulong _instantiateIndex;

        private GameObjectCreateHelper()
        { }

        public static void Clear()
        {
            GameObjectManager.Instance.Clear();
            foreach (var weak in AllCreateHelpers)
            {
                if (weak.TryGetTarget(out var helper))
                {
                    helper.CancelAllCreate();
                }
            }
            AllCreateHelpers.Clear();
        }
        
        public void CancelAllCreate()
        {
	        _waitInstantiateHandler.Clear();
            foreach (var assetHandle in _allLoadingHandler)
            {
                AssetManager.Instance.UnloadAsset(assetHandle);
            }
            _allLoadingHandler.Clear();
        }

        //警告：此函数可能会导致卡顿，请尽量使用Create创建实例
        public void CreateAsap(string prefabName, Transform parent, Action<GameObject> callback, int priority = 0)
        {
	        AssetManager.Instance.LoadAssetSmart(prefabName, true, (ret, handle) =>
	        {
		        if (!ret || !handle.Asset)
		        {
			        AssetManager.Instance.UnloadAsset(handle);
			        callback?.Invoke(null);
			        return;
		        }

#if UNITY_EDITOR
		        Profiler.BeginSample($"[GameObjectCreateHelper]CreateAsap: Prefab = {prefabName}");
#endif
		        
		        var go = UnityEngine.Object.Instantiate(handle.Asset as GameObject, parent);
		        
#if UNITY_EDITOR
		        Profiler.EndSample();
#endif
		        
		        go.name = handle.Asset.name;

		        GameObjectManager.Instance.AddCreatedGameObject(handle, go);
		        callback?.Invoke(go);
	        }, priority);
        }

        /// <param name="prefabName">资源名，无后缀</param>
		/// <param name="parent">挂载父节点</param>
		/// <param name="callback">创建回调</param>
		/// <param name="priority">优先级</param>
		/// <param name="syncCreate">同步创建（尽量，不保证一定，比如依赖的ab需要下载的情况会转为异步）</param>
		/// <returns></returns>
		public void Create(string prefabName, Transform parent, Action<GameObject> callback, int priority = 0, bool syncCreate = false)
        {
			if (AssetManager.Instance.CanLoadSync(prefabName) && syncCreate)
			{
				SyncCreate(prefabName, parent, callback);
			}
			else
			{
				AsyncCreate(prefabName, parent, callback, priority);
			}
        }

		private void SyncCreate(string prefabName, Transform parent, Action<GameObject> callback)
		{
			var handle = AssetManager.Instance.LoadAsset(prefabName, false, AssetManager.SyncLoadReason.OptimizeForAsyncLoad);
			var idx = unchecked(_instantiateIndex++);
			_waitInstantiateHandler.Add(idx);
			ObjectInstantiateManager.Instance.Instantiate(handle.Asset as GameObject, handle.AssetName, parent, newObject =>
			{
				if (!_waitInstantiateHandler.Remove(idx))
				{
#if UNITY_EDITOR
					if (Application.isPlaying)
					{
						DestroyGameObject(newObject);
					}
					else
					{
						DestroyGameObjectImmediate(newObject);
					}
#else
				    DestroyGameObject(newObject);
#endif
					return;
				}

				if (newObject)
				{
					newObject.name = handle.Asset.name;
				}
				else
				{
					NLogger.Error($"assetHandle.asset.Instantiate failed: {handle.AssetName}");
				}

				// 加载成功，管理AssetHandle
				GameObjectManager.Instance.AddCreatedGameObject(handle, newObject);
				callback?.Invoke(newObject);
			});
		}

		private void AsyncCreate(string prefabName, Transform parent, Action<GameObject> callback, int priority = 0)
		{
			var handle = AssetManager.Instance.LoadAssetAsync(prefabName, (b, assetHandle) =>
			{
				_allLoadingHandler.Remove(assetHandle);
				if (b && assetHandle.Asset is GameObject)
				{
					var idx = unchecked(_instantiateIndex++);
					_waitInstantiateHandler.Add(idx);
					ObjectInstantiateManager.Instance.Instantiate(assetHandle.Asset as GameObject, assetHandle.AssetName, parent, newObject =>
					{
						if (!_waitInstantiateHandler.Remove(idx))
						{
#if UNITY_EDITOR
							if (Application.isPlaying)
							{
								DestroyGameObject(newObject);
							}
							else
							{
								DestroyGameObjectImmediate(newObject);
							}
#else
				            DestroyGameObject(newObject);
#endif
							return;
						}
						if (newObject)
						{
							newObject.name = assetHandle.Asset.name;
						}
						else
						{
							NLogger.Error($"assetHandle.asset.Instantiate failed: {assetHandle.AssetName}");
						}
						// 加载成功，管理AssetHandle
						GameObjectManager.Instance.AddCreatedGameObject(assetHandle, newObject);
						callback?.Invoke(newObject);
					});
				}
				else
				{
					// 加载失败，卸载AssetHandle
					AssetManager.Instance.UnloadAsset(assetHandle);
					callback?.Invoke(null);
				}
			}, false, priority);

			// 拿到了AssetHandle，但是资源还在请求中
			if (!handle.IsValid)
			{
				_allLoadingHandler.Add(handle);
			}
		}

        public static void DestroyGameObject(GameObject go)
        {
			if (go)
			{
				UnityEngine.Object.Destroy(go);
			}
        }

		public static void DestroyGameObjectImmediate(GameObject go)
		{
			if (go)
			{
				UnityEngine.Object.DestroyImmediate(go);
			}
		}
    }
}
