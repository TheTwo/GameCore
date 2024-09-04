namespace DragonReborn.AssetTool
{
    public class AssetLoaderProxy
    {
        private AssetBundleLoader _assetBundleLoader;
        private ResourcesLoader _resourcesLoader;

#if UNITY_EDITOR
        private AssetDatabaseLoader _assetDatabaseLoader;
#endif
        
        public AssetBundleLoader AssetBundleLoader => _assetBundleLoader;

        public ResourcesLoader ResourcesLoader => _resourcesLoader;

#if UNITY_EDITOR
        public AssetDatabaseLoader AssetDatabaseLoader => _assetDatabaseLoader;
#endif

        public void Initialize()
        {
            _assetBundleLoader = new AssetBundleLoader();
            _assetBundleLoader.Initialize();
            
            _resourcesLoader = new ResourcesLoader();
            _resourcesLoader.Initialize();

#if UNITY_EDITOR
            _assetDatabaseLoader = new AssetDatabaseLoader();
            _assetDatabaseLoader.Initialize();
#endif
        }

        public void Reset()
        {
            _assetBundleLoader.Reset();
            _resourcesLoader.Reset();
#if UNITY_EDITOR
            _assetDatabaseLoader.Reset();
#endif
        }

		public bool IsAssetExist(string assetIndex)
		{
			if (AssetManager.Instance.IsBundleMode())
			{
				if (_assetBundleLoader.AssetExist(assetIndex))
				{
					return true;
				}

				if (_resourcesLoader.AssetExist(assetIndex))
				{
					return true;
				}
			}
			else
			{
#if UNITY_EDITOR
				if (_assetDatabaseLoader.AssetExist(assetIndex))
				{
					return true;
				}
#endif

				if (_resourcesLoader.AssetExist(assetIndex))
				{
					return true;
				}
			}

			return false;
		}
	}
}
