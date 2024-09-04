using System.Collections.Generic;

namespace DragonReborn
{
	public enum HttpMethod
	{
		Post,
		Get,
	}

    public class HttpRequestData
	{
		public string Url;
        public string SavePath;
        public uint CrcCheckValue;
		public HttpMethod Method = HttpMethod.Post;
		public byte[] RequestContent;
		public Dictionary<string, string> HeadersDict = new Dictionary<string, string>();
		public bool IsRetry;
	}
}

