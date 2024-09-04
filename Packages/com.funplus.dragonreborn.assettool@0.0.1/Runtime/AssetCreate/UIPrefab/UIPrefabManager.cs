#define USING_GAMEOBJECTMANAGER
using System;
using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
	public class UIPrefabManager : Singleton<UIPrefabManager>, IManager
	{
		private class UIPrefabCreateQueryWrap
		{
			// ReSharper disable InconsistentNaming
			public int runtimeId;
			public Transform parent;
			public Action<bool,GameObject> callback;
			// ReSharper restore InconsistentNaming
		}		

		// ReSharper disable once InconsistentNaming
		private const string LOG_CHANNEL = "UIPrefabManager";
#if USING_GAMEOBJECTMANAGER
		private Dictionary<int, UIPrefabCreateQueryWrap> _allCreateQuearies;
		private GameObjectCreateHelper _uiPrefabObjectCreateHelper;
#else
		private FrequencyCache<AssetHandle> _zeroRefLRU;
		private Dictionary<string,AssetHandle> _allLoadingHandles;
		private Dictionary<string, List<UIPrefabCreateQueryWrap>> _allCreateQuearies;
		private readonly HashSet<ulong> _waitInstantiateHandler = new();
		private ulong _instantiateIndex;
#endif
		
		
		public void OnGameInitialize(object configParam)
		{
#if USING_GAMEOBJECTMANAGER
			_uiPrefabObjectCreateHelper = GameObjectCreateHelper.Create();
			_allCreateQuearies = new Dictionary<int, UIPrefabCreateQueryWrap>();
#else
			_zeroRefLRU = new FrequencyCache<AssetHandle>(0, OnLRUDeleteCallback);
			_allLoadingHandles = new();
			_allCreateQuearies = new();
#endif
		}

		public void SetCacheSize(int size)
		{
#if !USING_GAMEOBJECTMANAGER
			_zeroRefLRU.CacheSize = size;
#endif
		}

		public void Clear()
		{
#if !USING_GAMEOBJECTMANAGER
			_zeroRefLRU.Clear();
#endif
		}

		public void Reset()
		{
			// 资源清理
			Clear();
			CancelAll(false);
		}
		
#if USING_GAMEOBJECTMANAGER
		public void CancelAll(bool invokeCallback = true)
		{
			_uiPrefabObjectCreateHelper.CancelAllCreate();
			if (invokeCallback)
			{
				using (UnityEngine.Pool.ListPool<UIPrefabCreateQueryWrap>.Get(out var list))
				{
					list.AddRange(_allCreateQuearies.Values);
					foreach (var wrap in list)
					{
						wrap.callback?.Invoke(false, null);
					}
				}
				_allCreateQuearies.Clear();
			}
		}
#else
		public void CancelAll(bool invokeCallback = true)
		{
			// 销毁正在请求加载中的资源
			foreach (var pair in _allLoadingHandles)
			{
				var handle = pair.Value;
				if(handle != null)
					AssetManager.Instance.UnloadAsset(handle);
				if( _allCreateQuearies.TryGetValue(pair.Key,out var quearyList))
				{
					if (invokeCallback && quearyList != null && quearyList.Count > 0)
					{
						foreach (var queary in quearyList)
						{
							queary.callback?.Invoke(false,null);
						}
					}
					_allCreateQuearies.Remove(pair.Key);
				}
			}
			_allLoadingHandles.Clear();
			_waitInstantiateHandler.Clear();
		}

		private void OnLRUDeleteCallback(string name, AssetHandle handle)
		{
			// 开始卸载			
			AssetManager.Instance.UnloadAsset(handle);
		}
#endif
		
#if USING_GAMEOBJECTMANAGER
		private void LoadUIPrefab(string name, Transform parent, int runTimeId)
		{
			_uiPrefabObjectCreateHelper.Create(name, parent, o =>
			{
				var success = o != null;
				if (!_allCreateQuearies.Remove(runTimeId, out var wrap))
				{
					if (success)
						UnityEngine.Object.Destroy(o);
					return;
				}
				var call = wrap.callback;
				wrap.callback = null;
				call?.Invoke(success, o);
			}, 999, true);
		}
#else
		void LoadUIPrefab(string name, Action<bool,string,AssetHandle> callback)
		{
			if (string.IsNullOrEmpty(name))
			{
				NLogger.ErrorChannel(LOG_CHANNEL, "LoadUIPrefab时，name不能为空");
				return;
			}

			if (_allLoadingHandles.ContainsKey(name))
			{
				// 正在加载中
				return;
			}
			
			if (_zeroRefLRU.TryGet(name, out var handle))
			{
				// 已经加载过了，直接返回
				callback?.Invoke(true, name,handle);
				return;
			}

			// 没有加载过，开始加载
			if (AssetManager.Instance.CanLoadSync(name))
			{
				SyncLoad(name, callback);
			}
			else
			{
				AsyncLoad(name, callback);
			}
		}

		private void SyncLoad(string name, Action<bool, string,AssetHandle> callback)
		{
			AssetHandle handle = AssetManager.Instance.LoadAsset(name, false, AssetManager.SyncLoadReason.OptimizeForAsyncLoad);
			if (handle.Asset == null)
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"同步加载UIPrefab失败，name={name}");
				callback?.Invoke(false, name,handle);
				return;
			}

			GameObject go = handle.Asset as GameObject;
			if (go == null)
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"同步加载UIPrefab失败，name={name}，Asset不是GameObject");
				callback?.Invoke(false, null,handle);
				return;
			}
			callback?.Invoke(true, name,handle);
		}

		private void AsyncLoad(string name, Action<bool, string,AssetHandle> callback)
		{	
			//先占位，防止已经缓存的资源同步回调时逻辑不正确
			_allLoadingHandles.Add(name,null);			
			var handle = AssetManager.Instance.LoadAssetAsync(name, (result, handle) =>
			{
				//如果_allLoadingHandles中没有key，说明被中断，不需要处理
				if(_allLoadingHandles.ContainsKey(name)){
					_allLoadingHandles.Remove(name);
					callback?.Invoke(result, name,handle);
				}
			},false,999);
			//如果是已经缓存的资源，会回同步回调，导致从_allLoadingHandles移除key
			//所以这里需要再检查一次
			if (_allLoadingHandles.ContainsKey(name))
			{
				_allLoadingHandles[name] = handle;
			}
		}
		
		private void ProcessCreateFaild(string name)
		{
			if(_allCreateQuearies.TryGetValue(name,out var queryList))
			{
				foreach (var query in queryList)
				{
					if(query != null && query.callback != null)
						query.callback(false, null);
				}
				_allCreateQuearies.Remove(name);
			}
		}

		private void OnUIPrefabLoaded(bool succeed, string name,AssetHandle handle)
		{
			if(!succeed)
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"加载UIPrefab失败，name={name}");
				ProcessCreateFaild(name);
				return;
			}


			if(handle.Asset == null )
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"加载UIPrefab成功，但是handle.Asset为空，不符合预期");
				ProcessCreateFaild(name);
				return;
			}	

			GameObject prefabGo = handle.Asset as GameObject;
			if(prefabGo == null)
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"加载UIPrefab成功，但是handle.Asset不是GameObject，不符合预期");
				ProcessCreateFaild(name);
				return;
			}
			
			// 加载成功，加入到缓存中
			_zeroRefLRU.Add(handle.AssetName, handle);		

			if (!_allCreateQuearies.TryGetValue(name, out var queryList))
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"加载UIPrefab成功，但是_allCreateQuearies没有找到{name}，不符合预期");
				return;
			}
			_allCreateQuearies.Remove(name);
			if(queryList == null || queryList.Count == 0)
			{
				return;
			}
			for (int i = 0; i < queryList.Count; i++)
			{
				if(queryList[i].parent == null) continue;
				var idx = unchecked(_instantiateIndex++);
				_waitInstantiateHandler.Add(idx);
				var query = queryList[i];
				ObjectInstantiateManager.Instance.Instantiate(prefabGo, handle.AssetName, query.parent, 
					(goInstance) =>
					{
						if (!_waitInstantiateHandler.Remove(idx))
						{
							//说明UI系统重启了，这个时候不需要UI生命周期的处理
	#if UNITY_EDITOR
							if (Application.isPlaying)
							{
								if (goInstance)
								{
									UnityEngine.Object.Destroy(goInstance);
								}
							}
							else
							{
								if (goInstance)
								{
									UnityEngine.Object.DestroyImmediate(goInstance);
								}
							}
#else
							if (goInstance)
							{
								UnityEngine.Object.Destroy(goInstance);
							}
#endif
							return;
						}

						if (goInstance)
						{
							goInstance.name = prefabGo.name;
						}
						else
						{
							NLogger.Error($"assetHandle.asset.Instantiate failed: {handle.AssetName}");
						}
						if(query.parent != null && query.callback != null)
						{
							query.callback(true,goInstance);
						}
						else
						{
							UnityEngine.Object.Destroy(goInstance);
						}
					}
				);
			}
			
		}
#endif

		public void CreateUI(int runtimeId,string name, Transform parent, Action<bool, GameObject> callback)
		{
			if (string.IsNullOrEmpty(name))
			{
				NLogger.ErrorChannel(LOG_CHANNEL, "CreateUI时，name不能为空");
				if(callback != null)
				{
					callback(false,null);
				}
				return;
			}

#if USING_GAMEOBJECTMANAGER
			if (!_allCreateQuearies.TryGetValue(runtimeId, out var wrap))
			{
				wrap = new UIPrefabCreateQueryWrap()
				{
					runtimeId = runtimeId,
					parent = parent,
					callback = callback
				};
				_allCreateQuearies.Add(runtimeId, wrap);
			}
			else
			{
				wrap.parent = parent;
				wrap.callback = callback;
			}
			LoadUIPrefab(name, parent, runtimeId);
#else
			var queryInfo = new UIPrefabCreateQueryWrap()
			{
				runtimeId = runtimeId,
				parent = parent,
				callback = callback
			};

			if(!_allCreateQuearies.TryGetValue(name,out var queryList))
			{
				queryList = new List<UIPrefabCreateQueryWrap>();
				_allCreateQuearies.Add(name, queryList);
			}
			queryList.Add(queryInfo);
			
			LoadUIPrefab(name, OnUIPrefabLoaded);
#endif
		}

		
		public void ShutdownCreateUI(int runtimeId, string name)
		{
#if USING_GAMEOBJECTMANAGER
			if (!_allCreateQuearies.Remove(runtimeId, out var wrap))
			{
				return;
			}
			wrap.parent = null;
			wrap.callback = null;
#else
			if(!_allCreateQuearies.TryGetValue(name,out var queryList))
			{
				return;
			}
			for (int i = 0; i < queryList.Count; i++)
			{
				if (queryList[i].runtimeId == runtimeId)
				{
					queryList.RemoveAt(i);
					break;
				}
			}
#endif
		}

		public void OnLowMemory()
		{

		}
	}
}
