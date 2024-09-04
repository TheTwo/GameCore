using System;

using System.Collections.Generic;
using System.Diagnostics;

namespace DragonReborn
{
    public class HttpRequester
	{
        public interface IRequestStrategy
		{
            bool IsConnected { get; }
			void GetRequestTimeOut(HttpRequester requester, out bool needRetry, out float timeOut, out bool reusePrevious);
			bool IsRetryImmediately(HttpResponseData responseData, out float timeout);
            bool NeedRetryOnServerError();
            bool NeedCrcCheck();
		}

		private bool _working;
		private IRequestStrategy _requestStrategy;
		private float _deltaTime;
		private float _maxWaitTime;
		private int _alreadyTryTimes;
		private int _validRequestNumber;
        private bool _needRetry;
		private ulong _lastDownloadBytes;
        private HttpRequestData _httpRequestData;
        private Action<object, long> _callback;
		private Action<ulong, ulong> _onProgress;
        
        private readonly INetworkAgent _networkAgent;
        private readonly bool _useRtmAgent;
        private readonly List<IHttpAsyncOperation> _asyncOperations = new List<IHttpAsyncOperation>();
        
        public HttpRequester(INetworkAgent networkAgent)
		{
            _networkAgent = networkAgent;
        }

		public int AlreadyTryTimes => _alreadyTryTimes;

		private void Reset()
        {
			_working = false;

            AbortOperations();
        }

        private void AbortOperations()
        {
            foreach (var operation in _asyncOperations)
            {
	            try
	            {
		            operation.Abort();
	            }
	            catch
	            {
		            // ignored
	            }
            }

            _asyncOperations.Clear();
        }

        private IHttpApi HttpApi => _networkAgent.Http;

        public void DoRequest(HttpRequestData httpRequestData, IRequestStrategy requestStrategy, bool retry,
            Action<object, long> callback, Action<ulong, ulong> onProgress = null)
        {
            _httpRequestData = httpRequestData;
            _requestStrategy = requestStrategy;
            _callback = callback;
			_onProgress = onProgress;
			_deltaTime = 0;
            _maxWaitTime = 0;
            _alreadyTryTimes = 0;
			_lastDownloadBytes = 0;
			_needRetry = retry;
            _requestStrategy.GetRequestTimeOut(this, out _, out var timeOut, out _);

            DoRequestInternal(timeOut, false, false);
        }

        public void Tick(float delta)
        {
	        if (_working)
	        {
		        _deltaTime += delta;

		        var isTimeOut = _deltaTime >= _maxWaitTime;
		        if (isTimeOut)
		        {
			        if (_needRetry)
			        {
				        if (_requestStrategy.IsConnected)
				        {
					        _requestStrategy.GetRequestTimeOut(this, out var needRetry, out var timeOut,
						        out var reusePrevious);
					        if (needRetry)
					        {
						        DoRequestInternal(timeOut, reusePrevious, true);
					        }
					        else
					        {
						        OnResponse(_validRequestNumber, null);
					        }
				        }
			        }
			        else
			        {
				        OnResponse(_validRequestNumber, null);
			        }
		        }
	        }
        }

        private void DoRequestInternal(float timeOut, bool reusePrevious, bool isRetry)
		{
			var stopWatch = new Stopwatch();
			stopWatch.Start();

			_working = true;
			_alreadyTryTimes ++;
            _deltaTime = 0;
			_lastDownloadBytes = 0;
			_maxWaitTime = timeOut;

			if(!reusePrevious)
			{
				_validRequestNumber++;
			}

			var requestNumber = _validRequestNumber;

			if (isRetry)
		    {
		        _httpRequestData.HeadersDict["Client-Retry"] = "1";
		    }

		    if (_httpRequestData.CrcCheckValue > 0 && !_requestStrategy.NeedCrcCheck())
		    {
			    _httpRequestData.CrcCheckValue = 0;
		    }

		    _httpRequestData.IsRetry = isRetry;

		    var operation = HttpApi.Send(_httpRequestData, delegate(HttpResponseData httpResponseData)
			{
				stopWatch.Stop();

				if(_httpRequestData.RequestContent != null)
				{
				}

                if (_requestStrategy != null)
                {
	                if(httpResponseData.ResponseCode == HttpResponseCode.OK)
	                {
		                OnResponse(requestNumber, httpResponseData);
	                }
	                else
	                {
		                var isServerError = httpResponseData.ResponseCode / 500 == 1;
		                if (isServerError && !_requestStrategy.NeedRetryOnServerError())
		                {
			                _callback.Invoke (httpResponseData, httpResponseData.ResponseCode);

			                Reset();
		                }
		                else
		                {
			                // make it retry next tick, or wait until time out
			                if (_requestStrategy.IsRetryImmediately(httpResponseData, out var timeout))
			                {
				                _deltaTime = 0;
								_lastDownloadBytes = 0;
				                _maxWaitTime = timeout;
			                }
		                }
	                }
                }
                
			}, (downloadBytes, allBytes) => 
			{
				// 如果下载进度有变化，重置超时计时器
				if (_lastDownloadBytes != downloadBytes)
				{
					_lastDownloadBytes = downloadBytes;
					_deltaTime = 0;
				}
				
				_onProgress?.Invoke(downloadBytes, allBytes);
			});

            if (operation != null)
            {
                _asyncOperations.Add(operation);
            }
		}

        private void OnResponse(int requestNumber, HttpResponseData httpResponseData)
		{
			if(!_working)
			{
				return;
			}

			if(requestNumber != _validRequestNumber)
			{
				return;
			}

			var responseCode = httpResponseData?.ResponseCode ?? 0;

			if (_requestStrategy != null)
			{
				DoResponse(httpResponseData, responseCode);
			}
		}

		/// do response
		private void DoResponse(object protocol, long responseCode)
		{
			_working = false;
			_callback.Invoke (protocol, responseCode);

			Reset();
		}
	}
}

