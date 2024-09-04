
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public class SimpleHttpProcessor : BaseServiceProcessor<SimpleHttpRequest, SimpleHttpResponse>
	{
		private SimpleHttpRequest _processingRequest;
		private readonly INetworkAgent _networkAgent;

		public SimpleHttpProcessor()
		{
			_networkAgent = new SimpleNetworkAgent();
		}

		public override void Tick(float delta)
		{
			_processingRequest?.HttpRequester.Tick(delta);

			_networkAgent.Update(delta);

			TickRequestQueue();

			TickResponseQueue();
		}

		private void TickRequestQueue()
		{
			if (_processingRequest != null || !_requestQueue.TryDequeue(out var req)) return;
			_processingRequest = req;
			var httpRequester = new HttpRequester(_networkAgent);
			httpRequester.DoRequest(_processingRequest.HttpRequestData, _requestStrategy, true,
				// ReSharper disable once UnusedParameter.Local
				delegate (object httpResponseData, long responseCode)
				{
					OnResponse(_processingRequest, httpResponseData as HttpResponseData);
				});
			_processingRequest.HttpRequester = httpRequester;
		}

		private void TickResponseQueue()
		{
			lock (_responseQueue)
			{
				while (_responseQueue.TryDequeue(out var workload))
				{
					var response = workload.response;
					var request = response.HttpRequest;
					if (_processingRequest != request) continue;
					_processingRequest = null;
					var httpResponseOk = response.HttpResponseData is { ResponseCode: HttpResponseCode.OK };
					request.Callback?.Invoke(httpResponseOk, response.HttpResponseData);
				}
			}
		}

		private void OnResponse(SimpleHttpRequest request, HttpResponseData httpResponseData)
		{
			InsertResponse(new SimpleHttpResponse(request, httpResponseData));
		}

		public override void Reset()
		{
			base.Reset();

			_processingRequest = null;

			_networkAgent.Reset();
		}
	}
}
