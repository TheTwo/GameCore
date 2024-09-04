using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.U2D;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
    public static class AssetBundleBuildGenerator
    {
	    public const string ShaderBundleName = ShaderBundlePreFix + "all";
	    public const string UnityBuiltInBundleName = StaticResourcesBundlePreFix + "unitybuiltin";
	    public const string UnityMonoScriptBundleName = StaticResourcesBundlePreFix + "monoscript";

	    private static readonly string[] AssetSearchPath = new[]
        {
	        "Assets/__Art/_Resources",
	        "Assets/__UI/_Resources",
	        "Assets/__Art/StaticResources",
	        "Assets/__UI/StaticResources",
        };

        private static readonly string[] ShaderSearchPath = new[]
        {
	       "Assets/__Shader",
	       "Assets/__Art/_Resources",
	       "Assets/__UI/_Resources",
	       "Assets/__Art/StaticResources",
	       "Assets/__UI/StaticResources",
        };

        private static readonly string[] SceneSearchPath = new[]
        {
            // add here for in bundle scene
            "Assets/__Scene/_Resources",
		};

        public static readonly IReadOnlyList<string> ScenePath = SceneSearchPath;

        public static bool BundleNeedAssetsListByName(ReadOnlySpan<char> bundleName, bool splitInPackAndOta)
        {
	        ReadOnlySpan<char> checkName;
	        if (splitInPackAndOta)
	        {
		        checkName = bundleName.StartsWith(InPackPreFix)
			        ? bundleName[InPackPreFix.Length..]
			        : bundleName.StartsWith(OtaPreFix)
				        ? bundleName[OtaPreFix.Length..]
				        : bundleName;
	        }
	        else
	        {
		        checkName = bundleName;
	        }
	        if (checkName.StartsWith(StaticResourcesBundlePreFix)) return false;
	        // if (checkName.StartsWith(ShaderBundlePreFix)) return false;
	        return true;
        }

        private class Context
        {
	        public readonly Dictionary<string, AssetBundleBuild> Builds = new Dictionary<string, AssetBundleBuild>();
	        public readonly Dictionary<string, string> MappedAssets = new Dictionary<string, string>();
	        public readonly Dictionary<GUID, string> SpriteToBundleName = new Dictionary<GUID, string>();
	        public readonly AssetPathTree<string> PackPathTree = new AssetPathTree<string>();
	        public readonly ISet<string> InPackAssetFullPath = new HashSet<string>();
	        public readonly bool SplitInPackAndOta;
	        public readonly HashSet<string> ExcludeAssetNames = new(StringComparer.OrdinalIgnoreCase);
	        public readonly HashSet<string> AllowInArtResourceAssetNames;

	        public Context(IEnumerable<string> inPackAssetFullPath, IEnumerable<string> excludeInArtResourceFolderPrefabAssetNames, IEnumerable<string> allowInArtResourceAssetNames)
	        {
		        SplitInPackAndOta = inPackAssetFullPath != null;
		        if (null != inPackAssetFullPath) InPackAssetFullPath.UnionWith(inPackAssetFullPath);
		        if (null != excludeInArtResourceFolderPrefabAssetNames) ExcludeAssetNames.UnionWith(excludeInArtResourceFolderPrefabAssetNames);
		        if (null != allowInArtResourceAssetNames)
			        AllowInArtResourceAssetNames = new HashSet<string>(allowInArtResourceAssetNames);
		        else
			        AllowInArtResourceAssetNames = null;
	        }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="explicitInBundleAssetsFullPath"></param>
        /// <param name="spriteToBundleName">额外输出sprite 和 bundle 的映射 强制atlas的所有sprite一定在同一个bundle中</param>
        /// <param name="staticBundleNameGetter"></param>
        /// <param name="mappedAssets"></param>
        /// <param name="splitInPackAndOta"></param>
        /// <param name="excludeAssetNames"></param>
        /// <param name="artResourceWhitelist">artResource 白名单</param>
        /// <returns></returns>
        public static AssetBundleBuild[] GenerateAssetBundleBuilds(IEnumerable<string> explicitInBundleAssetsFullPath
	        , out IReadOnlyDictionary<GUID, string> spriteToBundleName
	        , out Func<string, SourceType, bool?, string> staticBundleNameGetter
	        , out IReadOnlyDictionary<string, string> mappedAssets
	        , out bool splitInPackAndOta
	        , IEnumerable<string> excludeAssetNames = null
	        , IEnumerable<string> artResourceWhitelist = null)
        {
	        var context = new Context(explicitInBundleAssetsFullPath, excludeAssetNames, artResourceWhitelist);
	        PreparePackBundlePath(context);
	        PreGenerateShaderBundle(context);
	        PreGenerateSceneBundle(context);
            PreGenerateSpriteAtlasBundle(context);
            SetAssetBundleBuildWithFolderPath(context);
            // StaticResourcePackInBundle(context);
            PostProcessBundleBuild(context);
            spriteToBundleName = context.SpriteToBundleName;
            staticBundleNameGetter = (assetPath, sourceType, isInPack) =>
	            GenerateAssetBundleNameFromPath(assetPath, sourceType, context, context.SplitInPackAndOta ? isInPack : null);
            mappedAssets = context.MappedAssets;
            splitInPackAndOta = context.SplitInPackAndOta;
            return context.Builds.Values.ToArray();
        }

        private static void PreparePackBundlePath(Context context)
        {
	        var packPathTree = context.PackPathTree;
	        var markerGuids = AssetDatabase.FindAssets(PackBundleMark.MarkerFileName + " t:DefaultAsset", AssetSearchPath);
	        foreach (var markerGuid in markerGuids)
	        {
		        var assetPath = AssetDatabase.GUIDToAssetPath(markerGuid);
		        if (AssetDatabase.IsValidFolder(assetPath)) continue;
		        assetPath = assetPath.Replace('\\', '/').Trim('/');
		        var folderEndIndex = assetPath.LastIndexOf('/');
		        var folderPath = assetPath[..folderEndIndex];
		        var bundleName = FolderBundleName(assetPath);
		        packPathTree.AddPath(folderPath, bundleName, '/');
	        }
        }

        private static void PreGenerateShaderBundle(Context context)
        {
	        var map = context.Builds;
	        var mappedAssets = context.MappedAssets;
	        var shaderAndVariantCollection = AssetDatabase.FindAssets("t:shader t:ShaderVariantCollection", ShaderSearchPath);
	        var build = new AssetBundleBuild();
	        var list = new List<string>();
	        foreach (var assetGuid in shaderAndVariantCollection)
            {
                var assetPath = AssetDatabase.GUIDToAssetPath(assetGuid);
                mappedAssets.Add(assetPath, ShaderBundleName);
                list.Add(assetPath);
            }
	        build.assetBundleName = context.SplitInPackAndOta ? InPackPreFix + ShaderBundleName  : ShaderBundleName;
	        build.assetNames = list.ToArray();
	        map.Add(ShaderBundleName, build);
        }

        private static void PreGenerateSceneBundle(Context context)
        {
	        var map = context.Builds;
	        var mappedAssets = context.MappedAssets;
            if (SceneSearchPath.Length <= 0) return;
            var scenes = AssetDatabase.FindAssets("t:scene", SceneSearchPath);
            if (scenes.Length <= 0) return;
            foreach (var sceneGuid in scenes)
            {
                var scenePath = AssetDatabase.GUIDToAssetPath(sceneGuid);
                var sceneBundleName = GenerateAssetBundleNameFromPath(scenePath, SourceType.Scene, context, context.SplitInPackAndOta ? context.InPackAssetFullPath.Contains(scenePath) : null);
                var build = new AssetBundleBuild();
                build.assetBundleName = sceneBundleName;
                build.assetNames = new[] { scenePath };
                map.Add(sceneBundleName, build);
                mappedAssets.Add(scenePath, sceneBundleName);
            }
        }
        
        private static void PreGenerateSpriteAtlasBundle(Context context)
        {
	        var map = context.Builds;
	        var mappedAssets = context.MappedAssets;
	        var sprite2Bundle = context.SpriteToBundleName;
            var allSpriteAtlas = AssetDatabase.FindAssets("t:spriteatlas", AssetSearchPath);
            foreach (var spriteAtlasGuid in allSpriteAtlas)
            {
                var spAtlasAssetPath = AssetDatabase.GUIDToAssetPath(spriteAtlasGuid);
                var spriteAtlasAsset = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(spAtlasAssetPath);
                var spCount = spriteAtlasAsset.spriteCount;
                if (spCount <= 0) continue;
                var packables = spriteAtlasAsset.GetPackables();
                var bundleName = GenerateAssetBundleNameFromPath(spAtlasAssetPath, SourceType.SpriteAtlas, context, context.SplitInPackAndOta ? context.InPackAssetFullPath.Contains(spAtlasAssetPath) : null);
                var build = new AssetBundleBuild();
                var spriteList = new HashSet<string>();
                //spriteList.Add(spAtlasAssetPath);//add sprite atlas file for feature use
                mappedAssets.Add(spAtlasAssetPath, bundleName);
                foreach (var packable in packables)
                {
                    if (packable is Texture2D texture)
                    {
                        var spPath = AssetDatabase.GetAssetPath(texture);
                        var spGuid = AssetDatabase.GUIDFromAssetPath(spPath);
                        sprite2Bundle[spGuid] = bundleName;
                        mappedAssets.Add(spPath, bundleName);
                        spriteList.Add(spPath);
                    }
                    else if (packable is DefaultAsset defaultAsset)
                    {
                        var folder = AssetDatabase.GetAssetPath(defaultAsset);
                        var sps = AssetDatabase.FindAssets("t:sprite", new[] { folder });
                        foreach (var spguid in sps)
                        {
                            var spPath = AssetDatabase.GUIDToAssetPath(spguid);
                            var spGuid = AssetDatabase.GUIDFromAssetPath(spPath);
                            sprite2Bundle[spGuid] = bundleName;
                            mappedAssets.Add(spPath, bundleName);
                            spriteList.Add(spPath);
                        }
                    }
                    else
                    {
                        NLogger.Error(packable.ToString());
                    }
                }
                build.assetBundleName = bundleName;
                build.assetNames = spriteList.ToArray();
                map.Add(bundleName, build);
            }
        }

        private static void SetAssetBundleBuildWithFolderPath(Context context)
        {
	        var map = context.Builds;
	        var mappedAssets = context.MappedAssets;
	        var sprite2Bundle = context.SpriteToBundleName;
	        var sceneType = typeof(SceneAsset);
	        var shaderIncludeType = typeof(ShaderInclude);
	        var allAssets = AssetDatabase.FindAssets(string.Empty, AssetPathProvider.GetCheckFolders(false).ToArray()).Select(g=>new GUID(g));
            var bundleMap = new Dictionary<string, HashSet<string>>();
            using var assetChecker = AssetPathProvider.GetAssetChecker();
            foreach (var guid in allAssets)
            {
	            if (sprite2Bundle.ContainsKey(guid)) continue;
                var localPath = AssetDatabase.GUIDToAssetPath(guid);
                if (mappedAssets.ContainsKey(localPath)) continue;
                var ext = Path.GetExtension(localPath);
                if (string.IsNullOrWhiteSpace(ext)) continue;
                var mainType = AssetDatabase.GetMainAssetTypeAtPath(localPath);
                if (sceneType.IsAssignableFrom(mainType) || shaderIncludeType.IsAssignableFrom(mainType)) continue;
                var fileName = AssetPathProvider.GetFileNameWithoutExtension(localPath);
                if (string.IsNullOrEmpty(fileName))
                {
                    continue;
                }
                if (assetChecker.IsSceneBakedAsset(localPath)) continue;
                if (localPath.StartsWith("Assets/__Art/_Resources/") && context.AllowInArtResourceAssetNames != null && !context.AllowInArtResourceAssetNames.Contains(fileName)) continue;
                if (context.AllowInArtResourceAssetNames == null && context.ExcludeAssetNames.Contains(fileName)) continue;
                var bundleName = GenerateAssetBundleNameFromPath(localPath, SourceType.Asset, context, context.SplitInPackAndOta ? context.InPackAssetFullPath.Contains(localPath) : null);
                if (!bundleMap.TryGetValue(bundleName, out var set))
                {
                    set = new HashSet<string>();
                    bundleMap.Add(bundleName, set);
                }
                mappedAssets.Add(localPath, bundleName);
                set.Add(localPath);
            }
            foreach (var bundleAssetSet in bundleMap)
            {
                var build = new AssetBundleBuild();
                build.assetBundleName = bundleAssetSet.Key;
                if (map.TryGetValue(bundleAssetSet.Key, out var b))
                {
                    bundleAssetSet.Value.UnionWith(b.assetNames);
                    b.assetNames = bundleAssetSet.Value.ToArray();
                    map[bundleAssetSet.Key] = b;
                }
                else
                {
                    build.assetNames = bundleAssetSet.Value.ToArray();
                    map.Add(bundleAssetSet.Key, build);
                }
            }
        }

        // ReSharper disable once UnusedMember.Local
        private static void StaticResourcePackInBundle(Context context)
        {
	        var map = context.Builds;
	        var mappedAssets = context.MappedAssets;
	        var sprite2Bundle = context.SpriteToBundleName;
	        var sceneType = typeof(SceneAsset);
	        var allAssets = AssetDatabase.FindAssets(string.Empty, AssetPathProvider.GetStaticResourcesFolders().ToArray());
            var bundleMap = new Dictionary<string, HashSet<string>>();
            foreach (var find in allAssets)
            {
                var localPath = AssetDatabase.GUIDToAssetPath(find);
                if (mappedAssets.ContainsKey(localPath)) continue;
                var guid = AssetDatabase.GUIDFromAssetPath(localPath);
                if (sprite2Bundle.ContainsKey(guid)) continue;
                var mainType = AssetDatabase.GetMainAssetTypeAtPath(localPath);
                if (mainType == sceneType) continue;
                var extension = Path.GetExtension(localPath);
                if (string.IsNullOrEmpty(extension))
                {
                    continue;
                }
                var fileName = AssetPathProvider.GetFileNameWithoutExtension(localPath);
                if (string.IsNullOrEmpty(fileName))
                {
                    continue;
                }

                var bundleName = GenerateAssetBundleNameFromPath(localPath, SourceType.StaticResources, context, context.SplitInPackAndOta ? context.InPackAssetFullPath.Contains(localPath) : null);
                if (!bundleMap.TryGetValue(bundleName, out var set))
                {
                    set = new HashSet<string>();
                    bundleMap.Add(bundleName, set);
                }
                mappedAssets.Add(localPath, bundleName);
                set.Add(localPath);
            }
            foreach (var bundleAssetSet in bundleMap)
            {
                var build = new AssetBundleBuild();
                build.assetBundleName = bundleAssetSet.Key;
                if (map.TryGetValue(bundleAssetSet.Key, out var b))
                {
                    bundleAssetSet.Value.UnionWith(b.assetNames);
                    b.assetNames = bundleAssetSet.Value.ToArray();
                    map[bundleAssetSet.Key] = b;
                }
                else
                {
                    build.assetNames = bundleAssetSet.Value.ToArray();
                    map.Add(bundleAssetSet.Key, build);
                }
            }
        }

        private static void PostProcessBundleBuild(Context context)
        {
	        var map = context.Builds;
	        var keys = new List<string>(map.Keys);
	        foreach (var key in keys)
	        {
		        var v = map[key];
		        if (v.assetNames.Length <= 0)
		        {
			        map.Remove(key);
		        }
	        }
        }
        
        public enum SourceType
        {
            Asset,
            SpriteAtlas,
            Scene,
            StaticResources
        }

        public const string ArtBundlePreFix = "art@";
        public const string UiBundlePreFix = "ui@";
        public const string AtlasBundlePreFix = "atlas@";
        public const string SceneBundlePreFix = "scene@";
        public const string StaticResourcesBundlePreFix = "static@";
        public const string ShaderBundlePreFix = "shader@";
        public const string MaterialBundlePreFix = "mat@";
        public const string InPackPreFix = "pack@";
        public const string OtaPreFix = "ota@";

        private static string GenerateAssetBundleNameFromPath(string path, SourceType sourceType, Context context, bool? isInPack)
        {
	        string ret;
            var prefix = string.Empty;
            switch (sourceType)
            {
                case SourceType.Asset:
	                if (!context.PackPathTree.TryMatch(path, true, '/', out ret))
	                {
		                ret = FolderBundleName(path);
	                }
	                break;
                case SourceType.SpriteAtlas:
                {
                    prefix = AtlasBundlePreFix;
                    ret = Path.GetFileNameWithoutExtension(path);
                }
                    break;
                case SourceType.Scene:
                    prefix = SceneBundlePreFix;
                    ret = Path.GetFileNameWithoutExtension(path);
                    break;
                case SourceType.StaticResources:
                    prefix = StaticResourcesBundlePreFix;
                    if (!context.PackPathTree.TryMatch(path, true, '/', out ret))
                    {
	                    ret = FolderBundleName(path);
                    }
                    break;
                default:
                    throw new ArgumentOutOfRangeException(nameof(sourceType), sourceType, null);
            }
            if (string.IsNullOrWhiteSpace(ret))
            {
                ret = Path.GetDirectoryName(ret);
            }

            ret = isInPack.HasValue ? string.Concat(isInPack.Value ? InPackPreFix : OtaPreFix , prefix , ret) : string.Concat(prefix , ret);
            if (string.IsNullOrWhiteSpace(ret))
            {
                throw new ArgumentException($"error Path:{path}");
            }
            return ret.ToLowerInvariant();
        }

        private static string FolderBundleName(string inputPath, int folderDepthLimit = -1)
        {
	        var fileExt = Path.GetExtension(inputPath);
	        var folder = Path.GetDirectoryName(inputPath);
	        if (string.IsNullOrEmpty(folder)) return string.Empty;
	        folder = folder.Replace('\\', '/');
	        if (folderDepthLimit > 0)
	        {
		        for (var i = 1; i < folder.Length; i++)
		        {
			        var c = folder[i];
			        if (c != '/') continue;
			        if (--folderDepthLimit <= 0)
			        {
				        folder = folder[..i];
			        }
		        }
	        }

	        if (folder.EndsWith("/__DontFixMe", StringComparison.Ordinal))
	        {
		        folder = folder[..^"/__DontFixMe".Length];
	        }

	        if (folder.StartsWith("Assets/__Shader/VFX/", StringComparison.OrdinalIgnoreCase))
			{
				return ShaderBundlePreFix + folder["Assets/__Shader/".Length..].Replace('/', '@');
			}

	        if (folder.StartsWith("Assets/__Art/_Resources/City/", StringComparison.OrdinalIgnoreCase) 
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
		            || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + folder["Assets/__Art/_Resources/".Length..].Replace('/', '@') + '@' + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }
            
	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/Decoration/", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "KingdomMap@Decoration_Prefab@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }
	        
	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/Function/", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "KingdomMap@Function_Prefab@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }
	        
	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/BridgePrefab", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "KingdomMap@HexMap_BridgePrefab@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }
	        
	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/GatePrefab", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "KingdomMap@HexMap_GatePrefab@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }
	        
	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/SlopeRoadPrefab", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "KingdomMap@HexMap_SlopeRoadPrefab@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }
	        
	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/WavePrefab", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "KingdomMap@HexMap_WavePrefab@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }

	        if (inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/HexIdMap_v2/", StringComparison.OrdinalIgnoreCase)
	            && !inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/HexIdMap_v2/RoadPrefab/", StringComparison.OrdinalIgnoreCase)
	            && !inputPath.StartsWith("Assets/__Art/_Resources/KingdomMap/HexMap/Prefab/Runtime/HexIdMap_v2/RoadPrefab_2d/", StringComparison.OrdinalIgnoreCase)
	            && !string.IsNullOrWhiteSpace(fileExt)
	            && (StringComparer.OrdinalIgnoreCase.Compare(".prefab", fileExt) == 0
	                || StringComparer.OrdinalIgnoreCase.Compare(".fbx", fileExt) == 0))
	        {
		        return ArtBundlePreFix + "HexIdMap_v2@" + Path.GetFileNameWithoutExtension(inputPath).Replace(' ', '_');
	        }

	        if (folder.StartsWith("Assets/__Art/_Resources/", StringComparison.OrdinalIgnoreCase))
	        {
		        return ArtBundlePreFix + folder["Assets/__Art/_Resources/".Length..].Replace('/', '@');
	        }

			//// UI特效的材质和贴图，统一进一个ab
			//if (folder.StartsWith("Assets/__UI/StaticResources/VFX/", StringComparison.OrdinalIgnoreCase))
			//{
			//	return UiBundlePreFix + "vfx@all";
			//}

			if (folder.StartsWith("Assets/__UI/_Resources/Prefab/", StringComparison.OrdinalIgnoreCase))
	        {
		        return
			        UiBundlePreFix + "prefab@" + Path.GetFileNameWithoutExtension(inputPath); //folder["Assets/__UI/_Resources/Prefab/".Length..].Replace('/', '@');
	        }

	        if (folder.StartsWith("Assets/__UI/_Resources/", StringComparison.OrdinalIgnoreCase))
	        {
		        return UiBundlePreFix + folder["Assets/__UI/_Resources/".Length..].Replace('/', '@');
	        }

	        if (folder.StartsWith("Assets/__Art/StaticResources/", StringComparison.OrdinalIgnoreCase))
	        {
				if (folder.StartsWith("Assets/__Art/StaticResources/Characters/", StringComparison.OrdinalIgnoreCase)
					&& folder.Contains("/Anim/", StringComparison.OrdinalIgnoreCase))
				{
					var startIdx = "Assets/__Art/StaticResources/".Length;
					var endIdex = folder.IndexOf("/Anim/", StringComparison.OrdinalIgnoreCase) + "/Anim/".Length;
					return ArtBundlePreFix + folder[startIdx..endIdex].Replace('/', '@');
				}

		        return ArtBundlePreFix + folder["Assets/__Art/StaticResources/".Length..].Replace('/', '@');
	        }

	        if (folder.StartsWith("Assets/__UI/StaticResources/", StringComparison.OrdinalIgnoreCase))
	        {
		        return UiBundlePreFix + folder["Assets/__UI/StaticResources/".Length..].Replace('/', '@');
	        }

			if (folder.StartsWith("Packages/com.esotericsoftware.spine.spine-unity/Runtime/spine-unity/", StringComparison.OrdinalIgnoreCase))
			{
				return "spine";
			}

	        return folder.Replace('/', '@');
        }
        
        // ReSharper disable once UnusedMember.Local
        public static string BundleNameToHash(string bundleName)
        {
	        return Md5Utils.GetMd5ByString(bundleName);
        }
    }
}
