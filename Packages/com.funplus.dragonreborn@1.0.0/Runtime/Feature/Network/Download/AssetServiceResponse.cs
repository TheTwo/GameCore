using System;

namespace DragonReborn
{
	public class AssetServiceResponse
	{
		public AssetServiceResponse (AssetServiceRequest assetServiceRequest, HttpResponseData httpResponseData)
		{
			AssetServiceRequest = assetServiceRequest;
			HttpResponseData = httpResponseData;
		}

		public AssetServiceRequest AssetServiceRequest;
		public HttpResponseData HttpResponseData;
	}
}

