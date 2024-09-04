using System;
using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
    public class AssetBundleSyncManager : Singleton<AssetBundleSyncManager>
    {
        public void SyncAssetBundles(List<string> assetBundles, Action<bool> finishedCallback, Action<string, ulong, ulong> onProgress = null, int priority = 0)
        {
            var task = new AssetBundleSyncTask(assetBundles, finishedCallback, onProgress, priority);
            task.Start();
        }
    }
}
