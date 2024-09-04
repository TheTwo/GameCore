namespace DragonReborn
{
    public class AssetNetworkAgent : INetworkAgent
    {
        private readonly AssetHttpApi _httpApi = new AssetHttpApi();
        
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