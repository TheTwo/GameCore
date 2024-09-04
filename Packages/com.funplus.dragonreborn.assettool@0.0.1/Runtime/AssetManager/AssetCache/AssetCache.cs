using System;
using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
	public enum AssetCacheState
	{
		// ReSharper disable InconsistentNaming
		loading,
		complete,
		// ReSharper restore InconsistentNaming
	}
	
	public enum AssetLoadType
	{
		// ReSharper disable InconsistentNaming
		bundle,
		resources,
		// ReSharper restore InconsistentNaming
	}

	public class AssetCache : BaseRefCounter
	{
		private UnityEngine.Object _unityAsset;

		private BundleAssetData _bundleAssetData;
		private AssetCacheState _assetCacheState = AssetCacheState.loading;
		private AssetLoadType _loadType;
		private Action<AssetCache> _asyncLoadCallback;
		private AssetLoaderProxy _assetLoaderProxy;

		// Asset资源
		public UnityEngine.Object Asset
		{
			get
			{
#if UNITY_EDITOR
				FixPrefabShader(_unityAsset);
#endif
				return _unityAsset;
			}
		}
		
		public AssetLoadType LoadType => _loadType;

		// asset属于哪个AssetBundle
		public BundleAssetData BundleAssetData => _bundleAssetData;

		// asset的加载状态
		public AssetCacheState AssetCacheState => _assetCacheState;

		public AssetCache(string assetIndex, AssetLoaderProxy assetLoaderProxy)
		{
			_assetLoaderProxy = assetLoaderProxy;

			// editor下，且不指定使用bundle
			(_loadType, _bundleAssetData) = GetLoaderTypeAndBundleAssetData(assetIndex, assetLoaderProxy);
			if (_loadType == AssetLoadType.bundle && _bundleAssetData != null)
			{
				// 所属bundle引用计数+1
				_assetLoaderProxy.AssetBundleLoader.OnAssetCacheCreate(_bundleAssetData);
			}
		}

		public static (AssetLoadType,BundleAssetData) GetLoaderTypeAndBundleAssetData(string assetIndex, AssetLoaderProxy proxy)
		{
			var loaderType = AssetManager.Instance.IsBundleMode() ? AssetLoadType.bundle : AssetLoadType.resources;
			BundleAssetData bundleData = null;
			if (loaderType == AssetLoadType.bundle)
			{
				bundleData = BundleAssetDataManager.Instance.GetAssetData(assetIndex);
				if (bundleData == null)
				{
					if (!BundleAssetDataManager.Instance.DataAllInit())
					{
						var resourcesContains = proxy.ResourcesLoader.AssetExist(assetIndex);
						if (!resourcesContains)
						{
							NLogger.ErrorChannel(AssetManager.Channel, $"asset {assetIndex} can not be loaded before asset bundle all init");
						}
					}
					loaderType = AssetLoadType.resources;
				}
			}
			if (loaderType == AssetLoadType.resources)
			{
				bundleData = new BundleAssetData(assetIndex, string.Empty);
			}
			return (loaderType, bundleData);
		}

		public static bool CanSyncLoadCheck(AssetLoadType loadType, AssetLoaderProxy proxy,  string assetName)
		{
			switch (loadType)
			{
				case AssetLoadType.bundle:
					return proxy.AssetBundleLoader.IsAssetReady(assetName);
#if UNITY_EDITOR
				case AssetLoadType.resources:
				default:
					return proxy.AssetDatabaseLoader.IsAssetReady(assetName)
					       || proxy.ResourcesLoader.IsAssetReady(assetName);
#else
				case AssetLoadType.resources:
					return proxy.ResourcesLoader.IsAssetReady(assetName);
				default:
					throw new ArgumentOutOfRangeException();
#endif
			}
		}

		public bool CanSyncLoad()
		{
			return CanSyncLoadCheck(_loadType, _assetLoaderProxy, _bundleAssetData.AssetName);
		}

		/// <summary>
		/// 同步加载
		/// 注意：同步加载资源会触发AssetBundle的同步加载，此时如果依赖AssetBundle没准备好，会报错
		/// </summary>
		public void Load(bool isSprite)
		{
			if (_assetCacheState == AssetCacheState.complete)
			{
				return;
			}

			if (_loadType == AssetLoadType.bundle)
			{
				_unityAsset = _assetLoaderProxy.AssetBundleLoader.LoadAsset(_bundleAssetData, isSprite);
			}
			else if (_loadType == AssetLoadType.resources)
			{
				//编辑器下用AssetDatabase，运行时用Resources
#if UNITY_EDITOR
				if (!_unityAsset)
				{
					if (_assetLoaderProxy.AssetDatabaseLoader != null)
					{
						_unityAsset = _assetLoaderProxy.AssetDatabaseLoader.LoadAsset(_bundleAssetData, isSprite);
					}
				}
#endif

				if (!_unityAsset)
				{
					_unityAsset = _assetLoaderProxy.ResourcesLoader.LoadAsset(_bundleAssetData, isSprite);

					if (!_unityAsset)
					{
						NLogger.Error(_bundleAssetData.AssetName + " 在本地资源路径中未找到");
					}
				}
			}

			if (_unityAsset == null)
			{
				_assetCacheState = AssetCacheState.loading;
			}
			else
			{
				_assetCacheState = AssetCacheState.complete;
			}
		}

		/// <summary>
		/// 异步加载
		/// </summary>
		/// <param name="callback"></param>
		/// <param name="isSprite"></param>
		/// <param name="priority"></param>
		public void LoadAsync(Action<AssetCache> callback, bool isSprite, int priority = 0)
		{
			//如果资源加载完毕，不会重复调用底层加载
			if (_assetCacheState == AssetCacheState.complete)
			{
				callback(this);
				return;
			}

			_asyncLoadCallback = callback;
			if (_loadType == AssetLoadType.bundle)
			{
				// 获取资源所在的AssetBundle A，和A依赖的AssetBundle list
				var allBundleNeedSync = new List<string>();
				var dependenceData = BundleDependenceManager.Instance.GetBundleDependence(_bundleAssetData.BundleName);
				if (dependenceData != null && dependenceData.HasDependence())
				{
					allBundleNeedSync.AddRange(dependenceData.Dependence);
				}
				allBundleNeedSync.Add(_bundleAssetData.BundleName);

				// 下载完所有依赖后，调用AssetBundleLoader.Load
				AssetBundleSyncManager.Instance.SyncAssetBundles(allBundleNeedSync, (result) =>
				{
					_assetLoaderProxy.AssetBundleLoader.LoadAssetAsync(_bundleAssetData, OnAssetBundleLoadCallback, isSprite);
				}, null, (int) DownloadPriority.UltraHigh);
			}
			else if (_loadType == AssetLoadType.resources)
			{
#if UNITY_EDITOR
				// 先用AssetDatabaseLoader
				var success = _assetLoaderProxy.AssetDatabaseLoader.LoadAssetAsync(_bundleAssetData, OnAssetDatabaseLoadCallback, isSprite);

				// 失败再用ResourcesLoader
				if (!success)
				{
					_assetLoaderProxy.ResourcesLoader.LoadAssetAsync(_bundleAssetData, OnResourcesLoadCallback, isSprite);
				}
#else
				_assetLoaderProxy.ResourcesLoader.LoadAssetAsync(_bundleAssetData, OnResourcesLoadCallback, isSprite);
#endif
			}
		}

#if UNITY_EDITOR
		private void OnAssetDatabaseLoadCallback(UnityEngine.Object loadedObject)
		{
			_unityAsset = loadedObject;
			if (loadedObject != null)
			{
				_assetCacheState = AssetCacheState.complete;
				_asyncLoadCallback(this);
				_asyncLoadCallback = null;
			}
		}
#endif

		private void OnAssetBundleLoadCallback(UnityEngine.Object loadedObject)
		{
			_unityAsset = loadedObject;
			//不管成功与否都是complete
			if (_unityAsset)
			{
				_assetCacheState = AssetCacheState.complete;
			}

			if (loadedObject == null)
			{
				Debug.LogError($"asset {_bundleAssetData.AssetName} load failed from bundle {_bundleAssetData.BundleName}");

			}

			_asyncLoadCallback(this);
			_asyncLoadCallback = null;
		}

		private void OnResourcesLoadCallback(UnityEngine.Object loadedObject)
		{
			_unityAsset = loadedObject;
			//不管成功与否都是complete
			_assetCacheState = AssetCacheState.complete;

			if (loadedObject == null)
			{
				Debug.LogError(_bundleAssetData.AssetName + " 在本地资源路径中未找到，请尝试重新生成");
			}

			_asyncLoadCallback(this);
			_asyncLoadCallback = null;
		}

		public void Release()
		{
			//unload asset
			DestroyAsset();

			//资源销毁减少AssetBundle的引用
			if (_loadType == AssetLoadType.bundle)
			{
				_assetLoaderProxy.AssetBundleLoader.OnAssetCacheRelease(_bundleAssetData);
			}
		}

		public bool CanRemove()
		{
			//加载中的资源不能删除
			if (_referenceCount <= 0 && _assetCacheState == AssetCacheState.complete)
			{
				return true;
			}

			return false;
		}

		private void DestroyAsset()
		{
			if (_unityAsset)
			{
				//如果是无法立即卸载的资源，不能用unload asset
				if (CanUnloadImmediate())
				{
					Resources.UnloadAsset(_unityAsset);
					_unityAsset = null;
				}
				else
				{
					//AssetBundle里的prefab不能destroy，如果bundle还在，prefab被干掉了，再次加载会返回空
					_unityAsset = null;
				}
			}
#if UNITY_EDITOR
			_assetShaderProcessed = false;
#endif
		}

		// https://docs.unity3d.com/ScriptReference/Resources.UnloadAsset.html
		// Resources.UnloadAsset(asset). This function can only be called on Assets that are stored on disk.
		public bool CanUnloadImmediate()
		{
			var needKeep = _unityAsset is GameObject || _unityAsset is Component || _unityAsset is Sprite || _unityAsset is Texture;
			return !needKeep && _unityAsset;
		}
		
#if UNITY_EDITOR
		private readonly List<Renderer> _renderers = new();
		private bool _assetShaderProcessed;
		private void FixPrefabShader(UnityEngine.Object asset)
		{
			if (!AssetManager.Instance.IsBundleMode()) return;
			if (asset is not GameObject go || !go) return;
			if (_assetShaderProcessed) return;
			_assetShaderProcessed = true;
			using (UnityEngine.Pool.HashSetPool<Material>.Get(out var tempSet))
			{
				_renderers.Clear();
				go.GetComponentsInChildren(true, _renderers);
				foreach (var renderer in _renderers)
				{
					var sharedMaterials = renderer.sharedMaterials;
					foreach (var material in sharedMaterials)
					{
						if (!material) continue;
						tempSet.Add(material);
								
					}
				}
				foreach (var material in tempSet)
				{
					var shader = material.shader;
					if (!shader) continue;
					var editorShader = Shader.Find(shader.name);
					if (editorShader)
					{
						material.hideFlags = HideFlags.DontSave;
						material.shader = editorShader;
					}
					else
					{
						NLogger.Error("Failed to fix shader for editor: {0}", shader.name);
					}
				}
				_renderers.Clear();
			}
		}
#endif

		public string ToDebugString(bool showBundleName = true)
		{
			if (showBundleName)
			{
				return $"AssetBundle:{BundleAssetData.BundleName}, Asset:{BundleAssetData.AssetName}, Type:{_unityAsset.GetType()} RefCount:{GetRefCount()}";
			}

			return $"{BundleAssetData.AssetName}\tRef:{GetRefCount()}";
		}
	}
}
