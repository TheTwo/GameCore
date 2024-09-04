using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class TextureImporterContext
	{
		public TextureImporter TextureImporter { get; private set; }
		public HashSet<string> Labels { get; private set; }

		public TextureImporterContext(TextureImporter textureImporter, string[] labels)
		{
			TextureImporter = textureImporter;
			Labels = labels != null ? new HashSet<string>(labels, StringComparer.OrdinalIgnoreCase) : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		}

		public bool HasLabel(string label)
		{
			return Labels.Contains(label);
		}
		
	}
	public partial class CustomAssetPostprocessor
	{
		private const string UI_ATLAS_PATH = "Assets/__UI/_Resources/UIAtlas/Sprites";
		private const string UI_SINGLE_TEXTURE_PATH = "Assets/__UI/_Resources/Texture";
		private const string UI_ATLAS_MASK_FOLDER = "Assets/__UI/_Resources/UIAtlas/Sprites/ui_mask";
		private const string ART_VFX_PATH = "Assets/__Art/StaticResources/Vfx/Textures";
		private const string UI_VFX_PATH = "Assets/__UI/StaticResources/VFX/Texture";
		private const string ART_CONTROLMAP_PATH = "Assets/__Art/StaticResources/ControlMap/";
		// 加入处理标签
		private const string LABEL_2048 = "T_2048";
		private const string LABEL_1024 = "T_1024";
		private const string LABEL_R16 = "T_R16";
		private const string LABEL_Read = "T_Read";
		private const string LABEL_MipMapOff = "T_MipMapOff";
		private const string LABEL_REBA32 = "T_RGBA32";

		private static readonly string[] LimitTextureRootPath = 
		{
			"Assets/__Art",
			"Assets/__UI",
			"Assets/__Scene"
		};
		
		private bool TextureNeedProcess()
		{
			return CheckIsSomePath(assetPath, LimitTextureRootPath);
		}
		
		/// <summary>
		/// This lets you set up default values for the import settings.
		/// Use this callback if you want to change the compression format of the texture.
		/// </summary>
		void OnPreprocessTexture()
		{
			if (!TextureNeedProcess())
				return;
			
			var textureImporter = (TextureImporter)assetImporter;
			// 处理UI纹理
			ProcessUITextures(textureImporter);
			// 获取标签
			var labels = VfxTools.GetdAssetLabels(assetPath);
			var context = new TextureImporterContext(textureImporter, labels);
			
			// 先处理纹理读写
			PreProcessTextureReadable(context);
			if (assetPath.Contains("__DontFixMe")) return;
			
			// 处理mipmap设置
			ProcessMipmapSettings(context);
			// 处理FilterMode.Bilinear
			PreProcessCommonSettings(context);
			// 处理纹理大小
			PreprocessTextureSize(context);
			// 设置纹理格式
			SetTextureFormat(context);
		
		}
		
		#region SetEnableMipmap
		void ProcessMipmapSettings(TextureImporterContext context)
		{
			// 开启mipmap streaming
			// 开启mipmap后，只有2的n次幂的图才能用压缩格式
			if (ShouldEnableMipmap(context.TextureImporter) && !context.HasLabel(LABEL_MipMapOff))
			{
				context.TextureImporter.mipmapEnabled = true;
				context.TextureImporter.streamingMipmaps = ShouldEnableTextureStreaming();
				context.TextureImporter.ignoreMipmapLimit = false;
				context.TextureImporter.mipmapFilter = TextureImporterMipFilter.BoxFilter;
				context.TextureImporter.mipMapsPreserveCoverage = false;
				context.TextureImporter.borderMipmap = false;
				context.TextureImporter.fadeout = false;
			}
			else
			{
				context.TextureImporter.mipmapEnabled = false;
				context.TextureImporter.streamingMipmaps = false;
			}
		}
		
		private bool ShouldEnableMipmap(TextureImporter textureImporter)
		{
			if (textureImporter.textureType == TextureImporterType.Default ||
			    textureImporter.textureType == TextureImporterType.NormalMap ||
			    textureImporter.textureType == TextureImporterType.Lightmap ||
			    textureImporter.textureType == TextureImporterType.DirectionalLightmap)
			{
				return true;
			}

			return false;
		}
		#endregion
		
		#region SetUI
		void ProcessUITextures(TextureImporter textureImporter)
		{
			// 根据路径中的信息处理UI纹理
			ProcessUITextures(textureImporter, !assetPath.Contains(UI_ATLAS_PATH), SpriteMeshType.FullRect);
			ProcessUITextures(textureImporter, !assetPath.Contains(UI_SINGLE_TEXTURE_PATH), SpriteMeshType.Tight);
		}
		
		public void ProcessUITextures(TextureImporter textureImporter, bool condition, SpriteMeshType spriteMeshType)
		{
			if (condition)
			{
				return;
			}

			textureImporter.textureType = TextureImporterType.Sprite;
			textureImporter.mipmapEnabled = false;
			textureImporter.spriteImportMode = SpriteImportMode.Single;

			var settings = new TextureImporterSettings();
			textureImporter.ReadTextureSettings(settings);
			settings.spriteMeshType = spriteMeshType;
			settings.spriteGenerateFallbackPhysicsShape = false;
			textureImporter.SetTextureSettings(settings);
		}
		#endregion
		
		#region SetFilterMode
		private void PreProcessCommonSettings(TextureImporterContext context)
		{
			context.TextureImporter.anisoLevel = 1; // 关闭各项异性过滤
			if (context.TextureImporter.filterMode == FilterMode.Trilinear)
			{
				context.TextureImporter.filterMode = FilterMode.Bilinear;
			}
		}
		#endregion
		
		#region SetTextureReadable
		// 添加控制读写
		private void PreProcessTextureReadable(TextureImporterContext context)
		{
			if (context.HasLabel(LABEL_Read))
			{
				context.TextureImporter.isReadable = true;
			}
			else
			{
				if (assetPath.Contains("/DistributionMap/") || assetPath.Contains(ART_CONTROLMAP_PATH))
					context.TextureImporter.isReadable = true;
				else
					context.TextureImporter.isReadable = false;
			}
		}
		#endregion

		#region SetTextureSize
		private void PreprocessTextureSize(TextureImporterContext context)
		{
			if (assetPath.Contains(ART_VFX_PATH) || assetPath.Contains(UI_VFX_PATH))
			{
				// for vfx
				ProcessVfxTextureSize(context.TextureImporter);
			}
			else if (context.HasLabel(LABEL_2048))
			{
				context.TextureImporter.maxTextureSize = 2048;
			}
			else if (context.HasLabel(LABEL_1024))
			{
				context.TextureImporter.maxTextureSize = 1024;
			}
			else
			{
				// for Models: characters, city, kingdom, gve, se, environments
				ProcessModelTextureSize(context.TextureImporter);
			}
		}
		
		private void ProcessModelTextureSize(TextureImporter textureImporter)
		{
			// var realSize = textureImporter.maxTextureSize;
			int expectedSize = TextureSizeRuleFactory.GetModelTextureMaxSize(assetPath);
			if (expectedSize < 0) return;
			// 感觉应该写错了, 每次获取都是之前的大小, 先注了
			// if (realSize > expectedSize)
			// {
			// 	NLogger.Log($"ProcessModelTextureSize:{assetPath}, change max size from {realSize} to {expectedSize}");
			// 	textureImporter.maxTextureSize = expectedSize;
			// }
			textureImporter.maxTextureSize = expectedSize;
		}

		private void ProcessVfxTextureSize(TextureImporter textureImporter)
		{
			var expectedSize = VfxTools.GetMaxTextureSize(assetPath);
			// 同上应该是写错了
			// var realSize = textureImporter.maxTextureSize;
			// if (realSize > expectedSize)
			// {
			// 	NLogger.Log($"ProcessVfxTextureSize:{assetPath}, change max size from {realSize} to {expectedSize}");
				textureImporter.maxTextureSize = expectedSize;
			// }
		}
		#endregion
		
		#region SetTextureFormat
		private void SetTextureFormat(TextureImporterContext context)
		{
			PreprocessTexture_Android(context);
			PreprocessTexture_iOS(context);
			PreprocessTexture_Default(context);
			PreprocessTexture_Standalone(context);
		}

		private void PreprocessTexture_Android(TextureImporterContext context)
		{
			var androidSet = context.TextureImporter.GetPlatformTextureSettings("Android");
			androidSet.overridden = true;
			androidSet.resizeAlgorithm = TextureResizeAlgorithm.Mitchell;
			androidSet.maxTextureSize = context.TextureImporter.maxTextureSize;
			androidSet.format = GetTextureImporterFormat(context);
			androidSet.compressionQuality = 50;
			androidSet.androidETC2FallbackOverride = AndroidETC2FallbackOverride.UseBuildSettings;
			context.TextureImporter.SetPlatformTextureSettings(androidSet);
		}

		private void PreprocessTexture_iOS(TextureImporterContext context)
		{
			var iosSet = context.TextureImporter.GetPlatformTextureSettings("iPhone");
			iosSet.overridden = true;
			iosSet.maxTextureSize = context.TextureImporter.maxTextureSize;
			iosSet.resizeAlgorithm = TextureResizeAlgorithm.Mitchell;
			iosSet.format = GetTextureImporterFormat(context);
			context.TextureImporter.SetPlatformTextureSettings(iosSet);
		}
		
		private void PreprocessTexture_Default(TextureImporterContext context)
		{
			var ps = context.TextureImporter.GetDefaultPlatformTextureSettings();
			ps.resizeAlgorithm = TextureResizeAlgorithm.Mitchell;
			ps.maxTextureSize = context.TextureImporter.maxTextureSize;
			// 单独处理一下ControlMap
			ps.format = assetPath.Contains(ART_CONTROLMAP_PATH) ? TextureImporterFormat.RGBA32 : TextureImporterFormat.Automatic;
			ps.textureCompression = TextureImporterCompression.Compressed;
			
			context.TextureImporter.SetPlatformTextureSettings(ps);
		}
		
		private void PreprocessTexture_Standalone(TextureImporterContext context)
		{
			var standaloneSet = context.TextureImporter.GetPlatformTextureSettings("Standalone");
			standaloneSet.overridden = false;
			standaloneSet.maxTextureSize = context.TextureImporter.maxTextureSize;
			context.TextureImporter.SetPlatformTextureSettings(standaloneSet);
		}
		
		private TextureImporterFormat GetTextureImporterFormat(TextureImporterContext context)
		{
			if (context.HasLabel(LABEL_R16))
			{
				return TextureImporterFormat.R16;
			}
			// UI_MASK使用ASTC_4x4
			if (assetPath.Contains(UI_ATLAS_MASK_FOLDER))
			{
				return TextureImporterFormat.ASTC_4x4;
			}
			
			return TextureImporterFormat.ASTC_6x6;
		}
		
		private bool ShouldEnableTextureStreaming()
		{
			if (assetPath.Contains("StaticResources/Characters") && assetPath.Contains("Lod0", StringComparison.OrdinalIgnoreCase))
			{
				return true;
			}

			return false;
		}
		#endregion
	}
}
