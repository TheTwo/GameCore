
// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public interface ISpriteReference
    { }
    
    public static class SpriteReferenceExtension
    {
        public static T EnsureSpriteReference<T>(this UnityEngine.GameObject go) where T : UnityEngine.Component, ISpriteReference
        {
            if (!go) return default;
            var reference = go.GetComponent<ISpriteReference>();
            switch (reference)
            {
                case T t:
                    return t;
                case UnityEngine.Object obj:
                    UnityEngine.Object.Destroy(obj);
                    break;
            }
            return go.AddComponent<T>();
        }
    }
}