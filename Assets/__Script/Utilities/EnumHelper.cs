using System;
using System.Reflection;

// ReSharper disable once CheckNamespace
namespace DragonReborn.Utilities
{
    public static class EnumHelper
    {
        private static readonly Type ObsoleteAttributeType = typeof(ObsoleteAttribute);
    
        public static bool IsEnumValueObsolete(Enum value)
        {
            return IsEnumValueObsolete(value, value.GetType());
        }

        public static bool IsEnumValueObsolete(Enum value, Type enumType)
        {
            foreach (var field in enumType.GetFields(BindingFlags.Public | BindingFlags.Static))
            {
                if (Equals(field.GetValue(null), value) && !field.IsDefined(ObsoleteAttributeType))
                    return false;
            }
            return true;
        }
    }
}