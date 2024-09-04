using System;
using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn
{
    [Serializable]
    public class LuaSerializedObject
    {
        public string key;
        public List<LuaSerializedProperty<string>> values;
        public List<LuaSerializedProperty<UnityEngine.Object>> objects;
        [SerializeReference] public List<LuaSerializedObject> children;
        public List<LuaSerializedProperty<List<UnityEngine.Object>>> objectArray;
    }
}