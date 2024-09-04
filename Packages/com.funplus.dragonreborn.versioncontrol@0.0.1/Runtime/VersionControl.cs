using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using UnityEngine;
using UnityEngine.Scripting;

namespace DragonReborn
{
    [Preserve]
    public class VersionControl
    {
        public static string BaseUrl;
        public static string CustomUrl = string.Empty;
		public static string VersionName;
		public static string BuildNumber;
		public static string CustomBuildNumber;
		public static bool RuntimeLocalAssetOnly;
		public static string RemoteResVersion;

		// ReSharper disable InconsistentNaming
		public static VersionDefine localVersion;
		public static VersionDefine remoteVersion;
        public static VersionDefine streamingAssetsVersion;
		public static bool VersionReadyFlag = false;

		// ReSharper disable once FieldCanBeMadeReadOnly.Global
		// ReSharper disable once ConvertToConstant.Global
		// ReSharper disable once MemberCanBePrivate.Global
		// ReSharper disable once StringLiteralTypo
		public static string localVersionFile = "localversion.json";
		
		public static string localVersionFilePath => AssetPath.Combine(Application.persistentDataPath, localVersionFile);

		// ReSharper disable once UnusedMember.Local
		private const string LOG_CHANNEL = "Version";
		// ReSharper restore InconsistentNaming

		public static Func<string, string> GetBundleRelativePath;
		
		//保存的计数器
		private static int saveCounter = 0;
		
		//需要保存的最大数量
		private static int saveMaxCount = 10; 
		
		// 保存的时间间隔, 单位s
		private static int saveInterval = 30;
		
		//执行保存的时间
		private static float saveTime = 0;
		
		private static object saveLock = new object(); // 用于同步的锁
		private static Stopwatch stopwatch = new Stopwatch(); // 计时器替代 Time.realtimeSinceStartup

        public enum Result
        {
            Error = -1,
            Success = 0,
            SuccessNotUpdate = 1,
        }

		private static bool IsVersionReady()
		{
			if (VersionReadyFlag)
			{
				return true;
			}

			return remoteVersion != null && localVersion != null && streamingAssetsVersion != null;
		}

		// 设置保存的最大数量和时间间隔
		public static void SetSaveCountAndInterval(int count, int interval)
		{
			saveMaxCount = count;
			saveInterval = interval;
			stopwatch.Restart();
		}

		public static bool IsFileReady(string relativeFilePath)
		{
			if (NeedUpdate(relativeFilePath))
			{
				return false;
			}

			return IOUtils.HaveBundleAssetInPackage(relativeFilePath) || IOUtils.HaveBundleAssetInDocument(relativeFilePath);
		}

		public static bool InSyncing(string relativeFilePath)
		{
			if (!NeedUpdate(relativeFilePath)) return false;
			var downloadUrl = GetDownLoadUrl(relativeFilePath);
			var savePath = GetSavePath(relativeFilePath);
			return DownloadManager.Instance.IsInDownloadQueue(downloadUrl, savePath);
		}

		// 返回总的更新量
        public static void SyncFile(string relativeFilePath, Action<Result, string> callback, Action<string, ulong, ulong> onProgress = null, 
			int priority = (int)DownloadPriority.Normal, bool restartOnError = false)
        {
	        if (!IsVersionReady())
	        {
		        NLogger.ErrorChannel(LOG_CHANNEL, relativeFilePath + " :在资源更新阶段结束前访问了资源同步");
		        callback?.Invoke(Result.Error, relativeFilePath);
		        return;
	        }
        
            if (!NeedUpdate(relativeFilePath))
            {
				NLogger.LogChannel(LOG_CHANNEL, $"Wont update {relativeFilePath}");
                callback?.Invoke(Result.SuccessNotUpdate, relativeFilePath);
                return;
            }
            
            var versionCell = remoteVersion.GetVersion(relativeFilePath);
			var downloadUrl = GetDownLoadUrl(relativeFilePath);
			var savePath = GetSavePath(relativeFilePath);
			DoSyncFile(relativeFilePath, downloadUrl, savePath, versionCell, callback, onProgress, priority,
				restartOnError, nameof(SyncFile));
        }

        private static void DoSyncFile(string relativeFilePath, string downloadUrl, string savePath,
	        VersionDefine.VersionCell versionCell, Action<Result, string> callback, Action<string, ulong, ulong> onProgress,
	        int priority, bool restartOnError, string logFunc)
        {
	        NLogger.LogChannel(LOG_CHANNEL, $"download {downloadUrl}, save to {savePath}");
	        // ReSharper disable once UnusedParameter.Local
	        DownloadManager.Instance.DownloadAsset(downloadUrl, savePath, (b, data) =>
	        {
		        if (b)
		        {
			        callback?.Invoke(Result.Success, relativeFilePath);
			        NLogger.LogChannel(LOG_CHANNEL, $"{logFunc} {relativeFilePath} Success and have updated LocalVersion");
		        }
		        else
		        {
			        callback?.Invoke(Result.Error, relativeFilePath);
			        NLogger.ErrorChannel(LOG_CHANNEL, $"{logFunc} {relativeFilePath} Error");
		        }

	        }, (downloadedBytes, allBytes) => { 
		        onProgress?.Invoke(relativeFilePath, downloadedBytes, allBytes);
	        }, priority, versionCell.Crc, restartOnError, (b, _, _) =>
	        {
		        if (!b) return;
		        // 更新local version
		        localVersion.SetVersion(relativeFilePath, versionCell);
		        IOUtils.UpdateDocumentBundleAssetMap(relativeFilePath);

				SaveLocalVersionAsync();
			});
        }

		public static void SaveLocalVersionAsync()
		{
			TaskManager.Instance.RunAsync(SaveLocalVersion);
		}

		public static void MovePacksToDocument(Dictionary<string, VersionDefine.VersionCell> allPacks)
		{
			if (allPacks == null || allPacks.Count == 0)
			{
				return;
			}

			foreach (var (relativePath, cell) in allPacks)
			{
				NLogger.LogChannel(LOG_CHANNEL, $"Try MovePacksToDocument: {relativePath}");
				if (IOUtils.HaveGameAssetInDocument(relativePath))
				{
					NLogger.LogChannel(LOG_CHANNEL, $"Try MovePacksToDocument and already in document: {relativePath}");
					continue;
				}

				if (IOUtils.TryUnzipGameAssets(relativePath))
				{
					NLogger.LogChannel(LOG_CHANNEL, $"Try MovePacksToDocument unzip and copy success: {relativePath}");
					// 更新local version
					localVersion.SetVersion(relativePath, cell);
					SaveLocalVersionAsync();
				}
				else
				{
					NLogger.LogChannel(LOG_CHANNEL, $"Try MovePacksToDocument unzip and copy error: {relativePath}");
				}
			}
		}

		private static void SaveLocalVersion()
		{
			lock (saveLock)
			{
				if (localVersion == null)
				{
					// 注意：这里的日志记录需要替换为一个线程安全的日志系统
					Console.Error.WriteLine("localVersion is null");
					return;
				}

				saveCounter++;

				// 使用 Stopwatch 来检查时间间隔
				if(stopwatch.Elapsed.TotalSeconds > saveInterval || saveCounter > saveMaxCount)
				{
					stopwatch.Restart();
					saveCounter = 0;

					lock (localVersion)
					{
						// 确保 IOUtils.WriteGameAssetDefer 和 DataUtils.ToJson 是线程安全的
						// 或者在这里实现它们的线程安全版本
						string jsonData = DataUtils.ToJson(localVersion);
						bool hasEncrypt = IOUtils.HasEncryptTag(); // 假设这个方法是线程安全的
						IOUtils.WriteGameAssetDefer(localVersionFile, jsonData, hasEncrypt);
					}
				}
			}
		}

		public static Dictionary<string, VersionDefine.VersionCell> GetUpdateCells(Dictionary<string, VersionDefine.VersionCell> cells)
		{
			var tmp = new Dictionary<string, VersionDefine.VersionCell>();
			foreach (var (relativePath, cell) in cells)
			{
				// 需要更新的
				if (NeedUpdate(relativePath))
				{
					tmp[relativePath] = cell;
				}
			}
			return tmp;
		}

        public static long GetUpdateBytes(Dictionary<string, VersionDefine.VersionCell> cells)
		{
			var totalBytes = 0L;
			foreach (var (relativePath, cell) in cells)
			{
				// 需要更新的
				if (NeedUpdate(relativePath))
				{
					totalBytes += cell.ZipBytes;
				}
			}
			return totalBytes;
		}

        // 返回总的更新量
        public static void SyncFiles(Dictionary<string, VersionDefine.VersionCell> cells, Action<Result, string> callBack, Action<string, ulong, ulong> onProgress = null,
			int priority = (int)DownloadPriority.Normal, bool restartOnError = false, List<string> orderList = null)
        {
			if (!IsVersionReady())
			{
				NLogger.ErrorChannel(LOG_CHANNEL, "在资源更新阶段结束前访问了资源同步 SyncFiles");
				return;
			}

			// 按一定的顺序下载
			if (orderList != null && orderList.Count > 0)
			{
				// 先根据orderList，按顺序下载
				var markSet = new HashSet<string>();
				foreach (var bundleName in orderList)
				{
					var relativeFilePath = VersionDefine.GetBundleRelativePath(bundleName);
					markSet.Add(relativeFilePath);
					if (!cells.ContainsKey(relativeFilePath))
					{
						continue;
					}

					if (!NeedUpdate(relativeFilePath))
					{
						callBack?.Invoke(Result.SuccessNotUpdate, relativeFilePath);
						continue;
					}

					var versionCell = remoteVersion.GetVersion(relativeFilePath);
					DoSyncFile(relativeFilePath, GetDownLoadUrl(relativeFilePath), GetSavePath(relativeFilePath), versionCell, callBack, onProgress, priority, restartOnError, nameof(SyncFiles));
				}

				// 剩余部分，不保证顺序下载
				var others = new HashSet<string>(cells.Keys);
				others.ExceptWith(markSet);
				foreach (var relativeFilePath in others)
				{
					if (!cells.ContainsKey(relativeFilePath))
					{
						continue;
					}

					if (!NeedUpdate(relativeFilePath))
					{
						callBack?.Invoke(Result.SuccessNotUpdate, relativeFilePath);
						continue;
					}

					var versionCell = remoteVersion.GetVersion(relativeFilePath);
					DoSyncFile(relativeFilePath, GetDownLoadUrl(relativeFilePath), GetSavePath(relativeFilePath), versionCell, callBack, onProgress, priority, restartOnError, nameof(SyncFiles));
				}
			}
			else
			{
				// 不保证顺序下载
				foreach (var pair in cells)
				{
					var relativeFilePath = pair.Key;
					if (!NeedUpdate(relativeFilePath))
					{
						callBack?.Invoke(Result.SuccessNotUpdate, relativeFilePath);
						continue;
					}

					var versionCell = remoteVersion.GetVersion(relativeFilePath);
					DoSyncFile(relativeFilePath, GetDownLoadUrl(relativeFilePath), GetSavePath(relativeFilePath), versionCell, callBack, onProgress, priority, restartOnError, nameof(SyncFiles));
				}
			}
        }
        
        public static bool NeedUpdate(string relativeFilePath)
        {
	        if(localVersion == null || streamingAssetsVersion == null || remoteVersion == null)
            {
                return false;
            }

	        if (RuntimeLocalAssetOnly)
			{
				if (IOUtils.HaveBundleAssetInDocument(relativeFilePath))
				{
					IOUtils.DeleteGameAsset(relativeFilePath);
				}
				return false;
			}

			var localMd5 = localVersion.GetVersion(relativeFilePath).Md5;

			var streamingAssetsMd5 = string.Empty;
			if (IOUtils.HaveBundleAssetInPackage(relativeFilePath)) 
			{
				streamingAssetsMd5 = streamingAssetsVersion.GetVersion(relativeFilePath).Md5;
			}

	        var remoteMd5 = remoteVersion.GetVersion(relativeFilePath).Md5;
	        
	        //本地与远端md5相同，并且document目录存在该文件，不需要更新
	        if (localMd5 == remoteMd5 && IOUtils.HaveBundleAssetInDocument(relativeFilePath))
	        {
		        return false;
	        }

	        // streamingAssets 版本与远端一致, 不需要更新。如果document目录存在该文件，需要将其删除
            if (streamingAssetsMd5 == remoteMd5)
            {
	            if (IOUtils.HaveBundleAssetInDocument(relativeFilePath))
	            {
		            IOUtils.DeleteGameAsset(relativeFilePath);
	            }
	            return false;
            }
            
            //NLogger.LogChannel(LOG_CHANNEL, $"{relativeFilePath} need update");

            return true;
        }

        private static string GetDownLoadUrl(string relativeFilePath)
        {
            return BaseUrl + relativeFilePath;
        }

        private static string GetSavePath(string relativeFilePath)
        {
            return AssetPath.Combine(Application.persistentDataPath, relativeFilePath);
        }
        
        private class VersionControlAdaptersDescriptor : FrameInterfaceDescriptor<IFrameVersionControl>
        {
	        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterAssembliesLoaded)]
	        private static void RegisterDescriptor()
	        {
		        FrameworkInterfaceManager.RegisterFrameInterface(new VersionControlAdaptersDescriptor());
	        }
			
	        protected override IFrameVersionControl Create()
	        {
		        return new VersionControlAdapter();
	        }
        }

        private class VersionControlAdapter : IFrameVersionControl
        {
	        bool IFrameVersionControl.IsFileReady(string relativeFilePath)
	        {
				return IsFileReady(relativeFilePath);
	        }

	        bool IFrameVersionControl.InSyncing(string relativeFilePath)
	        {
		        return InSyncing(relativeFilePath);
	        }

	        void IFrameVersionControl.SyncFile(string relativeFilePath)
	        {
				SyncFile(relativeFilePath, null);
	        }
        }

//#if UNITY_EDITOR
//	    [DomainReloadingCleanup]
//	    // ReSharper disable once UnusedMember.Local
//	    private static void OnDomainReload()
//	    {
//		    _appInfoJson = null;
//	    }
//#endif
    }
}
