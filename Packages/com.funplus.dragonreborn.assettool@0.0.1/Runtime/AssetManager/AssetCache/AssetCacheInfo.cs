using System;
using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
    [Serializable]
    internal struct DiffField<T>
    {
        public T Value;
        public bool Changed;

        public DiffField(T value, bool changed) : this()
        {
            Value = value;
            Changed = changed;
        }
    }
    
    [Serializable]
    internal struct AssetCacheInfoDiff
    {
        public string Key;
        public DiffField<int> RefCount;
        public DiffField<AssetLoadType> LoadType;
        public DiffField<AssetCacheState> State;
        public DiffField<string> BundleName;
        public DiffField<bool> IsScene;
        
        public bool AnyDiff()
        {
            return RefCount.Changed || LoadType.Changed || State.Changed || BundleName.Changed || IsScene.Changed;
        }
    }
    
    [Serializable]
    internal struct AssetCacheInfo
    {
        public string AssetName;
        public int RefCount;
        public AssetLoadType LoadType;
        public AssetCacheState State;
        public string BundleName;
        public bool IsScene;
        
        public static implicit operator AssetCacheInfo(KeyValuePair<string, AssetCache> assetCache)
        {
            return new AssetCacheInfo
            {
                AssetName = assetCache.Key,
                RefCount = assetCache.Value.GetRefCount(),
                LoadType = assetCache.Value.LoadType,
                State = assetCache.Value.AssetCacheState,
                BundleName = assetCache.Value.BundleAssetData?.BundleName,
                IsScene = assetCache.Value.BundleAssetData?.IsScene ?? false
            };
        }

        public static AssetCacheInfoDiff operator -(in AssetCacheInfo a, in AssetCacheInfo b)
        {
            return new AssetCacheInfoDiff()
            {
                Key = a.AssetName,
                RefCount = new DiffField<int>(a.RefCount - b.RefCount, a.RefCount != b.RefCount),
                LoadType = new DiffField<AssetLoadType>(a.LoadType, a.LoadType != b.LoadType),
                State = new DiffField<AssetCacheState>(a.State, a.State != b.State),
                BundleName = new DiffField<string>(a.BundleName, string.CompareOrdinal(a.BundleName, b.BundleName) != 0),
                IsScene = new DiffField<bool>(a.IsScene, a.IsScene != b.IsScene),
            };
        }
    }
    
    [Serializable]
    internal struct BundleCacheInfoDiff
    {
        public string Key;
        public DiffField<int> AssetRef;
        public DiffField<int> DependenceRef;
        public DiffField<AssetBundleLoadingState> State;
        
        public bool AnyDiff()
        {
            return AssetRef.Changed || DependenceRef.Changed || State.Changed;
        }
    }

    [Serializable]
    internal struct BundleCacheInfo
    {
        public string BundleName;
        public string BundleFilePath;
        public int AssetRef;
        public int DependenceRef;
        public AssetBundleLoadingState State;
        
        public static implicit operator BundleCacheInfo(KeyValuePair<string, AssetBundleCache> bundleCache)
        {
            return new BundleCacheInfo()
            {
                BundleName = bundleCache.Key,
#if UNITY_DEBUG
                BundleFilePath = bundleCache.Value.AssetBundleFullPath,
#else
                BundleFilePath = "<NO DATA>",
#endif
                AssetRef = bundleCache.Value.GetRefCount(),
                DependenceRef = bundleCache.Value.ByRefCount,
                State = bundleCache.Value.State
            };
        }
        
        public static BundleCacheInfoDiff operator -(in BundleCacheInfo a, in BundleCacheInfo b)
        {
            return new BundleCacheInfoDiff()
            {
                Key = a.BundleName,
                AssetRef = new DiffField<int>(a.AssetRef - b.AssetRef, a.AssetRef != b.AssetRef),
                DependenceRef = new DiffField<int>(a.DependenceRef - b.DependenceRef, a.DependenceRef != b.DependenceRef),
            };
        }
    }
}