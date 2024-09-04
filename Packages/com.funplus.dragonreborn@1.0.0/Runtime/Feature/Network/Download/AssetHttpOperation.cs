using UnityEngine.Networking;

namespace DragonReborn
{
    public class AssetHttpOperation : IHttpAsyncOperation
    {
        private readonly UnityWebRequestAsyncOperation _operation;

        public AssetHttpOperation(UnityWebRequestAsyncOperation operation)
        {
            _operation = operation;
        }

        public UnityWebRequest Request => _operation.webRequest;

        public bool IsDone => _operation.isDone;

        public byte Priority
        {
            get => (byte) _operation.priority;
            set => _operation.priority = value;
        }

        public float Progress => _operation.webRequest.downloadProgress;

		public ulong DownloadedBytes => _operation.webRequest.downloadedBytes;

		private ulong? _contentLength;

		public ulong ContentLength
		{
			get
			{
				if (_contentLength.HasValue)
					return _contentLength.Value;

				if (ulong.TryParse(_operation.webRequest.GetResponseHeader("Content-Length"), out var length))
				{
					_contentLength = length;
					return length;
				}

				return 0;
			}
		}

		public bool IsAborted { get; private set; }

        public void Abort()
        {
            try
            {
                IsAborted = true;
                _operation.webRequest.Abort();
            }
            catch
            {
                // 如果请求应经调用过Dispose()，会抛ArgumentNullException
            }
        }
    }
}
