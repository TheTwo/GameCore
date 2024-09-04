namespace DragonReborn
{
	public class SimpleHttpResponse
	{
		public SimpleHttpResponse(SimpleHttpRequest httpRequest, HttpResponseData httpResponseData)
		{
			HttpRequest = httpRequest;
			HttpResponseData = httpResponseData;
		}

		public SimpleHttpRequest HttpRequest;
		public HttpResponseData HttpResponseData;
	}
}
