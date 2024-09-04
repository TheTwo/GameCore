using UnityEngine;

namespace DragonReborn.AssetTool
{
    /// <summary>
    /// 每个Handle对应一个GameObject实例
    /// </summary>
    public class PooledGameObjectHandle
    {
        private static readonly GameObjectRequestCallback Callback = OnLoad;

        private GameObjectRequest _request;
        private GameObjectCache _cache;
        private PooledGameObjectRequestCallback _action;
        private object _userData;

#if UNITY_EDITOR
        private static long _globalDebugGuid;
        private long _debugGuid;
#endif

        public PooledGameObjectHandle(string pool)
        {
            Pool = pool;
            
#if UNITY_EDITOR
            _debugGuid = ++_globalDebugGuid;
#endif
        }
        
        public string PrefabName { get; private set; }
        public GameObject Asset { get; private set; }
        public string Pool { get; }
        public bool Idle => Asset == null && _request == null;
        public bool Loaded => Asset != null;

        public void Create(string prefabName, Transform parent, PooledGameObjectRequestCallback action,
	        object userData = null, int priority = 0, bool syncCreate = false, bool syncLoad = false)
        {
	        Create(prefabName, parent, Vector3.zero, Quaternion.identity, Vector3.one,
		        action, userData, priority, syncCreate, syncLoad);
        }

        public void Create(string prefabName, Transform parent, Vector3 pos, Quaternion rot, Vector3 scale,
	        PooledGameObjectRequestCallback action, object userData = null, int priority = 0, bool syncCreate = false,
	        bool syncLoad = false)
        {
	        var samePath = PrefabName == prefabName;
	        PrefabName = prefabName;
	        _action = action;
	        _userData = userData;

	        var pool = GameObjectPoolManager.Instance.GetPool(Pool);

	        if (Idle && !samePath)
	        {
		        pool.Create(prefabName, parent, pos, rot, scale, out _request, Callback, this, priority, syncCreate, syncLoad);
	        }
	        else
	        {
		        if (!Idle)
		        {
			        Log("PooledGameObjectHandle:Create没有创建，因为Idle==false");
		        }
		        else if (samePath)
		        {
			        Log("PooledGameObjectHandle:Create没有创建，因为已经持有的相同的资源");
		        }
	        }
        }

        public void Delete(float t = 0)
        {
            if (Asset != null)
            {
                if (GameObjectPoolManager.Instance.TryGetPool(Pool, out var pool))
                {
                    pool.Destroy(_cache, Asset, t);
                }
                else
                {
	                Log("get pool for {0} fail, may caused by 'pool was removed when OnGameDestroy'", Pool);
#if UNITY_EDITOR
					if (Application.isPlaying)
					{
						Object.Destroy(Asset);
					}
					else
					{
						Object.DestroyImmediate(Asset);
					}
#else
					Object.Destroy(Asset);
#endif
				}
            }

            if (_request != null)
            {
                _request.Cancel = true;
                _request.Callback = null;
                _request = null;
            }

            PrefabName = null;
            Asset = null;
            _action = null;
            _userData = null;
            _cache?.Decrease();
            _cache = null;
        }

        private static void OnLoad(GameObject go, object data)
        {
            if (data is not PooledGameObjectHandle handle)
            {
                return;
            }

            var action = handle._action;
            var userData = handle._userData;

            handle._cache = handle._request.Cache;
            handle._cache?.Increase();
            
            handle._request = null;
            handle._action = null;
            handle._userData = null;

            handle.Asset = go;

            action?.Invoke(go, userData, handle);
        }
        
        private static void Log(string msg, params object[] args)
        {
	        NLogger.WarnChannel("PooledGameObjectHandle", msg, args);
        }
    }
}
