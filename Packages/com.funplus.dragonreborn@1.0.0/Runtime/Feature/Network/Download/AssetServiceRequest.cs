using System;
using System.Collections.Generic;
using System.IO;

namespace DragonReborn
{
	public class AssetServiceRequest
	{
		public AssetServiceRequest(string downloadUrl, string savePath, Action<bool, HttpResponseData> callback, Action<ulong, ulong> onProgress = null,
			int priority = (int)DownloadPriority.Normal, uint crcCheckValue = 0, long index = 0, bool restartOnError = false,
			Action<bool, HttpResponseData, AssetServiceRequest> setVersionCallback = null)
		{
			DownloadUrl = downloadUrl;
			SavePath = savePath;
			Callback += callback;
			//设置版本信息的回调独立且只替换 不+=, Callback 留给业务用
			SetVersionCallback = setVersionCallback;

			if (onProgress != null)
			{
				OnProgress += onProgress;
			}
			
			Priority = priority;
			CrcCheckValue = crcCheckValue;
			Index = index;
			RestartOnError = restartOnError;
		}

		public bool CancelMark = false;
		public string DownloadUrl;
		public string SavePath;
		public HttpRequester HttpRequester;
        public Action<bool, HttpResponseData> Callback;
        public Action<bool,HttpResponseData, AssetServiceRequest> SetVersionCallback;
		public Action<ulong, ulong> OnProgress;
        public int Priority;
        public long Index;
        public uint CrcCheckValue;
		public bool RestartOnError;
	
		private static readonly Dictionary<string,string> _headerForAsset = new Dictionary<string, string>
		{ 
			{
				"Content-Type",
				"application/octet-stream"
			}
		};

        public static bool IsValid(string savePath)
        {
            var localName = Path.GetFileNameWithoutExtension(savePath);
            return !string.IsNullOrEmpty(localName);
        }

        private HttpRequestData _httpRequestData;
		public HttpRequestData HttpRequestData
		{
			get
			{
				if(_httpRequestData == null)
				{
					_httpRequestData = new HttpRequestData
					{ 
						Url = DownloadUrl,
                        SavePath = SavePath,
                        CrcCheckValue = CrcCheckValue,
						Method = HttpMethod.Get,
						HeadersDict = _headerForAsset,
						RequestContent = null
					};
				}

				return _httpRequestData;
			}
		}
			
	}
}

