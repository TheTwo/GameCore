using System;
using System.Collections.Generic;

namespace DragonReborn
{
    public enum LuaSchemaSlotType
    {
        Unknown,
        Object,
        Value,
        Table,
        List,
        Enum,
    }
    
    public class LuaSchemaSlot
    {
        public string Name;
        public LuaSchemaSlotType SlotType = LuaSchemaSlotType.Unknown;
        public Type Type;
        public string MangledName;
        public readonly List<LuaSchemaSlot> Children = new List<LuaSchemaSlot>(); // Table的属性
        public object DefaultValue;
        public LuaEnum Enum;
        public bool FoldOut; //仅Editor使用

        public LuaSchemaSlot GetSlot(string name)
        {
	        foreach (var child in Children)
	        {
		        if (child.Name == name) return child;
	        }
	        return default;
        }
    }
}