using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.U2D;

namespace DragonReborn.AssetTool.Editor
{
    public class SpriteAtlasTool
    {
        private const string SPRITE_ATLAS_PATH = "Assets/__UI/StaticResources/SpriteAtlas/";
        private const string SPRITES_ROOT = "Assets/__UI/_Resources/UIAtlas/Sprites/";
        
        [MenuItem("DragonReborn/资源工具箱/图集工具/生成图集")]
        public static void GenerateSpriteAtlas()
        {
            if (!Directory.Exists(SPRITE_ATLAS_PATH))
            {
                Directory.CreateDirectory(SPRITE_ATLAS_PATH);
            }
            else
            {
                Directory.Delete(SPRITE_ATLAS_PATH, true);
                Directory.CreateDirectory(SPRITE_ATLAS_PATH);
            }

            // var guids = AssetDatabase.FindAssets("t:folder", new[] { SPRITES_ROOT });
            var guids = SearchAssetHelper.SearchAssetInFoldersTopOnly("t:folder", new[] { SPRITES_ROOT });
            // 以目录为单位创建SpriteAtlas
            foreach (var guid in guids)
            {
                var folderPath = AssetDatabase.GUIDToAssetPath(guid);
                if (EditorSettings.spritePackerMode == SpritePackerMode.SpriteAtlasV2)
                {
                    // sprite atlas v2
                    CreateSpriteAtlasV2ByFolder(folderPath);
                }
                else
                {
                    // sprite atlas v1
                    CreateSpriteAtlasV1ByFolder(folderPath);
                }
            }

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
        }

        private static void CreateSpriteAtlasV1ByFolder(string spritesFolderPath)
        {
			NLogger.Log($"CreateSpriteAtlasV1ByFolder {spritesFolderPath}");

            var guids = AssetDatabase.FindAssets("t:texture", new[] { spritesFolderPath });
            if (guids.Length == 0)
            {
                Debug.LogWarning($"{spritesFolderPath}里没有找到texture");
                return;
            }
            
            // v1是SpriteAtlas
            // v2是SpriteAtlasAsset
            var sa = new SpriteAtlas();
            TextureImporter importer = null;
            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                sa.Add(new UnityEngine.Object[1] {tex});
                
                if (importer == null)
                {
                    importer = AssetImporter.GetAtPath(path) as TextureImporter;
                }
            }
            
            var packSetting = sa.GetPackingSettings();
            packSetting.enableRotation = false;
            packSetting.enableTightPacking = false;
			sa.SetPackingSettings(packSetting);

			// if (spritesFolderPath.EndsWith("ui_item"))
			// {
			// 	var textureSetting = sa.GetTextureSettings();
			// 	textureSetting.generateMipMaps = true;
			// 	sa.SetTextureSettings(textureSetting);
			// 	NLogger.Log($"CreateSpriteAtlasV2ByFolder: generateMipMaps true for {spritesFolderPath}");
			// }
            
            sa.SetIncludeInBuild(true);

            if (importer == null)
            {
                Debug.LogError("{spritesFolderPath}里没有找到texture");
                return;
            }
            
            // 用texture设置来配置SpriteAtlas
            var iosSet = importer.GetPlatformTextureSettings("iPhone");
            var androidSet = importer.GetPlatformTextureSettings("Android");

            var iosSpriteAtlasSet = sa.GetPlatformSettings("iPhone");
            var androidSpriteAtlasSet = sa.GetPlatformSettings("Android");

            iosSpriteAtlasSet.format = iosSet.format;
            iosSpriteAtlasSet.overridden = true;
            
            androidSpriteAtlasSet.overridden = true;
            androidSpriteAtlasSet.format = androidSet.format;
            androidSpriteAtlasSet.allowsAlphaSplitting = androidSet.allowsAlphaSplitting;
            sa.SetPlatformSettings(iosSpriteAtlasSet);
            sa.SetPlatformSettings(androidSpriteAtlasSet);

            var directoryInfo = new DirectoryInfo(Path.Join(Application.dataPath, spritesFolderPath));
            var alasPath = SPRITE_ATLAS_PATH + directoryInfo.Name + ".spriteatlas";
            AssetDatabase.CreateAsset(sa, alasPath);
        }

        private static void CreateSpriteAtlasV2ByFolder(string spritesFolderPath)
        {
			NLogger.Log($"CreateSpriteAtlasV2ByFolder {spritesFolderPath}");

			var guids = AssetDatabase.FindAssets("t:texture", new[] { spritesFolderPath });
            if (guids.Length == 0)
            {
                Debug.LogWarning($"{spritesFolderPath}里没有找到texture");
                return;
            }
            
            // v1是SpriteAtlas
            // v2是SpriteAtlasAsset
            var sa = new SpriteAtlasAsset();
            TextureImporter importer = null;
            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                sa.Add(new UnityEngine.Object[1] {tex});
                
                if (importer == null)
                {
                    importer = AssetImporter.GetAtPath(path) as TextureImporter;
                }
            }
			if (importer == null)
            {
                Debug.LogError("{spritesFolderPath}里没有找到texture");
                return;
            }
			var directoryInfo = new DirectoryInfo(Path.Join(Application.dataPath, spritesFolderPath));
			var alasPath = SPRITE_ATLAS_PATH + directoryInfo.Name + ".spriteatlasv2";
			SpriteAtlasAsset.Save(sa, alasPath);

			var spriteAtlasImporter = AssetImporter.GetAtPath(alasPath) as SpriteAtlasImporter;
			var packSetting = spriteAtlasImporter.packingSettings;
			packSetting.enableRotation = false;
			packSetting.enableTightPacking = false;
			spriteAtlasImporter.packingSettings = packSetting;

			// if (spritesFolderPath.EndsWith("ui_item"))
			// {
			// 	var textureSetting = sa.GetTextureSettings();
			// 	textureSetting.generateMipMaps = true;
			// 	sa.SetTextureSettings(textureSetting);
			// 	NLogger.Log($"CreateSpriteAtlasV2ByFolder: generateMipMaps true for {spritesFolderPath}");
			// }

			spriteAtlasImporter.includeInBuild = true;

			// 用texture设置来配置SpriteAtlas
			var iosSet = importer.GetPlatformTextureSettings("iPhone");
            var androidSet = importer.GetPlatformTextureSettings("Android");

            var iosSpriteAtlasSet = spriteAtlasImporter.GetPlatformSettings("iPhone");
            var androidSpriteAtlasSet = spriteAtlasImporter.GetPlatformSettings("Android");

            iosSpriteAtlasSet.format = iosSet.format;
            iosSpriteAtlasSet.overridden = true;
            
            androidSpriteAtlasSet.overridden = true;
            androidSpriteAtlasSet.format = androidSet.format;
            androidSpriteAtlasSet.allowsAlphaSplitting = androidSet.allowsAlphaSplitting;
			spriteAtlasImporter.SetPlatformSettings(iosSpriteAtlasSet);
			spriteAtlasImporter.SetPlatformSettings(androidSpriteAtlasSet);
			spriteAtlasImporter.SaveAndReimport();
        }
    }
}
