using System.IO;

namespace DragonReborn.AssetTool
{
    /// <summary>
    /// 描述asset和bundle的关系
    /// 即当前的asset在哪个bundle里
    /// </summary>
    public class BundleAssetData
    {
        private string _assetName;
        private string _bundleName;
        private bool _isScene;
        
        public BundleAssetData(string assetIndex, string bundleName, bool isScene = false)
        {
            _bundleName = bundleName;
            _assetName = assetIndex;
            _isScene = isScene;
        }

        public string AssetName => _assetName;

        public bool IsScene => _isScene;

        public string BundleName
        {
            get => _bundleName;
            set => _bundleName = value;
        }
    }
}
