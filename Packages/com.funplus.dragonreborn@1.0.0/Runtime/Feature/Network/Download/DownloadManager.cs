using System;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public class DownloadManager : Singleton<DownloadManager>, IManager, ITicker
	{
		private readonly AssetServiceProcessor _assetServiceProcessor = new AssetServiceProcessor();
		private bool _limitDownloadQueueMode;

		

		public void OnGameInitialize(object configParam)
		{
			_assetServiceProcessor.SetRequestStrategy(new BaseRequestStrategy());
			_assetServiceProcessor.SetAssetDownloadQueue(AssetServiceProcessor.DefaultMaxRequestCount);
		}

		public void SetDownloadLimitMode(bool isLimit)
        {
            _limitDownloadQueueMode = isLimit;
            _assetServiceProcessor.SetAssetDownloadQueue(_limitDownloadQueueMode ? 1 : AssetServiceProcessor.DefaultMaxRequestCount);
        }

		public void Reset()
		{
			_assetServiceProcessor.Reset();
		}

		public void DownloadAsset(string url, string savePath, Action<bool, HttpResponseData> callback, Action<ulong, ulong> onProgress = null,
			int priority = (int)DownloadPriority.Normal, uint crcCheckValue = 0, bool restartOnError = false, 
			Action<bool, HttpResponseData, AssetServiceRequest> setVersionCallback = null)
		{
			if (!AssetServiceRequest.IsValid(savePath))
			{
				NLogger.Error(savePath + " IsValid");
				return;
			}

			_assetServiceProcessor.InsertRequest(new AssetServiceRequest(url, savePath, callback, onProgress, priority,
				crcCheckValue, 0, restartOnError, setVersionCallback));

			DebugLog("url {0} savePath {1} priority {2}", url, savePath, priority);
		}
		
		public bool IsInDownloadQueue(string url, string savePath)
        {
            return _assetServiceProcessor.HasRequest(url, savePath);
        }

		public void Tick(float dt)
		{
			_assetServiceProcessor.Tick(dt);
		}

		[System.Diagnostics.Conditional("HTTP_LOADER_SERVICE_PROCESSOR_LOG_ENABLED")]
		[System.Diagnostics.CodeAnalysis.SuppressMessage("ReSharper", "UnusedParameter.Local")]
		private static void DebugLog(string log, params object[] parameters)
		{
#if HTTP_LOADER_SERVICE_PROCESSOR_LOG_ENABLED
			NLogger.LogChannel("DownloadManager", log, parameters);
#endif
		}

		public void OnLowMemory()
		{

		}
	}
}
