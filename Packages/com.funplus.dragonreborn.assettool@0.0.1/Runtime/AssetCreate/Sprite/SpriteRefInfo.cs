using System;
using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
    [Serializable]
    internal struct SpriteRefInfoDiff
    {
        public string Key;
        public DiffField<int> Count;

        public bool AnyDiff()
        {
            return Count.Changed;
        }
    }
    
    [Serializable]
    internal struct SpriteRefInfo
    {
        public string SpriteName;
        public int Count;
        
        public static implicit operator SpriteRefInfo(KeyValuePair<string, int> kv)
        {
            return new SpriteRefInfo()
            {
                SpriteName = kv.Key,
                Count = kv.Value,
            };
        }
        
        public static SpriteRefInfoDiff operator -(in SpriteRefInfo a, in SpriteRefInfo b)
        {
            return new SpriteRefInfoDiff()
            {
                Key = a.SpriteName,
                Count = new DiffField<int>(a.Count - b.Count, a.Count != b.Count),
            };
        }
    }
}