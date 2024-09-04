using System;
using System.Collections.Generic;

namespace DragonReborn
{
	public class SimpleHttpManager : Singleton<SimpleHttpManager>, IManager, ITicker
	{
		private readonly SimpleHttpProcessor _httpProcessor = new SimpleHttpProcessor();
		public void OnGameInitialize(object configParam)
		{
			_httpProcessor.SetRequestStrategy(new BaseRequestStrategy());
		}

		public void Reset()
		{
			_httpProcessor.Reset();
		}

		public void Tick(float dt)
		{
			_httpProcessor.Tick(dt);
		}

		public void SendHttpGet(string url, Dictionary<string, object> param, Action<bool, HttpResponseData> callback)
		{
			string body = null;
			if (param != null)
			{
				body = DataUtils.ToJson(param);
			}

			_httpProcessor.InsertRequest(new SimpleHttpRequest(url, HttpMethod.Get, body, callback));
		}

		public void SendHttpPost(string url, Dictionary<string, object> param, Action<bool, HttpResponseData> callback)
		{
			string body = null;
			if (param != null)
			{
				body = DataUtils.ToJson(param);
			}

			_httpProcessor.InsertRequest(new SimpleHttpRequest(url, HttpMethod.Post, body, callback));
		}

		public void OnLowMemory()
		{

		}
	}
}
