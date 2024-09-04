using System;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public static class AssetBundleAsyncLoadTracker
    {
        public static bool NoneLoading => _assetAsyncLoadingCount == 0;
        
        public static int AssetAsyncLoadingCount => _assetAsyncLoadingCount;

        private static int _assetAsyncLoadingCount;

        private static readonly Action<AsyncOperation> OnRequestComplete = _ =>
        {
            --_assetAsyncLoadingCount;
        };

        public static AssetBundleRequest TrackedAsyncLoad(this AssetBundle bundle, string assetName)
        {
            ++_assetAsyncLoadingCount;
            var request = bundle.LoadAssetAsync(assetName);
            request.completed += OnRequestComplete;
            return request;
        }
        
        public static AssetBundleRequest TrackedAsyncLoad<T>(this AssetBundle bundle, string assetName)
        {
            ++_assetAsyncLoadingCount;
            var request = bundle.LoadAssetAsync<T>(assetName);
            request.completed += OnRequestComplete;
            return request;
        }
    }
}