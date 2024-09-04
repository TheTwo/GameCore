using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using UnityEngine;

namespace DragonReborn
{
	public class IOUtils
	{
		// ReSharper disable InconsistentNaming
		private const string LOG_CHANEL = "IOUtils";

		private static readonly string PersistentDataPath = Application.persistentDataPath;
		private static readonly string StreamingAssetsPath = Application.streamingAssetsPath;

		private static readonly HashSet<string> _documentAssetMap = new(StringComparer.Ordinal);
		private static readonly HashSet<string> _packageAssetMap = new(StringComparer.Ordinal);
		public static HashSet<string> DocumentAssetMap => _documentAssetMap;

		private static bool _documentAssetMapReady;
		// 表示是否已经扫描过StreamingAssets下的GameAsset目录
		private static bool _packageAssetMapReady;

		private static Dictionary<string, string> _documentPathMap = new(StringComparer.Ordinal);
		private static Dictionary<string, string> _packagePathMap = new(StringComparer.Ordinal);

		public const string ENCRYPT_TAG = "version1";
		private static int _hasEncryptTag = -1;
		private const string StreamingAssetsListFile = "asset_list.txt";
		// ReSharper restore InconsistentNaming
		
		public static bool HasEncryptTag()
		{
			if (_hasEncryptTag == -1)
			{
				_hasEncryptTag = HaveGameAssetInPackage(ENCRYPT_TAG) ? 1 : 0;
			}

			return _hasEncryptTag == 1;
		}
		
		private const int DeferWriteIntervalMs = 200;

		private static Thread _deferWriteWorker;
		private static volatile bool _deferWriteWorkerRunning;
		private static readonly Dictionary<string, ArraySegment<byte>> DeferWriteMap = new(StringComparer.Ordinal);
		private static readonly List<string> DeferWriteMapTempKey = new();
		private static readonly AutoResetEvent DeferWritePendingEvent = new(false);
		private static readonly ManualResetEvent DeferDirtyEvent= new(false);

		[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
		private static void BeginDoDeferWriteLoop()
		{
			_deferWriteWorker = new Thread(DoDeferWriteLoop)
			{
				IsBackground = true
			};
			_deferWriteWorkerRunning = true;
			_deferWriteWorker.Start();
		}

#if !UNITY_EDITOR && UNITY_ANDROID
		private static bool _noUnzip = true;
		private static AndroidJavaObject _unityActivity = null;
		private static AndroidJavaObject unityActivity
		{
			get
			{
				if (_unityActivity != null)
					return _unityActivity;

				_unityActivity = new AndroidJavaClass("com.unity3d.player.UnityPlayer").GetStatic<AndroidJavaObject>("currentActivity");
				if (_unityActivity == null)
				{
					NLogger.ErrorChannel(LOG_CHANEL, "Initial unityActivity Failed.");
				}
				return _unityActivity;
			}
		}

		private static AndroidJavaClass _androidIOUtils = null;

		private static AndroidJavaObject androidIOUtils
		{
			get
			{
				if (_androidIOUtils != null)
					return _androidIOUtils;

				_androidIOUtils = new AndroidJavaClass("com.kingsgroup.io.IOUtils");
				if (_androidIOUtils == null)
				{
					NLogger.ErrorChannel(LOG_CHANEL, "Initial androidIOUtils Failed.");
				}
				return _androidIOUtils;
			}
		}
		
		public static bool AndroidHaveAssets(string relativePath)
		{
			return androidIOUtils.CallStatic<bool>("AssetExist", unityActivity, relativePath);;
		}

		public static void AndroidGetAllFilesInApk(string relativePath)
		{
			_packageAssetMap.Clear();
			var useListContent = false;
			if (AndroidHaveAssets(StreamingAssetsListFile))
			{
				try
				{
					var contentBytes = ReadStreamingAsset_NoUnzip(StreamingAssetsListFile);
					var text = Encoding.UTF8.GetString(contentBytes);
					using var textReader = new StringReader(text);
					var line = textReader.ReadLine();
					while (line != null)
					{
						_packageAssetMap.Add(line.Trim('\n', '\r'));
                        line = textReader.ReadLine();
					}
					useListContent = true;
				}
				catch (Exception ex)
				{
					Debug.LogException(ex);
				}
			}

			if (!useListContent)
			{
				using var result = androidIOUtils.CallStatic<AndroidJavaObject>("GetAllFilesInApk", unityActivity, relativePath);
				if (result != null)
				{
					int size = result.Call<int>("size");
					for (int i = 0; i < size; i++)
					{
						using var obj = result.Call<AndroidJavaObject>("get", i);
						string path = obj.Call<string>("toString");
						_packageAssetMap.Add(path);
					}
				}
			}
			_packageAssetMapReady = true;
			// NLogger.ErrorChannel("IOUtils", $"packageAssetMapReady, collect {_packageAssetMap.Count}");
		}
		
		public static bool UnzipAssets_Threaded(string fromRelativePath, string toRelativePath)
		{
			var attachRet = AndroidJNI.AttachCurrentThread();

			if (attachRet != 0)
			{
				NLogger.ErrorChannel(LOG_CHANEL,"UnzipAssets AndroidJNI.AttachCurrentThread() Failed！");
				return false;
			}
			
			string externalFullPath = AssetPath.Combine(PersistentDataPath, toRelativePath);
			
			NLogger.ErrorChannel(LOG_CHANEL, $"UnzipAssets_Threaded {fromRelativePath}, {externalFullPath}");

			var fileInfo = new FileInfo(externalFullPath);
			if (fileInfo.Directory != null && !fileInfo.Directory.Exists)
			{
				fileInfo.Directory.Create( );
			}

			bool unzipResult = androidIOUtils.CallStatic<bool>("UnzipAssets", unityActivity, fromRelativePath, externalFullPath);
    
			var detachRet = AndroidJNI.DetachCurrentThread();
			
			if (detachRet != 0)
			{
				NLogger.ErrorChannel(LOG_CHANEL,"UnzipAssets AndroidJNI.DetachCurrentThread() Failed！");
				return false;
			}
			
			return unzipResult;

		}

		public static bool UnzipAsset(string fromRelativePath, string toRelativePath)
		{
			string externalFullPath = AssetPath.Combine(PersistentDataPath, toRelativePath);

			var fileInfo = new FileInfo(externalFullPath);
				if (!fileInfo.Directory.Exists)
			{
				fileInfo.Directory.Create( );
			}
					
			bool unzipResult = androidIOUtils.CallStatic<bool>("UnzipAssets", unityActivity, fromRelativePath, externalFullPath);
			return unzipResult;
		}

		private static byte[] ReadStreamingAsset_NoUnzip(string relativePath)
		{
			var stream = new APKFileSystemStream(relativePath);
			var fileLength = (int) stream.Length;
			if (fileLength <= 0)
			{
				return null;
			}

			var buffer = new byte[fileLength];
			if (stream.Read(buffer, fileLength) != fileLength)
			{
				return null;
			}

			return buffer;
		}

		private static byte[] AndroidReadStreamingAsset(string relativePath)
		{
			if (_noUnzip)
			{
				return ReadStreamingAsset_NoUnzip(relativePath);
			}
			
			if (UnzipAsset(relativePath, relativePath))
			{
				return ReadGameAsset(relativePath);
			}
			else
			{
				return null;
			}
		}
#endif

		public static bool TryUnzipGameAssets(string relativePath)
		{
			IOAccessRecorder.RecordFile(relativePath);
#if !UNITY_EDITOR && UNITY_ANDROID
			// 包外已经有了
			if (HaveGameAssetInDocument(relativePath))
			{
				return false;
			}

			// 包内没有，报错
			if (!HaveGameAssetInPackage(relativePath))
			{
				NLogger.Error($"try unzip {relativePath} but no GameAsset found in package");
				return false;
			}

			// 解压到包外
			if (!UnzipAsset(relativePath, relativePath))
			{
				NLogger.Error($"unzip {relativePath} failure");
				return false;
			}
#endif
			return true;
		}
		
		public static void ProcessStreamingAssetList(IEnumerable<string> fromVersionDefineFiles)
		{
			if (null == fromVersionDefineFiles) return;
			_packageAssetMap.UnionWith(fromVersionDefineFiles);
		}
		
		public static void ProcessBundleAssetList(string bundlePath)
		{
			_documentAssetMapReady = false;
			try
			{	
				_documentAssetMap.Clear();
				string externalFullPath = GetGameAssetPathInDocument(bundlePath);
				// 未经任何下载的完整大包不会有GameAssets目录
				if (Directory.Exists(externalFullPath))
				{
					var files = Directory.GetFiles(externalFullPath, "*.*", SearchOption.AllDirectories);
					foreach (var path in files)
					{
						var relativePath = AssetPath.GetRelativePath(PersistentDataPath, path);//path.Substring(path.IndexOf(PersistentDataPath, StringComparison.Ordinal));
						_documentAssetMap.Add(relativePath);
					}

					// NLogger.ErrorChannel("IOUtils", $"documentBundleAssetMapReady, collect {_documentAssetMap.Count}");
				}
				// 不论目录是否存在，都已经建立过资源索引
				_documentAssetMapReady = true;
			}
			catch (Exception e)
			{
				Debug.LogException(e);
				_documentAssetMapReady = false;
				// NLogger.ErrorChannel(LOG_CHANEL, "ProcessBundleAssetList documentBundleAssetMap Exception:{0}", e.ToString());
			}

			
#if UNITY_EDITOR || !UNITY_ANDROID
			_packageAssetMapReady = false;
			try
			{
				_packageAssetMap.Clear();
				var useListContent = false;
				if (HaveGameAssetInPackage(StreamingAssetsListFile))
				{
					var contentBytes = ReadGameAsset(StreamingAssetsListFile);
					var text = Encoding.UTF8.GetString(contentBytes);
					using var textReader = new StringReader(text);
					var line = textReader.ReadLine();
					while (line != null)
					{
						_packageAssetMap.Add(line.Trim('\n', '\r'));
						line = textReader.ReadLine();
					}
					useListContent = true;
				}

				if (!useListContent)
				{
					var fullPath = GetGameAssetPathInPackage(bundlePath);
					if (Directory.Exists(fullPath))
					{
						var files = Directory.GetFiles(fullPath, "*.*", SearchOption.AllDirectories);
						foreach (var path in files)
						{
							var relativePath = AssetPath.GetRelativePath(StreamingAssetsPath, path);//path.Substring(path.IndexOf(StreamingAssetsPath, StringComparison.Ordinal));
							_packageAssetMap.Add(relativePath);
						}
					}
				}
				// 不论目录是否存在，都已经建立过资源索引
				_packageAssetMapReady = true;
			}
			catch (Exception e)
			{
				_packageAssetMapReady = false;
				NLogger.Error("ProcessBundleAssetList packageBundleAssetMap Exception:{0}", e.ToString());
			}
#else
			AndroidGetAllFilesInApk(bundlePath);
#endif
		}

		/// <summary>
		/// 不使用缓存的判断逻辑， 或包内根级的路径
		/// </summary>
		/// <param name="relativePath"></param>
		/// <returns></returns>
		public static bool HaveGameAssetInPackage(string relativePath)
		{
#if !UNITY_EDITOR && UNITY_ANDROID
			return AndroidHaveAssets(relativePath);
#else
			
			var internalFullPath = GetGameAssetPathInPackage(relativePath);
			return File.Exists(internalFullPath);
#endif
		}
		
		public static bool HaveBundleAssetInPackage(string relativePath)
		{
			bool ret;
			if (_packageAssetMapReady && _packageAssetMap != null)
			{
				ret = _packageAssetMap.Contains(relativePath);
			}
			else
			{
				ret = HaveGameAssetInPackage(relativePath);
			}
			return ret;
		}
		
		public static bool HaveBundleAssetInDocument(string relativePath)
		{
			bool ret;
			if (_documentAssetMapReady && _documentAssetMap != null)
			{
				ret = _documentAssetMap.Contains(relativePath);
			}
			else
			{
				// NLogger.ErrorChannel("IOUtils", $"HaveBundleAssetInDocument[{_documentAssetMapReady}][{_documentAssetMap?.Count ?? 0}] : {relativePath}");
				ret = HaveGameAssetInDocument(relativePath);
			}
			return ret;
		}

		public static void UpdateDocumentBundleAssetMap(string relativePath)
		{
			if (_documentAssetMap != null && !_documentAssetMap.Contains(relativePath))
			{
				_documentAssetMap.Add(relativePath);
			}
		}
		
		public static void DeleteDocumentBundleAssetMap(string relativePath)
		{
			if (_documentAssetMap != null && _documentAssetMap.Contains(relativePath))
			{
				_documentAssetMap.Remove(relativePath);
			}
		}

		public static bool HaveGameAssetInDocument(string relativePath)
		{
			var externalFullPath = GetGameAssetPathInDocument(relativePath);
			lock (DeferWriteMap)
			{
				if (DeferWriteMap.Remove(externalFullPath, out var writeData))
				{
					return DoWriteDeferBytes(externalFullPath, writeData);
				}
			}
			return File.Exists(externalFullPath);
		}

		public static bool HaveGameAsset(string relativePath, bool externalStorageOnly = false)
		{
			if (HaveGameAssetInDocument(relativePath))
			{
				return true;
			}

			if (externalStorageOnly)
			{
				return false;
			}

			return HaveGameAssetInPackage(relativePath);
		}

		public static int DeleteGameAssetByPattern(string baseFolder, string searchPattern, SearchOption searchOption)
		{
			var processCount = 0;
			var fullPath = AssetPath.Combine(PersistentDataPath, baseFolder);
			if (!Directory.Exists(fullPath)) return processCount;
			var files = Directory.EnumerateFiles(fullPath, searchPattern, searchOption);
			foreach (var file in files)
			{
				var relPath = AssetPath.GetRelativePath(baseFolder, file);
				if (DeleteGameAsset(relPath))
				{
					++processCount;
				}
			}
			return processCount;
		}

		public static bool DeleteGameAsset(string relativePath)
		{
			if (_documentAssetMapReady)
			{
				_documentAssetMap.Remove(relativePath);
			}
			var externalFullPath = GetGameAssetPathInDocument(relativePath);
			lock (DeferWriteMap)
			{
				DeferWriteMap.Remove(externalFullPath);
			}
			if (File.Exists(externalFullPath))
			{
				try
				{
					File.Delete(externalFullPath);
					DeleteDocumentBundleAssetMap(relativePath);
				}
				// https://stackoverflow.com/questions/329355/cannot-delete-directory-with-directory-deletepath-true
				catch(Exception e)
				{
					NLogger.Error($"DeleteGameAsset {externalFullPath} with Exception: " + e.Message);
				}

				return true;
			}

			return false;
		}

		public static bool DeleteGameAssetDir(string relativePath)
		{
			if (_documentAssetMapReady)
			{
				_documentAssetMap.RemoveWhere(x => x.StartsWith(relativePath));
			}
			var externalFullPath = GetGameAssetPathInDocument(relativePath);
			lock (DeferWriteMap)
			{
				DeferWriteMapTempKey.Clear();
				DeferWriteMapTempKey.AddRange(DeferWriteMap.Keys);
				foreach (var key in DeferWriteMapTempKey)
				{
					if (key.StartsWith(externalFullPath) 
					    && (key.Length == externalFullPath.Length 
					    || key[externalFullPath.Length] == '/'))
                    {
                        DeferWriteMap.Remove(key);
                    }
				}
			}
			if (Directory.Exists(externalFullPath))
			{
				try
				{
					Directory.Delete(externalFullPath, true);
				}
				// https://stackoverflow.com/questions/329355/cannot-delete-directory-with-directory-deletepath-true
				catch
				{
					Thread.Sleep(0); 
					Directory.Delete(externalFullPath, true);
				}

				return true;
			}

			return false;
		}

		public static byte[] ReadStreamingAsset(string relativePath)
		{
			IOAccessRecorder.RecordFile(relativePath);
#if !UNITY_EDITOR && UNITY_ANDROID	
			return AndroidReadStreamingAsset(relativePath);
#else
	        string absolutePath = GetGameAssetPathInPackage(relativePath);

	        if (File.Exists(absolutePath))
	        {
		        return File.ReadAllBytes(absolutePath);
	        }

	        NLogger.ErrorChannel(LOG_CHANEL, $"Read streaming assets error, can not find file: {absolutePath}");
	        return null;
#endif
        }

        public static string ReadStreamingAssetAsText(string relativePath, bool decode = false)
        {
	        var allBytes = ReadStreamingAsset(relativePath);
	        if (allBytes != null)
	        {
		        if (decode)
		        {
			        if (!SafetyUtils.CodeByteBuffer(allBytes))
			        {
				        return string.Empty;
			        }
		        }
		        return Encoding.UTF8.GetString(allBytes);
	        }

	        return string.Empty;
        }
        
        public static byte[] ReadGameAsset(string relativePath)
        {
	        IOAccessRecorder.RecordFile(relativePath);
	        var externalFullPath = GetGameAssetPathInDocument(relativePath);
	        lock (DeferWriteMap)
	        {
		        if (DeferWriteMap.Remove(externalFullPath, out var deferWriteBytes))
                {
	                if (DoWriteDeferBytes(externalFullPath, deferWriteBytes))
	                {
		                return deferWriteBytes.ToArray();
	                }
                }
	        }

	        if (File.Exists(externalFullPath))
	        {
		        return File.ReadAllBytes(externalFullPath);
	        }

	        return ReadStreamingAsset(relativePath);
        }

        public static string ReadGameAssetAsText(string relativePath, bool decode = false)
		{
			var allBytes = ReadGameAsset(relativePath);
			if (allBytes != null)
			{
				if (decode)
				{
					if (!SafetyUtils.CodeByteBuffer(allBytes))
					{
						return string.Empty;
					}
				}
				
				return Encoding.UTF8.GetString(allBytes);
			}

			return string.Empty;
		}
        
        public static bool WriteGameAsset(string relativePath, string context, bool encode = false)
        {
	        var bytes = Encoding.UTF8.GetBytes(context);
	        if (encode)
	        {
		        if (!SafetyUtils.CodeByteBuffer(bytes))
		        {
			        return false;
		        }
	        }

	        return WriteGameAsset(relativePath, bytes);
        }

		public static bool WriteGameAsset(string relativePath, byte[] bytes)
		{
			return WriteGameAsset(relativePath, bytes, bytes.Length);
		}
        
        public static bool WriteGameAsset(string relativePath, byte[] bytes, int length)
        {
            try
            {
	            var externalFullPath = GetGameAssetPathInDocument(relativePath);
	            lock (DeferWriteMap)
	            {
		            DeferWriteMap.Remove(externalFullPath);
	            }
	            var fileInfo = new FileInfo(externalFullPath);
                var directoryName = fileInfo.DirectoryName;
                if (string.IsNullOrEmpty(directoryName))
                {
	                return false;
                }
                
                if (!Directory.Exists(directoryName))
                {
                    Directory.CreateDirectory(directoryName);
                }

                using (var stream = fileInfo.Create())
                {
                    stream.Write(bytes, 0, length);
                    stream.Flush();
                    stream.Close();
                }

                NLogger.LogChannel(LOG_CHANEL, "WriteGameAsset({0})", externalFullPath);
                return true;
            }
            catch
            {
                // EventManager.Instance.TriggerEvent(new IOExceptionEvent(IOExceptionEvent.Exception.Write));
                return false;
            }
        }

        public static string GetGameAssetPath(string relativePath)
        {
	        var pathInDocument = GetGameAssetPathInDocument(relativePath);
	        if (File.Exists(pathInDocument))
	        {
		        return pathInDocument;
	        }

	        return GetGameAssetPathInPackage(relativePath);
        }

		public static string GetGameAssetPathInDocument(string relativePath)
		{
			if (_documentPathMap.ContainsKey(relativePath))
			{
				return _documentPathMap[relativePath];
			}

			var fullpath = AssetPath.Combine(PersistentDataPath, relativePath);
			_documentPathMap.Add(relativePath, fullpath);
			return fullpath;
		}

		public static string GetGameAssetPathInPackage(string relativePath)
		{
			if (_packagePathMap.ContainsKey(relativePath))
			{
				return _packagePathMap[relativePath];
			}

			var fullpath = AssetPath.Combine(StreamingAssetsPath, relativePath);
			_packagePathMap.Add(relativePath, fullpath);
			return fullpath;
		}
		
		public static bool WriteGameAssetDefer(string relativePath, string context, bool encode = false)
        {
            var bytes = Encoding.UTF8.GetBytes(context);
            if (encode)
            {
                if (!SafetyUtils.CodeByteBuffer(bytes))
                {
                    return false;
                }
            }

            return WriteGameAssetDefer(relativePath, bytes);
        }
		
		public static bool WriteGameAssetDefer(string relativePath, byte[] bytes)
		{
			return WriteGameAssetDefer(relativePath, bytes, bytes.Length);
		}
		
		public static bool WriteGameAssetDefer(string relativePath, byte[] bytes, int length)
		{
			if (!_deferWriteWorkerRunning)
			{
				return WriteGameAsset(relativePath, bytes, length);
			}

			var externalFullPath = GetGameAssetPathInDocument(relativePath);
			var directoryName = Path.GetDirectoryName(externalFullPath);
			if (string.IsNullOrEmpty(directoryName)) return false;
			lock (DeferWriteMap)
			{
				DeferWriteMap[externalFullPath] = new ArraySegment<byte>(bytes, 0, length);
				DeferDirtyEvent.Set();
			}
			NLogger.LogChannel(LOG_CHANEL, "WriteGameAssetDefer({0})", externalFullPath);
			return true;
		}

		private static void DoDeferWriteLoop()
		{
			try
			{
				while (_deferWriteWorkerRunning)
				{
					DeferDirtyEvent.WaitOne();
					DeferWritePendingEvent.WaitOne(DeferWriteIntervalMs);
					lock (DeferWriteMap)
					{
						if (DeferWriteMap.Count > 0)
						{
							DeferWriteMapTempKey.Clear();
							DeferWriteMapTempKey.AddRange(DeferWriteMap.Keys);
							foreach (var externalFullPath in DeferWriteMapTempKey)
							{
								DeferWriteMap.Remove(externalFullPath, out var writeData);
								DoWriteDeferBytes(externalFullPath, writeData);
							}
						}
						DeferDirtyEvent.Reset();
					}
				}
			}
			catch (OperationCanceledException)
			{
				// ignore
			}
			catch (ThreadAbortException)
			{
				// ignore
			}
		}

		private static bool DoWriteDeferBytes(string externalFullPath, ArraySegment<byte> bytes)
		{
			try
			{
				var fileInfo = new FileInfo(externalFullPath);
				var directoryName = fileInfo.DirectoryName;
				if (string.IsNullOrEmpty(directoryName))
				{
					return false;
				}
                
				if (!Directory.Exists(directoryName))
				{
					Directory.CreateDirectory(directoryName);
				}

				using (var stream = fileInfo.Create())
				{
					stream.Write(bytes);
					stream.Flush();
					stream.Close();
				}

				NLogger.LogChannel(LOG_CHANEL, "WriteGameAsset({0})", externalFullPath);
				return true;
			}
			catch
			{
				// EventManager.Instance.TriggerEvent(new IOExceptionEvent(IOExceptionEvent.Exception.Write));
				return false;
			}
		}

		public static void OnApplicationQuit()
		{
			_deferWriteWorkerRunning = false;
			DeferDirtyEvent.Set();
			DeferWritePendingEvent.Set();
			_deferWriteWorker.Join();
			_deferWriteWorker = null;
		}
	}	
}
