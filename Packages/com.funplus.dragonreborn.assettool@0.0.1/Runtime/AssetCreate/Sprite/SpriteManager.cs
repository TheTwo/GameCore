using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.UI;

namespace DragonReborn.AssetTool
{
	public class SpriteManager : Singleton<SpriteManager>, IManager
	{
		private const string LOG_CHANNEL = "SpriteManager";
		private const string DEFAULT_SPRITE_NAME = "sp_icon_missing_2";
		private Dictionary<string, AssetHandle> _allLoadedSpriteHandles;
		private Dictionary<string, int> _allLoadedSpriteCount;
		private HashSet<AssetHandle> _allLoadingHandler;
		private AssetHandle _defaultSpriteHandle;
		private HashSet<SpriteWrapper> _allWaitCallbackWrappers;

		private FrequencyCache<AssetHandle> _zeroRefLRU;

		public enum RendererType
		{
			Image,
			SpriteRenderer,
			U2DSpriteMesh
		}

		/// <summary>
		/// 游戏启动
		/// </summary>
		/// <param name="configParam"></param>
		public void OnGameInitialize(object configParam)
		{
			_zeroRefLRU = new FrequencyCache<AssetHandle>(0, OnLRUDeleteCallback);
			_allLoadedSpriteHandles = new Dictionary<string, AssetHandle>();
			_allLoadedSpriteCount = new Dictionary<string, int>();
			_allLoadingHandler = new HashSet<AssetHandle>();
			_allWaitCallbackWrappers = new HashSet<SpriteWrapper>();
		}

		public void SetLRUSize(int size)
		{
			_zeroRefLRU.CacheSize = size;
		}

		/// <summary>
		/// 游戏重启
		/// </summary>
		public void Reset()
		{
			// 资源清理
			_zeroRefLRU.Clear();
			foreach (var pair in _allLoadedSpriteHandles)
			{
				AssetManager.Instance.UnloadAsset(pair.Value);
			}
			_allLoadedSpriteHandles.Clear();

			// 引用计数清理
			_allLoadedSpriteCount.Clear();

			// 销毁正在请求加载中的资源
			foreach (var handle in _allLoadingHandler)
			{
				AssetManager.Instance.UnloadAsset(handle);
			}
			_allLoadingHandler.Clear();
			
#if UNITY_EDITOR
			_isEditorWithLogicFolder = null;
#endif
		}

		public void CancelAll()
		{
			foreach (var assetHandle in _allLoadingHandler)
			{
				AssetManager.Instance.UnloadAsset(assetHandle);
			}
			_allLoadingHandler.Clear();
		}

		private Sprite DefaultSprite
		{
			get
			{
				if (_defaultSpriteHandle != null && _defaultSpriteHandle.IsValid)
				{
					return _defaultSpriteHandle.Asset as Sprite;
				}

				// TODO 同步加载
				_defaultSpriteHandle = AssetManager.Instance.LoadAsset(DEFAULT_SPRITE_NAME, true);
				return _defaultSpriteHandle.Asset as Sprite;
			}
		}

		private void UnloadSpriteIfNotUsed(string spriteName)
		{
			// 没有引用记录
			if (!_allLoadedSpriteCount.ContainsKey(spriteName) && _allLoadedSpriteHandles.TryGetValue(spriteName, out var handle))
			{
				AssetManager.Instance.UnloadAsset(handle);
				_allLoadedSpriteHandles.Remove(spriteName);
			}
		}

		/// <summary>
		/// 引用计数自管理
		/// </summary>
		/// <param name="spriteName"></param>
		/// <param name="host"></param>
		private void IncreaseSpriteReference(string spriteName, GameObject host)
		{
			if (_allLoadedSpriteCount.ContainsKey(spriteName))
			{
				if (_allLoadedSpriteCount[spriteName] == 0 && _zeroRefLRU.Contains(spriteName))
				{
					// 从LRU中移除，不触发OnDelete
					_zeroRefLRU.Remove(spriteName, false);
				}

				_allLoadedSpriteCount[spriteName]++;
			}
			else
			{
				_allLoadedSpriteCount[spriteName] = 1;
			}

			var spriteRef = GetSpriteReference(host);
			spriteRef.SetOnDestroyCallback(DecreaseSpriteReference);
			spriteRef.SetSpriteName(spriteName);  // 可能触发_allLoadedSpriteHandles unload
		}

		private void DecreaseSpriteReference(string spriteName)
		{
			if (spriteName == DEFAULT_SPRITE_NAME)
			{
				return;
			}

			// 没有引用记录
			if (!_allLoadedSpriteCount.ContainsKey(spriteName))
			{
				// NLogger.Error($"DecreaseSpriteReference {spriteName}，但是没有引用记录");
				return;
			}

			// 有引用记录
			_allLoadedSpriteCount[spriteName]--;
			if (_allLoadedSpriteCount[spriteName] <= 0)
			{
				if (_allLoadedSpriteHandles.TryGetValue(spriteName, out var handle))
				{
					if (_zeroRefLRU.CacheSize > 0)
					{
						AddToZeroRefLRU(spriteName, handle);		
					}
					else
					{
						OnLRUDeleteCallback(spriteName, handle);
					}
				}
				else
				{
					NLogger.ErrorChannel(LOG_CHANNEL, $"DecreaseSpriteReference {spriteName}，没有取到handle，这是不符合预期的");
				}
			}
		}

		public void CleanZeroRefLRU()
		{
			_zeroRefLRU.Clear();
		}

		private void AddToZeroRefLRU(string spriteName, AssetHandle handle)
		{
			_zeroRefLRU.Add(spriteName, handle);
		}

		private void OnLRUDeleteCallback(string name, AssetHandle handle)
		{
			if (!_allLoadedSpriteCount.ContainsKey(name))
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"LRU删除时，_allLoadedSpriteCount没有找到{name}，不符合预期");
			}

			if (_allLoadedSpriteCount[name] > 0)
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"LRU删除时，_allLoadedSpriteCount[name] > 0，不符合预期");
			}

			if (!_allLoadedSpriteHandles.ContainsKey(name))
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"LRU删除时，_allLoadedSpriteHandles没有找到{name}，不符合预期");
			}

			// 开始卸载
			_allLoadedSpriteCount.Remove(name);
			_allLoadedSpriteHandles.Remove(name);
			AssetManager.Instance.UnloadAsset(handle);
		}

		private SpriteReference EnsureSpriteReference(GameObject host)
		{
			return host.EnsureSpriteReference<SpriteReference>();
		}

		private SpriteReference GetSpriteReference(GameObject host)
		{
			return host.GetComponent<SpriteReference>();
		}

		public void LoadSprite(string spriteName, Image image, [CallerMemberName]string csharpCaller = null, bool forceAsync = false)
        {
            SpriteWrapper wrapper = new()
            {
                rendererType = RendererType.Image,
                image = image,
                Caller = csharpCaller,
            };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
			TryFindLuaCaller(ref wrapper);	        
#endif
            LoadSpriteWrapper(spriteName, wrapper, forceAsync);
        }

        public void LoadSpriteAndNotify(string spriteName, Image image, [CallerMemberName]string csharpCaller = null, bool forceAsync = false)
        {
	        SpriteWrapper wrapper = new()
	        {
		        rendererType = RendererType.Image,
		        image = image,
		        Caller = csharpCaller,
		        NotifySetSprite = true,
	        };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
	        TryFindLuaCaller(ref wrapper);	        
#endif
	        LoadSpriteWrapper(spriteName, wrapper, forceAsync);
        }

        public void LoadSprite(string spriteName, SpriteRenderer spriteRenderer, [CallerMemberName]string csharpCaller = null, bool forceAsync = false)
        {
            SpriteWrapper wrapper = new()
            {
                rendererType = RendererType.SpriteRenderer,
                spriteRenderer = spriteRenderer,
                Caller = csharpCaller
            };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
            TryFindLuaCaller(ref wrapper);	        
#endif
            LoadSpriteWrapper(spriteName, wrapper, forceAsync);
        }

        public void LoadSpriteAndNotify(string spriteName, SpriteRenderer spriteRenderer, [CallerMemberName]string csharpCaller = null, bool forceAsync = false)
        {
	        SpriteWrapper wrapper = new()
	        {
		        rendererType = RendererType.SpriteRenderer,
		        spriteRenderer = spriteRenderer,
		        Caller = csharpCaller,
		        NotifySetSprite = true
	        };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
	        TryFindLuaCaller(ref wrapper);	        
#endif
	        LoadSpriteWrapper(spriteName, wrapper, forceAsync);
        }
        
        public void LoadSprite(string spriteName, U2DSpriteMesh u2DSpriteMesh, [CallerMemberName]string csharpCaller = null, bool forceAsync = false)
        {
            SpriteWrapper wrapper = new()
            {
                rendererType = RendererType.U2DSpriteMesh,
                spriteMesh = u2DSpriteMesh,
                Caller = csharpCaller,
            };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
            TryFindLuaCaller(ref wrapper);
#endif
            LoadSpriteWrapper(spriteName, wrapper, forceAsync);
        }
        
        public void LoadSpriteAndNotify(string spriteName, U2DSpriteMesh u2DSpriteMesh, [CallerMemberName]string csharpCaller = null, bool forceAsync = false)
        {
	        SpriteWrapper wrapper = new()
	        {
		        rendererType = RendererType.U2DSpriteMesh,
		        spriteMesh = u2DSpriteMesh,
		        Caller = csharpCaller,
		        NotifySetSprite = true,
	        };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
	        TryFindLuaCaller(ref wrapper);
#endif
	        LoadSpriteWrapper(spriteName, wrapper, forceAsync);
        }

        public void SetNullSprite(Image image, [CallerMemberName]string csharpCaller = null)
        {
	        SpriteWrapper wrapper = new()
	        {
		        rendererType = RendererType.Image,
		        image = image,
		        Caller = csharpCaller,
	        };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
			TryFindLuaCaller(ref wrapper);	        
#endif
	        SetSpriteWrapperNull(wrapper);
        }
        
        public void SetNullSprite(SpriteRenderer spriteRenderer, [CallerMemberName]string csharpCaller = null)
        {
	        SpriteWrapper wrapper = new()
	        {
		        rendererType = RendererType.SpriteRenderer,
		        spriteRenderer = spriteRenderer,
		        Caller = csharpCaller
	        };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
            TryFindLuaCaller(ref wrapper);	        
#endif
	        SetSpriteWrapperNull(wrapper);
        }
        
        public void SetNullSprite(U2DSpriteMesh u2DSpriteMesh, [CallerMemberName]string csharpCaller = null)
        {
	        SpriteWrapper wrapper = new()
	        {
		        rendererType = RendererType.U2DSpriteMesh,
		        spriteMesh = u2DSpriteMesh,
		        Caller = csharpCaller,
	        };
#if UNITY_EDITOR && DEBUG_SPRITE_MAMAGER
            TryFindLuaCaller(ref wrapper);
#endif
	        SetSpriteWrapperNull(wrapper);
        }
        
        private void SetSpriteWrapperNull(SpriteWrapper spriteWrapper)
        {
	        if (!spriteWrapper.IsValid())
	        {
		        return;
	        }
	        using (UnityEngine.Pool.HashSetPool<SpriteWrapper>.Get(out var tempSet))
	        {
		        foreach (var wrapper in _allWaitCallbackWrappers)
		        {
			        if (wrapper.IsSameTarget(in spriteWrapper))
			        {
				        tempSet.Add(wrapper);
			        }
		        }
		        _allWaitCallbackWrappers.ExceptWith(tempSet);
		        tempSet.Clear();
	        }
	        spriteWrapper.SetEmpty(this);
        }

#if UNITY_EDITOR
		private bool? _isEditorWithLogicFolder = null;
		
		private void TryFindLuaCaller(ref SpriteWrapper wrapper)
		{
			//这意味着从XLua的SpriteManagerWrap里调用过来
			_isEditorWithLogicFolder ??= Directory.Exists(Path.Combine(Application.dataPath, "../../../../ssr-logic/Lua"));
			if (!_isEditorWithLogicFolder.Value)
			{
				return;
			}
			if (string.CompareOrdinal(wrapper.Caller, "_m_LoadSprite") != 0) return;
			if (!FrameworkInterfaceManager.QueryFrameInterface<IFrameworkLogger>(out var logger)) return;
			if (!logger.SHOW_STACK_TRACE_IN_LUA()) return;
			if (PlayerPrefs.GetInt("SHOW_STACK_TRACE_IN_LUA", 1) == 0) return;
			if (FrameworkInterfaceManager.QueryFrameInterface<IFrameworkLuaStackTrace>(out var stackTrace))
				wrapper.Caller = stackTrace.StackTrace();
		}
#endif

        private void LoadSpriteWrapper(string spriteName, SpriteWrapper spriteWrapper, bool forceAsync)
        {
            if (!spriteWrapper.IsValid())
            {
#if UNITY_DEBUG
                NLogger.WarnChannel(LOG_CHANNEL, $"try load {spriteName} but target component {spriteWrapper.rendererType} is null, " +
                                                 $"\ncaller is {spriteWrapper.Caller}");
#endif
                return;
            }

            if (string.IsNullOrWhiteSpace(spriteName))
            {
#if UNITY_DEBUG
                NLogger.WarnChannel(LOG_CHANNEL, $"component {spriteWrapper.GetName()} is setting Empty!, " +
                                                 $"\ncaller is {spriteWrapper.Caller}");
#endif

                spriteWrapper.SetEmpty(this);
				return;
            }

            if (!AssetManager.Instance.ExistsInAssetSystem(spriteName))
            {
#if UNITY_DEBUG
	            NLogger.ErrorChannel(LOG_CHANNEL, $"{spriteWrapper.GetName()}: '{spriteName}' doesn't exist!, " +
	                                              $"\ncaller is {spriteWrapper.Caller}");
#endif
	            return;
            }

            spriteWrapper.AddToRequestList(this, spriteName);
            _allWaitCallbackWrappers.Add(spriteWrapper);
            var cacheHit = false;
            LoadSpriteInternal(spriteName, sprite =>
            {
	            if (!_allWaitCallbackWrappers.Remove(spriteWrapper))
	            {
		            UnloadSpriteIfNotUsed(spriteName);
		            return;
	            }
                if (sprite)
                {
                    cacheHit = true;

                    // 回调时刻，host已经不存在了
                    if (spriteWrapper.IsValid())
                    {
                        spriteWrapper.SetSprite(this, spriteName, sprite);
                    }
                    else
                    {
						UnloadSpriteIfNotUsed(spriteName);
                    }
                }
            }, forceAsync);

            // 需要等待异步加载，先设置默认图片
            if (!cacheHit)
            {
                spriteWrapper.SetSprite(this, DEFAULT_SPRITE_NAME, DefaultSprite);
            }
        }

        private void LoadSpriteInternal(string spriteName, Action<Sprite> callback, bool forceAsync)
        {
			if (_allLoadedSpriteHandles.TryGetValue(spriteName, out var cachedSpriteHandle))
			{	
				callback(cachedSpriteHandle.Asset as Sprite);
				return;
			}

            AssetHandle handle;
            if (!forceAsync && AssetManager.Instance.CanLoadSync(spriteName))
            {
				// 如果不是强制异步加载，则尽量同步加载
				handle = AssetManager.Instance.LoadAsset(spriteName, true, AssetManager.SyncLoadReason.OptimizeForAsyncLoad);
                if (handle.IsValid)
                {
                    // 存储AssetHandle，卸载时用
                    if (!_allLoadedSpriteHandles.ContainsKey(spriteName))
                    {
                        _allLoadedSpriteHandles.Add(spriteName, handle);
                    }

                    var sprite = handle.Asset as Sprite;
                    callback.Invoke(sprite);
                }
                else
                {
                    // 失败处理
                    callback.Invoke(null);
                    AssetManager.Instance.UnloadAsset(handle);
                }
            }
            else 
            {
                handle = AssetManager.Instance.LoadAssetAsync(spriteName, (b, assetHandle) =>
                {
                    if (_allLoadingHandler.Contains(assetHandle))
                    {
                        _allLoadingHandler.Remove(assetHandle);
                    }

                    if (b && assetHandle.IsValid)
                    {
                        // 存储AssetHandle，卸载时用
                        if (!_allLoadedSpriteHandles.ContainsKey(spriteName))
                        {
                            _allLoadedSpriteHandles.Add(spriteName, assetHandle);
                        }

                        var sprite = assetHandle.Asset as Sprite;
                        callback.Invoke(sprite);
                    }
                    else
                    {
                        // 失败处理
                        callback.Invoke(null);
                        AssetManager.Instance.UnloadAsset(assetHandle);
                    }
                }, true);

                // 请求中
                if (!handle.IsValid)
                {
                    _allLoadingHandler.Add(handle);
                }
            }
        }

		public void OnLowMemory()
		{
			CleanZeroRefLRU();
		}

		internal void DumpSpriteRefCountInfo(List<SpriteRefInfo> writeTo)
		{
			foreach (var kv in _allLoadedSpriteCount)
			{
				writeTo.Add(kv);
			}
		}

		private struct SpriteWrapper
		{
			public RendererType rendererType;
			public Image image;
			public SpriteRenderer spriteRenderer;
			public U2DSpriteMesh spriteMesh;
			public bool NotifySetSprite;
			public string Caller;
			public List<string> Queue;

			public bool IsValid()
			{
				if (rendererType == RendererType.Image && image != null)
				{
					return true;
				}

				if (rendererType == RendererType.SpriteRenderer && spriteRenderer != null)
				{
					return true;
				}

				if (rendererType == RendererType.U2DSpriteMesh && spriteMesh != null)
				{
					return true;
				}

				return false;
			}

			public bool IsSameTarget(in SpriteWrapper wrapper)
			{
				if (rendererType != wrapper.rendererType) return false;
				switch (rendererType)
				{
					case RendererType.Image:
						return image == wrapper.image;
					case RendererType.SpriteRenderer:
						return spriteRenderer == wrapper.spriteRenderer;
					case RendererType.U2DSpriteMesh:
						return spriteMesh == wrapper.spriteMesh;
				}
				return false;
			}

			public GameObject GetHostGameObject()
			{
				if (rendererType == RendererType.Image && image != null)
				{
					return image.gameObject;
				}

				if (rendererType == RendererType.SpriteRenderer && spriteRenderer != null)
				{
					return spriteRenderer.gameObject;
				}

				if (rendererType == RendererType.U2DSpriteMesh && spriteMesh != null)
				{
					return spriteMesh.gameObject;
				}

				return null;
			}

			public string GetName()
			{
				var path = GetPath(Transform);
				return path;
			}

			private Transform Transform
			{
				get
				{
					var go = GetHostGameObject();
					return go ? go.transform : null;
				}
			}

			private static string GetPath(Transform transform)
			{
				var names = new List<string> { transform.name };

				var parent = transform.parent;
				while (parent != null)
				{
					names.Add(parent.name);
					parent = parent.parent;
				}

				names.Reverse();

				return string.Join('/', names);
			}

			/// <summary>
			/// 1, 多次请求，需要保证按顺序交付
			/// 2, 同名的请求，需要刷新顺序
			/// 3, 删除过号的请求
			/// </summary>
			/// <param name="manager"></param>
			/// <param name="spriteName"></param>
			public void AddToRequestList(SpriteManager manager, string spriteName)
			{
				var host = GetHostGameObject();
				manager.EnsureSpriteReference(host);

				var reqQueue = GetRequestQueue();
				if (reqQueue.Contains(spriteName))
				{
					reqQueue.Remove(spriteName);
				}
				reqQueue.Add(spriteName);
			}

			private List<string> GetRequestQueue()
			{
				if (Queue == null)
				{
					Queue = new();
				}

				return Queue;
			}

			/// <summary>
			/// 1, 多次请求，需要保证按顺序交付
			/// 2, 同名的请求，需要刷新顺序
			/// 3，删除过号的请求
			/// </summary>
			/// <param name="manager"></param>
			/// <param name="spriteName"></param>
			/// <returns></returns>
			private bool CheckRequestList(SpriteManager manager, string spriteName)
			{
				var host = GetHostGameObject();
				var spriteRef = manager.GetSpriteReference(host);
				var reqQueue = GetRequestQueue();
				if (!reqQueue.Contains(spriteName) && spriteName != DEFAULT_SPRITE_NAME)
				{
					NLogger.WarnChannel(LOG_CHANNEL, $"设置sprite失败，请求队列中没有找到{spriteName} {GetHashCode()}");
					return false;
				}

				var index = reqQueue.IndexOf(spriteName);
#if UNITY_DEBUG
				var cancelCount = index;
				for (var i = 0; i < cancelCount; i++)
				{
					NLogger.WarnChannel(LOG_CHANNEL, $"取消sprite {reqQueue[i]}的赋值");
				}
#endif
				reqQueue.RemoveRange(0, index + 1);
				return true;
			}

			public void SetSprite(SpriteManager manager, string spriteName, Sprite sprite)
			{
				// 处理过期的请求
				if (!CheckRequestList(manager, spriteName))
				{
					manager.UnloadSpriteIfNotUsed(spriteName);
					return;
				}

				// 当前目标节点还没有初始化过，需要把请求信息保存下来，待初始化后再处理
				var spriteHostGo = GetHostGameObject();
				var spRef = manager.GetSpriteReference(spriteHostGo);
				if (!spRef.Activated)
				{
					manager.UnloadSpriteIfNotUsed(spriteName);
					spRef.SaveRequest(spriteName, rendererType);
					return;
				}

				var success = false;
				if (rendererType == RendererType.Image && image != null)
				{
					image.sprite = sprite;
					success = true;
				}

				if (rendererType == RendererType.SpriteRenderer && spriteRenderer != null)
				{
					spriteRenderer.sprite = sprite;
					success = true;
				}

				if (rendererType == RendererType.U2DSpriteMesh && spriteMesh != null)
				{
					spriteMesh.sprite = sprite;
					success = true;
				}

				// 设置sprite成功，处理引用计数+1
				if (success)
				{
					manager.IncreaseSpriteReference(spriteName, spriteHostGo);
				}
				else
				{
					NLogger.Error($"SetSprite not success {spriteName}");
					manager.UnloadSpriteIfNotUsed(spriteName);
				}

				if (!NotifySetSprite) return;
				if (!spriteHostGo) return;
				var notify = spriteHostGo.GetComponent<ISpriteSetNotify>();
				notify?.OnSpriteManagerSetSprite(success, spriteName);
			}

			public void SetEmpty(SpriteManager manager)
			{
				if (rendererType == RendererType.Image && image != null)
				{
					image.sprite = null;
				}
				else if (rendererType == RendererType.SpriteRenderer && spriteRenderer != null)
				{
					spriteRenderer.sprite = null;
				}
				else if (rendererType == RendererType.U2DSpriteMesh && spriteMesh != null)
				{
					spriteMesh.sprite = null;
				}
				var spriteHostGo = GetHostGameObject();
				var spRef = manager.GetSpriteReference(spriteHostGo);
				if (!spRef) return;
				spRef.SetSpriteName(string.Empty);
			}
		}
	}
}
