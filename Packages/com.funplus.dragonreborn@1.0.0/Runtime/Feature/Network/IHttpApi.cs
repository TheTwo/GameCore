using System;

namespace DragonReborn
{
	public interface IHttpAsyncOperation
	{
		void Abort();
	}

	public interface IHttpApi
	{
		IHttpAsyncOperation Send(HttpRequestData requestData, Action<HttpResponseData> callback, Action<ulong, ulong> onProgress = null);
		void Tick(float dt);
		void Reset();
	}
}

