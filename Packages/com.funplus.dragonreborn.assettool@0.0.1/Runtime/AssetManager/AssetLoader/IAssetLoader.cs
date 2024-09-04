using System;

namespace DragonReborn.AssetTool
{
    public interface IAssetLoader
    {
        void Initialize();
        void Reset();

        UnityEngine.Object LoadAsset(BundleAssetData data, bool isSprite);
        bool LoadAssetAsync(BundleAssetData data, Action<UnityEngine.Object> callback, bool isSprite);

        bool AssetExist(string assetName);

        bool IsAssetReady(string assetName);
    }
}
