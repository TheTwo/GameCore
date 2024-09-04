using System;
using System.Collections.Generic;
using System.IO;

namespace DragonReborn.AssetTool.Editor
{
	public static class TextureSizeRuleFactory
	{
        private static readonly List<ITextureSizeRule> Rules = new List<ITextureSizeRule>
        {
	        // 顺序调整
	        new UltraHighResRule(),
	        new MedResNameRule(),
	        new VeryLowRule(),
        	new LowResRule(),
	        new SceneMedResRule(),
	        new HighResRule(),
	        // 放最后兜底都是512
	        new MedResRule()
        };

        public static int GetModelTextureMaxSize(string assetPath)
        {
        	foreach (var rule in Rules)
        	{
        		if (rule.IsMatch(assetPath))
		        {
        			return rule.GetSize();
        		}
        	}
        	return -1;
        }
	}
	
	public interface ITextureSizeRule
	{
		bool IsMatch(string assetPath);
		int GetSize();
	}
	
	public class UltraHighResRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => Path.GetFileNameWithoutExtension(assetPath).EndsWith("_HighRes");
		public int GetSize() => 2048;
	}
	
	public class MedResNameRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => Path.GetFileNameWithoutExtension(assetPath).EndsWith("_MedRes");
		public int GetSize() => 1024;
	}
	
	public class HighResRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => assetPath.ToLower().Contains("/lod0/", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("_lod0_", StringComparison.OrdinalIgnoreCase);
		public int GetSize() => 1024;
	}
	
	// 防止场景出现1024
	public class SceneMedResRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => assetPath.Contains("Assets/__Art/StaticResources/City", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("Assets/__Art/StaticResources/Common", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("Assets/__Art/StaticResources/ControlMap", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("Assets/__Art/StaticResources/Environment", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("Assets/__Art/StaticResources/KingdomMap", StringComparison.OrdinalIgnoreCase);
		                                         
		public int GetSize() => 512;
	}
	
	public class MedResRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => assetPath.Contains("Assets/__Art/StaticResources", StringComparison.OrdinalIgnoreCase);
		                                         
		public int GetSize() => 512;
	}
    
	public class LowResRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => assetPath.ToLower().Contains("/lod1/", StringComparison.OrdinalIgnoreCase) || 
		                                         assetPath.ToLower().Contains("/gpu/", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("_lod1", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("_lod01", StringComparison.OrdinalIgnoreCase);
		public int GetSize() => 256;
	}
    
	public class VeryLowRule : ITextureSizeRule
	{
		public bool IsMatch(string assetPath) => assetPath.ToLower().Contains("/lod2/", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("_lod2", StringComparison.OrdinalIgnoreCase) ||
		                                         assetPath.Contains("_lod02", StringComparison.OrdinalIgnoreCase);
		public int GetSize() => 128;
	}
}
