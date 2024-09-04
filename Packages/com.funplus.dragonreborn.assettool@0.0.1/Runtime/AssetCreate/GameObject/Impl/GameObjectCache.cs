using System;
using System.Collections.Generic;
using UnityEngine;
using Object = UnityEngine.Object;

#if UNITY_DEBUG
using UnityEngine.Profiling;
#endif

namespace DragonReborn.AssetTool
{
    public enum GameObjectCacheState
    {
        NotReady = 0,
        Loading = 1,
        Ready = 2,
        Failure = 3,
        Dead = 4,
    }
    
    internal class GameObjectCache
    {
	    public AssetHandle Handle;
        public string PrefabName;
        public GameObject Prefab;
        public GameObjectCacheState State = GameObjectCacheState.NotReady;
        public int WarmUpCount;
        public int WarmUpCountPerTick;
        public Action<GameObject> WarmUpSingle;
        public Action WarmUpDone;
        public int RefCount;

        private Transform _root;
        private readonly Stack<GameObject> _stack = new();

        private bool HasCachedGameObject => CachedGameObjectCount > 0;
        private int CachedGameObjectCount => _stack.Count;
        public bool Corrupted => State == GameObjectCacheState.Ready && Prefab == null;

        public void Increase()
        {
	        ++RefCount;
	        
#if DEBUG_GAME_OBJECT_POOL_LRU
	        NLogger.ErrorChannel("GameObjectCache", $"Increase: Prefab = {PrefabName}, Ref = {RefCount}");
#endif
        }

        public void Decrease()
        {
	        if (RefCount <= 0)
	        {
		        NLogger.ErrorChannel("GameObjectCache", $"Redundant Decrease: Prefab = {PrefabName}, Ref = {RefCount}");
		        return;
	        }

	        --RefCount;
#if DEBUG_GAME_OBJECT_POOL_LRU
	        NLogger.ErrorChannel("GameObjectCache", $"Decrease: Prefab = {PrefabName}, Ref = {RefCount}");
#endif
	        
	        if (RefCount > 0)
	        {
		        return;
	        }

#if DEBUG_GAME_OBJECT_POOL_LRU
	        NLogger.ErrorChannel("GameObjectCache", $"Unload: Prefab = {PrefabName}");
#endif
	        
	        ++GameObjectPoolManager.Instance.AccumulatedUnusedCacheCount;
	        
	        Clear();
        }
        
        public void Initialize(AssetHandle handle, Transform root)
        {
            Prefab = handle.Asset as GameObject;
            Handle = handle;
            _root = root;
        }

        public GameObject Allocate()
        {
            if (!Prefab)
            {
                NLogger.ErrorChannel("GameObjectCache", $"Allocate: Corrupted prefab: {PrefabName}");
                return null;
            }

            GameObject go = null;

            while (HasCachedGameObject)
            {
                go = _stack.Pop();
                if (!go)
                {
                    NLogger.ErrorChannel("GameObjectCache", $"Allocate: Game object was externally deleted: {PrefabName}");
                }
                else
                {
                    break;
                }
            }

            if (!go)
            {
                go = Instantiate();
            }

            go.SetActive (true);

            return go;
        }

        public GameObject Instantiate()
        {
	        if (!Prefab)
	        {
		        return null;
	        }

#if UNITY_DEBUG
	        Profiler.BeginSample($"[GameObjectCache] Instantiate: Prefab = {PrefabName}");
#endif
	        
	        var go = UnityEngine.Object.Instantiate(Prefab);

#if UNITY_DEBUG
	        Profiler.EndSample();
#endif

	        go.name = PrefabName;

	        return go;
        }

        public void Recycle(GameObject go)
        {
            if (!go)
            {
                return;
            }
            
            go.SetActive(false);

            if (_root && State == GameObjectCacheState.Ready && _stack.Count < GameObjectPoolManager.Instance.CachedGameObjectLimit)
            {
                go.transform.SetParent(_root);
                _stack.Push(go);
            }
            else
            {
	            DestroyGameObject(go);
            }
        }

        private void Clear()
        {
	        ClearStack();

	        AssetManager.Instance.UnloadAsset(Handle);
	        Handle = null;
	        _root = null;
	        
	        PrefabName = string.Empty;
	        Prefab = null;
	        State = GameObjectCacheState.Dead;
	        WarmUpCount = 0;
	        WarmUpCountPerTick = 0;
	        WarmUpSingle = null;
	        WarmUpDone = null;
        }

        public void ClearStack()
        {
	        while (_stack.Count > 0)
	        {
		        var go = _stack.Pop();
		        if (go)
		        {
			        DestroyGameObject(go);
		        }
	        }
        }

        private static void DestroyGameObject(Object go)
        {
#if UNITY_EDITOR
	        if (Application.isPlaying)
	        {
		        Object.Destroy(go);
	        }
	        else
	        {
		        Object.DestroyImmediate(go);
	        }
#else
			Object.Destroy(go);
#endif
        }

        public void UpdateCachedGameObjectLimit()
        {
	        while (_stack.Count > GameObjectPoolManager.Instance.CachedGameObjectLimit)
	        {
		        var go = _stack.Pop();
		        if (go)
		        {
			        DestroyGameObject(go);
		        }
	        }
        }
    }
}
