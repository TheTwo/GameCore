using System;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
	public class GenerateLuaHintOutputPathAttribute : Attribute
	{
		public GenerateLuaHintOutputPathAttribute(string nameIndexFormat, string splitter = "_", bool skipZero = true, int lineLimit = 5000)
		{
			NameIndexFormat = nameIndexFormat;
			Splitter = splitter;
			SkipZero = skipZero;
			LineLimit = lineLimit;
		}

		public readonly string NameIndexFormat;
		public readonly string Splitter;
		public readonly bool SkipZero;
		public readonly int LineLimit;
	}
    
    [AttributeUsage(AttributeTargets.Method)]
    public class GenerateLuaHintFilterForTypeAttribute : Attribute
    {
        
    }

    [AttributeUsage(AttributeTargets.Method)]
    public class GenerateLuaHintFilterForMethodAttribute : Attribute
    {
        
    }
    
    [AttributeUsage(AttributeTargets.Method)]
    public class GenerateLuaHintFilterForFieldAttribute : Attribute
    {
        
    }
    
    [AttributeUsage(AttributeTargets.Method)]
    public class GenerateLuaHintFilterForPropertyAttribute : Attribute
    {
        
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
    public class ParameterRefLikeTypesForHintAttribute : Attribute
    {
    }
}