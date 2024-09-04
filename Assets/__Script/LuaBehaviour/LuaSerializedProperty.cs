using System;

namespace DragonReborn
{
    [Serializable]
    public class LuaSerializedProperty<T>
    {
        public string key;
        public T value;
    }
}