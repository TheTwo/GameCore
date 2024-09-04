namespace DragonReborn
{
	public class SimpleNetworkAgent : INetworkAgent
	{
		private readonly IHttpApi _httpApi = new SimpleHttpApi();

		public IHttpApi Http => _httpApi;

		public void Update(float delta)
		{
			_httpApi.Tick(delta);
		}

		public void Reset()
		{
			_httpApi.Reset();
		}
	}
}
