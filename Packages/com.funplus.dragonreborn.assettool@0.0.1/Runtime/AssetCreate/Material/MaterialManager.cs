using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
	public class MaterialManager : Singleton<MaterialManager>, IManager
    {
	    private class MaterialCache : IRefCounter
	    {
		    private AssetHandle _handle;
		    private int _refCount;
		    private Material _material;

		    public MaterialCache(AssetHandle handle)
		    {
			    _handle = handle;
			    _material = handle.Asset as Material;
		    }
		    
		    public bool IsMyHandle(AssetHandle handle)
		    {
			    return _handle == handle;
		    }

		    public Material GetMaterialAndAddRef()
		    {
			    Increase();
			    return _material;
		    }

		    public void Increase(string log = "")
		    {
			    ++_refCount;
		    }

		    public bool Decrease(string log = "")
		    {
			    if (null == _handle) return true;
			    --_refCount;
			    if (_refCount != 0) return false;
			    _material = null;
			    AssetManager.Instance.UnloadAsset(_handle);
			    _handle = null;
			    return true;
		    }

		    public int GetRefCount()
		    {
			    return _refCount;
		    }

		    public void ResetRefCount()
		    {
			    _refCount = 0;
		    }

		    public void ForceRelease()
		    {
			    ResetRefCount();
			    if (null == _handle) return;
			    _material = null;
			    AssetManager.Instance.UnloadAsset(_handle);
			    _handle = null;
		    }
	    }

	    private readonly Dictionary<string, MaterialCache> _allLoadedMaterials = new();

        public void OnGameInitialize(object configParam)
        { }

        public void Reset()
        {
            foreach (var pair in _allLoadedMaterials)
            {
	            pair.Value.ForceRelease();
            }
            _allLoadedMaterials.Clear();
        }

        /// <summary>
        /// 材质加载
        /// </summary>
        /// <param name="materialName"></param>
        /// <returns></returns>
        public Material LoadMaterial(string materialName)
        {
			if (_allLoadedMaterials.TryGetValue(materialName, out var materialCache))
            {
	            return materialCache.GetMaterialAndAddRef();
            }

			var assetHandle = AssetManager.Instance.LoadAsset(materialName);
			if (assetHandle.IsValid)
			{
				var cache = new MaterialCache(assetHandle);
				_allLoadedMaterials.Add(materialName, cache);
				return cache.GetMaterialAndAddRef();
			}

			var stackInfo = new System.Diagnostics.StackTrace(true);
				
			NLogger.Error($"LoadMaterial {materialName} failed. {stackInfo}");

			return null;
        }

		public void LoadMaterialAsync(string materialName, System.Action<bool, Material> callback)
		{
			if (_allLoadedMaterials.TryGetValue(materialName, out var materialCache))
			{
				callback?.Invoke(true, materialCache.GetMaterialAndAddRef());
				return;
			}

			AssetManager.Instance.LoadAssetAsync(materialName, (isSuccess, assetHandle) =>
			{
				if (isSuccess && assetHandle.IsValid)
				{
					var needReleaseHandle = false;
					if (!_allLoadedMaterials.TryGetValue(materialName, out var cache))
					{
						cache = new MaterialCache(assetHandle);
						_allLoadedMaterials.Add(materialName, cache);
					}
					else if (!cache.IsMyHandle(assetHandle))
					{
						// 有缓存了 用缓存的 异步加载的就放掉
						needReleaseHandle = true;
					}
					callback?.Invoke(true, cache.GetMaterialAndAddRef());
					if (needReleaseHandle)
					{
						AssetManager.Instance.UnloadAsset(assetHandle);
					}
				}
				else
				{
					AssetManager.Instance.UnloadAsset(assetHandle);
					callback?.Invoke(false, null);
				}
			});
		}

		public void UnloadMaterial(string materialName)
		{
			if (!_allLoadedMaterials.TryGetValue(materialName, out var cache)) return;
			if (!cache.Decrease()) return;
			_allLoadedMaterials.Remove(materialName);
		}

		public void OnLowMemory()
		{

		}
	}
}
