
using System.Linq;
using UnityEditor;

namespace DragonReborn.AssetTool.Editor
{
	public partial class CustomAssetPostprocessor
	{
		private static readonly string[] LoopActionNames = 
		{
			"idle",
			"stand",
			"loop",
			"run",
			"walk",
			"stun",
			"loop",
			"transport",
			"lift",
			"construct",
			"craft",
			"gather",
			"fell",
			"mine",
			"fire_jin",
			"fire_yuan",
			"water_jin",
			"water_yuan",
			"sleep",
			"dine"
		};
		
		void OnPreprocessAnimation()
		{
			if (!ModelNeedProcess())
				return;
			
			ModelImporter modelImporter = assetImporter as ModelImporter;
			if (modelImporter == null || modelImporter.defaultClipAnimations == null)
			{
				return;
			}
			
			var clipAnimations = modelImporter.defaultClipAnimations;
			foreach (var clip in clipAnimations)
			{
				// 检查动画片段的名字是否包含预定的循环动作名
				if (LoopActionNames.Any(loopName => clip.name.ToLowerInvariant().Contains(loopName)))
				{
					// 如果包含，设置该片段为循环
					clip.loopTime = true;
				}
			}
			
			modelImporter.clipAnimations = clipAnimations;
		}
		
	}
}
