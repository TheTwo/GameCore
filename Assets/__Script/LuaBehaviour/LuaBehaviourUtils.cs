using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Reflection;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using UnityEngine;
using XLua;
using Object = UnityEngine.Object;

namespace DragonReborn
{
    public static class LuaBehaviourUtils
    {
        private class IgnorePropertiesResolver : DefaultContractResolver
        {
            protected override JsonProperty CreateProperty(MemberInfo member, MemberSerialization memberSerialization)
            {
                var property = base.CreateProperty(member, memberSerialization);
                if (member is PropertyInfo)
                {
                    property.ShouldSerialize = x => false;
                }
                return property;
            }    
        }

        public static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
        {
            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
            ContractResolver = new IgnorePropertiesResolver()
        };
        
        public static object GetDefaultValue(LuaSchemaSlot slot)
        {
            var type = slot.Type;

            if (slot.DefaultValue != null && type.IsInstanceOfType(slot.DefaultValue))
            {
                return slot.DefaultValue;
            }

            if (slot.SlotType == LuaSchemaSlotType.Enum)
            {
                if (slot.Enum.Items.Count > 0)
                {
                    return slot.Enum.Items[0].Value;
                }

                return 0;
            }
            
            return type.IsValueType ? Activator.CreateInstance(type) : null;
        }
        
        public static object ChangeType(object source, Type type)
        {
            try
            {
                if (type.IsPrimitive)
                {
                    return Convert.ChangeType(source, type);
                }

                if (type == typeof(string))
                {
                    return source?.ToString();
                }
                
                if (type.IsEnum)
                {
                    if (!(source is string))
                    {
                        return Enum.ToObject(type, source);
                    }
                    
                    var converter = TypeDescriptor.GetConverter(type);
                    return converter.ConvertFrom(source);
                }

                if (type.IsValueType)
                {
                    return Convert.ChangeType(source, type);
                }
            }
            catch
            {
                return null;
            }

            return null;
        }
        
        public static void GetSchemaSlotTree(LuaTable schemaRecords, List<LuaSchemaSlot> oldSlots,
            List<LuaSchemaSlot> newSlots, string schemaName)
        {
            var duplicate = new HashSet<string>();
            schemaRecords?.ForEach(delegate(int i, LuaTable table)
            {
                table.Get(1, out string slotName);
                var oldSlot = GetSlotByName(oldSlots, slotName);
                var newSlot = oldSlot != null
                    ? new LuaSchemaSlot {Name = slotName, FoldOut = oldSlot.FoldOut}
                    : new LuaSchemaSlot {Name = slotName};

                if (!duplicate.Contains(newSlot.Name))
                {
#if UNITY_EDITOR
					string slotLabel = "";
					try
					{
						table.Get(3, out slotLabel);
					}
					catch
					{
						slotLabel = ToMeaningfulName(newSlot.Name);
					}
					finally
					{
						if (string.IsNullOrEmpty(slotLabel))
						{
							slotLabel = ToMeaningfulName(newSlot.Name);
						}
					}
					newSlot.MangledName = slotLabel;
#endif
                    table.Get(2, out newSlot.Type);
                    if (newSlot.Type == null)
                    {
                        table.Get(2, out LuaTable nestedRecords);
                        if (nestedRecords != null)
                        {
                            if (!TryParseEnum(newSlot, nestedRecords))
                            {
                                newSlot.SlotType = LuaSchemaSlotType.Table;
                                GetSchemaSlotTree(nestedRecords, oldSlot?.Children, newSlot.Children, newSlot.Name);
                            }
                        }
                    }
                    else if(newSlot.Type.IsGenericType && newSlot.Type.GetGenericTypeDefinition() == typeof(List<>) && newSlot.Type.GetGenericArguments()[0].IsSubclassOf(typeof(Object)))
                    {
                        newSlot.SlotType = LuaSchemaSlotType.List;
                    }
                    else
                    {
                        newSlot.SlotType = newSlot.Type.IsSubclassOf(typeof(Object))
                            ? LuaSchemaSlotType.Object
                            : LuaSchemaSlotType.Value;
                    }
                    
                    if (newSlot.SlotType == LuaSchemaSlotType.Value || newSlot.SlotType == LuaSchemaSlotType.Enum)
                    {
                        table.Get(3, out newSlot.DefaultValue);
                        newSlot.DefaultValue = ChangeType(newSlot.DefaultValue, newSlot.Type);
                    }

                    if (newSlot.SlotType != LuaSchemaSlotType.Unknown)
                    {
                        newSlots.Add(newSlot);
                        duplicate.Add(newSlot.Name);    
                    }
                }
                else
                {
                    Debug.LogError($"Duplicated Slot Name: Schema ={schemaName}, Name = {newSlot.Name}");
                }
            });
        }

        private static bool TryParseEnum(LuaSchemaSlot newSlot, LuaTable nestedRecords)
        {
            var meta = nestedRecords.GetMetaTable();
            if (meta == null)
            {
                return false;
            }

            if (!meta.ContainsKey("__enum") || !meta.ContainsKey("__define"))
            {
                return false;
            }
            
            meta.Get("__enum", out bool isEnum);
            if (!isEnum)
            {
                return false;
            }

            newSlot.Enum = new LuaEnum();
            meta.Get("__define", out LuaTable define);
            define?.ForEach(delegate(int i, LuaTable item)
            {
                item.Get(1, out string key);
                item.Get(2, out int value);
                newSlot.Enum.Items.Add(new KeyValuePair<string, int>(key, value));
            });
            
            newSlot.SlotType = LuaSchemaSlotType.Enum;
            newSlot.Type = typeof(int);
            return true;
        }

        private static LuaSchemaSlot GetSlotByName(IEnumerable<LuaSchemaSlot> slots, string slotName)
        {
            return slots?.FirstOrDefault(slot => slot.Name == slotName);
        }
        
        private static string ToMeaningfulName(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return value;
            }

            var spacedWords = value.Select(delegate(char c, int i)
            {
                if (i == 0)
                {
                    return "" + char.ToUpper(c);
                }

                return c == char.ToUpper(c) ? " " + c : c.ToString();
            }).ToArray();

            return string.Join("", spacedWords).Trim();
        }

        public static void Populate(LuaTable instance, LuaSchemaSlot treeRoot, LuaSerializedObject serializedObject)
        {
            foreach (var slot in treeRoot.Children)
            {
                switch (slot.SlotType)
                {
                    case LuaSchemaSlotType.Value:
                    {
                        LoadValue(instance, slot, serializedObject.values);
                        break;
                    }
            
                    case LuaSchemaSlotType.Object:
                    {
                        LoadObject(instance, slot, serializedObject.objects);
                        break;
                    }
                    
                    case LuaSchemaSlotType.Table:
                    {
                        LoadTable(instance, slot, serializedObject.children);
                        break;
                    }

                    case LuaSchemaSlotType.Enum:
                    {
                        LoadEnum(instance, slot, serializedObject.values);
                        break;
                    }

                    case LuaSchemaSlotType.List:
                    {
                        LoadList(instance, slot, serializedObject.objectArray);
                        break;
                    }
                }
            }
        }

        private static void LoadObject(LuaTable instance, LuaSchemaSlot slot,
            IEnumerable<LuaSerializedProperty<Object>> objects)
        {
            var o = GetSerializedProperty(slot.Name, objects);
            if (o != null)
            {
                instance?.Set(slot.Name, o.value);
            }
        }

        private static void LoadValue(LuaTable instance, LuaSchemaSlot slot,
            IEnumerable<LuaSerializedProperty<string>> values)
        {
            object value;
            var o = GetSerializedProperty(slot.Name, values);
            if (o == null)
            {
                value = GetDefaultValue(slot);
            }
            else
            {
                value = string.IsNullOrEmpty(o.value)
                    ? GetDefaultValue(slot)
                    : JsonConvert.DeserializeObject(o.value, slot.Type, Settings);
            }

            instance?.Set(slot.Name, value);
        }

        private static void LoadEnum(LuaTable instance, LuaSchemaSlot slot, IEnumerable<LuaSerializedProperty<string>> values)
        {
            object value;
            var o = GetSerializedProperty(slot.Name, values);
            if (o == null)
            {
                value = GetDefaultValue(slot);
            }
            else
            {
                value = string.IsNullOrEmpty(o.value)
                    ? GetDefaultValue(slot)
                    : JsonConvert.DeserializeObject(o.value, typeof(int), Settings);
            }

            instance?.Set(slot.Name, value);
        }
        
        private static LuaSerializedProperty<T> GetSerializedProperty<T>(string name, IEnumerable<LuaSerializedProperty<T>> values)
        {
            foreach (var o in values)
            {
                if (name == o.key)
                {
                    return o;
                }
            }

            return null;
        }
        
        private static void LoadTable(LuaTable instance, LuaSchemaSlot slot,
            IEnumerable<LuaSerializedObject> objects)
        {
            foreach (var o in objects)
            {
                if (slot.Name == o.key)
                {
                    var table = ScriptEngine.Instance.LuaInstance.NewTable();
                    if (table != null)
                    {
                        Populate(table, slot, o);
                        instance?.Set(slot.Name, table);    
                    }
                    break;
                }
            }
        }

        private static void LoadList(LuaTable instance, LuaSchemaSlot slot,
            IEnumerable<LuaSerializedProperty<List<Object>>> objects)
        {
            foreach (var o in objects)
            {
                if (slot.Name == o.key)
                {
                    instance?.Set(slot.Name, o.value);
                    return;
                }
            }
        }
    }
}
