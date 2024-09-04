using System;
using System.Collections.Generic;
using System.Text;

namespace DragonReborn
{
	public class SimpleHttpRequest
	{
		public SimpleHttpRequest(string url, HttpMethod httpMethod, string body, Action<bool, HttpResponseData> callback)
		{
			Url = url;
			HttpMethod= httpMethod;
			Callback += callback;

			if (!string.IsNullOrEmpty(body))
			{
				RequestContent = Encoding.UTF8.GetBytes(body);
			}
		}

		public bool CancelMark = false;
		public HttpRequester HttpRequester;
		public string Url;
		public HttpMethod HttpMethod;
		public byte[] RequestContent;
		public Action<bool, HttpResponseData> Callback;

		private static readonly Dictionary<string, string> _headerForAsset = new Dictionary<string, string>
		{
			{
				"Content-Type",
				"application/json"
			}
		};

		private HttpRequestData _httpRequestData;
		public HttpRequestData HttpRequestData
		{
			get
			{
				if (_httpRequestData == null)
				{
					_httpRequestData = new HttpRequestData
					{
						Url = Url,
						Method = HttpMethod,
						HeadersDict = _headerForAsset,
						RequestContent = RequestContent
					};
				}

				return _httpRequestData;
			}
		}
	}
}
