using System;

namespace DragonReborn.AssetTool
{
    public class AssetHandle //: BaseRefCounter
    {
        /// <summary>
        /// 不同的AssetHandle，可能持有同一份AssetCache
        /// 每一个持有，AssetCache引用计数+1
        /// </summary>
        private AssetCache _cache;
        
        //内部管理的唯一标示
        public string cacheIndex;
        
        public void SetAssetCache(AssetCache cache)
        {
            _cache = cache;
        }
        
        public UnityEngine.Object Asset 
        {
            get 
            {
                if(_cache != null)
                {
                    return _cache.Asset;
                }
                else
                {
                    return null;
                }
            }
        }

        public bool IsValid => _cache != null && _cache.Asset;
		public string AssetName => cacheIndex;
        public Action<bool, AssetHandle> callback;
    }
}
