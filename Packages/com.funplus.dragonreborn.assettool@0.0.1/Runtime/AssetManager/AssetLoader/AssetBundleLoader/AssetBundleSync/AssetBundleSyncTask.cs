using System;
using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
    internal class AssetBundleSyncTask
    {
        private const string RelativePath = "GameAssets/AssetBundle/{0}/{1}.ab";

        private List<string> _assetBundleList;
        private Action<bool> _finishCallback;
		private Action<string, ulong, ulong> _onProgress;
        private int _taskTotalCount;
        private int _taskProgress;
		private int _priority;

        public AssetBundleSyncTask(List<string> assetBundleList, Action<bool> finishCallback, Action<string, ulong, ulong> onProgress, int priority = 0)
        {
            _assetBundleList = assetBundleList;
            _finishCallback = finishCallback;
			_onProgress = onProgress;
			_priority = priority;

		}

        public void Start()
        {
            _taskTotalCount = _assetBundleList.Count;
            _taskProgress = 0;

            foreach (var assetBundleName in _assetBundleList)
            {
                var relativePath = GetRelativeFilepath(assetBundleName);
                VersionControl.SyncFile(relativePath, (result, file) => 
                {
                    _taskProgress++;
                    if (result == VersionControl.Result.Error)
                    {
                        throw new Exception($"Download AssetBundle {assetBundleName} failed. Need Restart Game!!!");
                    }

                    if (_taskProgress == _taskTotalCount)
                    {
						_finishCallback?.Invoke(true);
                    }

                }, _onProgress, _priority, true);
            }
        }

        public static string GetRelativeFilepath(string bundleName)
        {
            return string.Format(RelativePath, PathHelper.GetBundlePlatformFolderName(), bundleName);
        }
    }
}
