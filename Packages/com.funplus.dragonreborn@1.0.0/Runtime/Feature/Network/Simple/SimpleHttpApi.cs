using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine.Networking;

namespace DragonReborn
{
	internal class SimpleHttpApi : IHttpApi
	{
		private struct Response
		{
			public Action<HttpResponseData> Callback;
			public bool IsRetry;
		}

		private readonly Dictionary<SimpleHttpOperation, Response> _operations = new();
		private readonly List<SimpleHttpOperation> _removals = new List<SimpleHttpOperation>();

		public IHttpAsyncOperation Send(HttpRequestData requestData, Action<HttpResponseData> callback, Action<ulong, ulong> onProgress = null)
		{
			var request = new UnityWebRequest { url = requestData.Url };

			switch (requestData.Method)
			{
				case HttpMethod.Get:
					request.method = UnityWebRequest.kHttpVerbGET;
					break;

				case HttpMethod.Post:
					request.method = UnityWebRequest.kHttpVerbPOST;
					break;
			}

			request.uploadHandler = new UploadHandlerRaw(requestData.RequestContent);
			request.disposeUploadHandlerOnDispose = true;

			request.downloadHandler = new DownloadHandlerBuffer();
			request.disposeDownloadHandlerOnDispose = true;

			foreach (var header in requestData.HeadersDict)
			{
				request.SetRequestHeader(header.Key, header.Value);
			}

			var operation = new SimpleHttpOperation(request.SendWebRequest());
			_operations.Add(operation, new Response
			{
				Callback = callback,
				IsRetry = requestData.IsRetry
			});

			if (requestData.IsRetry)
			{
				NLogger.Error("[SimpleHttpApi]Send Retry: URL = {0}", requestData.Url);
			}

			return operation;
		}

		public void Tick(float dt)
		{
			_removals.Clear();

			foreach (var pair in _operations)
			{
				var operation = pair.Key;
				var response = pair.Value;

				var error = operation.Request.error;
				if (!string.IsNullOrEmpty(error))
				{
					var responseData = new HttpResponseData
					{
						ResponseCode = HttpResponseCode.REQUEST_ERROR,
						ResponseText = operation.Request.error,
						Url = operation.Request.url,
					};

					if (response.IsRetry)
					{
						NLogger.Error($"[SimpleHttpApi] Update operation Request error: URL = {responseData.Url}, responseCode={responseData.ResponseCode}, error ={error}");
					}

					response.Callback?.Invoke(responseData);
					operation.Request.Dispose();
					_removals.Add(operation);
				}
				else if (operation.IsDone)
				{
					var responseData = new HttpResponseData
					{
						ResponseCode = operation.Request.responseCode,
						ResponseText = operation.Request.downloadHandler.text,
						Url = operation.Request.url
					};

					if (response.IsRetry)
					{
						NLogger.Error($"[SimpleHttpApi] Update operation IsDone: URL = {responseData.Url}, responseCode={responseData.ResponseCode}");
					}

					response.Callback?.Invoke(responseData);
					operation.Request.Dispose();
					_removals.Add(operation);
				}
				else if (operation.IsAborted)
				{
					_removals.Add(operation);
				}
			}

			foreach (var operation in _removals)
			{
				_operations.Remove(operation);
			}
		}

		public void Reset()
		{
			foreach (var pair in _operations)
			{
				var operation = pair.Key;
				if (!operation.IsDone)
				{
					operation.Abort();
				}

				operation.Request.Dispose();
			}

			_operations.Clear();
			_removals.Clear();
		}
	}
}
