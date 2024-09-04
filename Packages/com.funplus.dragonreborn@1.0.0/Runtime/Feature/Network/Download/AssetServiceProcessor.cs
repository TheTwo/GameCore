//#define HTTP_LOADER_SERVICE_PROCESSOR_LOG_ENABLED

using System;
using System.Collections.Generic;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public class AssetServiceProcessor : BaseServiceProcessor<AssetServiceRequest, AssetServiceResponse>
	{
		public const int DefaultMaxRequestCount = 10;
		
		private int _maxRequestCount = DefaultMaxRequestCount;
		private long _index;

		private readonly List<AssetServiceRequest> _allHighPriorityRequestList = new List<AssetServiceRequest>();
        private readonly List<AssetServiceRequest> _allProcessingRequest = new List<AssetServiceRequest>();
        private readonly AssetNetworkAgent _networkAgent;

        public AssetServiceProcessor()
        {
            _networkAgent = new AssetNetworkAgent();
        }

		public void SetAssetDownloadQueue(int total)
		{
			_maxRequestCount = total;
		}
		
		public bool HasRequest(string url, string savePath)
        {
	        // ReSharper disable once ConvertToLocalFunction
	        Predicate<AssetServiceRequest> match = (request) => string.CompareOrdinal(request.DownloadUrl, url) == 0 && string.CompareOrdinal(request.SavePath, savePath) == 0;
	        lock (_allHighPriorityRequestList)
	        {
		        if (_allProcessingRequest.FindLastIndex(match) >= 0 || _allHighPriorityRequestList.FindLastIndex(match) >=0)
			        return true;
	        }
	        return false;
        }

		public override void InsertRequest(AssetServiceRequest request)
		{
			InsertHighPriorityRequest(request);
		}

		public void InsertHighPriorityRequest(AssetServiceRequest request)
		{
			DebugLog("{0} priority {1} add to high request list",
				request.DownloadUrl.Substring(request.DownloadUrl.LastIndexOf("/", StringComparison.Ordinal) + 1),
				request.Priority);
		
			request.Index = _index++;
			lock(_allHighPriorityRequestList)
			{
				AssetServiceRequest finalRequest = null;
				
				// already exist in processing queue
				var sameRequest = _allProcessingRequest.Find(p => p.DownloadUrl == request.DownloadUrl && p.SavePath == request.SavePath);
				if(sameRequest != null)
				{
					// update priority
					if (request.Priority >= sameRequest.Priority)
					{
						sameRequest.Index = request.Index;
						sameRequest.Priority = request.Priority;
					}
					sameRequest.Callback += request.Callback;
					sameRequest.SetVersionCallback = request.SetVersionCallback;
					if (request.OnProgress != null)
					{
						sameRequest.OnProgress += request.OnProgress;
					}

					finalRequest = sameRequest;
				}

				// already exist in high priority queue
				if(finalRequest == null)
				{
					foreach(var requestInQueue in _allHighPriorityRequestList)
					{
						if(requestInQueue.DownloadUrl == request.DownloadUrl &&
							requestInQueue.SavePath == request.SavePath)
						{
							if (request.Priority >= requestInQueue.Priority)
							{
								requestInQueue.Index = request.Index;
								requestInQueue.Priority = request.Priority;
							}
							requestInQueue.Callback += request.Callback;
							requestInQueue.SetVersionCallback = request.SetVersionCallback;
							if (request.OnProgress != null)
							{
								requestInQueue.OnProgress += request.OnProgress;
							}

							finalRequest = requestInQueue;
						}
					}
				}

				// append to high priority queue
				if(finalRequest == null)
				{
					_allHighPriorityRequestList.Add(request);
				}
			}
		}
			
		public override void Tick (float delta)
		{
			lock (_allProcessingRequest)
			{
				foreach(AssetServiceRequest assetServiceRequest in _allProcessingRequest)
				{
					assetServiceRequest.HttpRequester.Tick(delta);
				}
			}
            
            _networkAgent.Update(delta);

			TickRequestQueue();

			TickResponseQueue();
		}

		private void TickRequestQueue()
		{
			lock (_allProcessingRequest)
			{
				if(_allProcessingRequest.Count < _maxRequestCount)
				{
					lock(_allHighPriorityRequestList)
					{
						while((_allHighPriorityRequestList.Count > 0) &&  _allProcessingRequest.Count < _maxRequestCount)
						{
							AssetServiceRequest assetServiceRequest = null;

							if(_allHighPriorityRequestList.Count > 0)
							{
								_allHighPriorityRequestList.Sort(PriorityComparison);
								assetServiceRequest = _allHighPriorityRequestList[_allHighPriorityRequestList.Count -1];
								_allHighPriorityRequestList.RemoveAt(_allHighPriorityRequestList.Count -1);

								DebugLog("{0} priority {1} begin request list",
									assetServiceRequest.DownloadUrl.Substring(
										assetServiceRequest.DownloadUrl.LastIndexOf("/", StringComparison.Ordinal) + 1),
									assetServiceRequest.Priority);
							}

							if(assetServiceRequest != null && !assetServiceRequest.CancelMark)
							{
								_allProcessingRequest.Add(assetServiceRequest);

								var httpRequester = new HttpRequester(_networkAgent);
								DebugLog("~~ download asset " + assetServiceRequest.HttpRequestData.Url + " " +
								         assetServiceRequest.HttpRequestData.Method + " " + assetServiceRequest.Priority);
                            
								httpRequester.DoRequest(assetServiceRequest.HttpRequestData, _requestStrategy, true,
									// ReSharper disable once UnusedParameter.Local
									delegate(object httpResponseData, long responseCode)
									{
										OnResponse(assetServiceRequest, httpResponseData as HttpResponseData);
									}, assetServiceRequest.OnProgress);

								assetServiceRequest.HttpRequester = httpRequester;
							}
						}

						//DebugLog ("REQUEST COUNT: " + _allProcessingRequest.Count);
					}
				}
			}
		}

		// high at last, for new high request will be first process
		private static int PriorityComparison(AssetServiceRequest x, AssetServiceRequest y)
		{
			if (x.Priority == y.Priority)
			{
				return x.Index.CompareTo(y.Index);
			}
			
			return x.Priority.CompareTo(y.Priority);
		}

		private void TickResponseQueue()
		{
			while(_responseQueue.TryDequeue(out var workload))
			{
				AssetServiceResponse assetServiceResponse = workload.response;

				AssetServiceRequest assetServiceRequest = assetServiceResponse.AssetServiceRequest;

				bool removed;
				lock (_allProcessingRequest)
				{
					removed = _allProcessingRequest.Remove(assetServiceRequest);
				}
				if (removed)
				{
					var httpResponseOk = assetServiceResponse.HttpResponseData is { ResponseCode: HttpResponseCode.OK };

					DebugLog("Asset Download Result : {0}, from {1} to {2}",
						httpResponseOk,
						assetServiceResponse.AssetServiceRequest.DownloadUrl,
						assetServiceResponse.AssetServiceRequest.SavePath);

					assetServiceRequest.SetVersionCallback?.Invoke(httpResponseOk, assetServiceResponse.HttpResponseData, assetServiceRequest);
					assetServiceRequest.Callback?.Invoke(httpResponseOk, assetServiceResponse.HttpResponseData);

					if (!httpResponseOk && assetServiceRequest.RestartOnError)
					{
						//NLogger.Error($"Download Asset {assetServiceRequest.DownloadUrl} failed. Need Restart Game!!!");

						if (FrameworkInterfaceManager.QueryFrameInterface<IRestartGameInterface>(out var handle))
						{
							handle.TriggerLuaRestartGame("Warning", $"Download Asset {assetServiceRequest.DownloadUrl} failed. Need Restart Game!!!");
						}
						else
						{
							UnityEngine.Debug.LogErrorFormat("IRestartGameInterface not register in FrameworkInterfaceManager");
						}

						//throw new Exception($"Download Asset {assetServiceRequest.DownloadUrl} failed. Need Restart Game!!!");
					}
				}
				else
				{
					DebugLog("ignore loader response");
				}
			}
        }

		private void OnResponse(AssetServiceRequest assetServiceRequest, HttpResponseData httpResponseData)
		{
            InsertResponse(new AssetServiceResponse(assetServiceRequest, httpResponseData));
		}

		[System.Diagnostics.Conditional("HTTP_LOADER_SERVICE_PROCESSOR_LOG_ENABLED")]
		[System.Diagnostics.CodeAnalysis.SuppressMessage("ReSharper", "UnusedParameter.Local")]
		private static void DebugLog(string log, params object[] parameters)
		{
			#if HTTP_LOADER_SERVICE_PROCESSOR_LOG_ENABLED
			NLogger.LogChannel("AssetServiceProcessor", log, parameters);
			#endif
		}

		public override void Reset()
		{
			base.Reset();
			_maxRequestCount = DefaultMaxRequestCount;
			lock (_allHighPriorityRequestList)
			{
				_allHighPriorityRequestList.Clear();
			}

			lock (_allProcessingRequest)
			{
				_allProcessingRequest.Clear();	
			}

            _networkAgent.Reset();
        }
	}
}

