using System.IO;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    /// <summary>
    /// 开发模式快速切换pack开关
    /// </summary>
    public static class EditorUsePackMode
    {
        private const string MENU_KEY = "DragonReborn/常用设置/使用Pack模式加载luac和配置";
        private const string MENU_GEN_KEY = "DragonReborn/资源工具箱/出包工具/Pack/生成Luac和配置的pack";
        private const string MENU_LOCAL_ASSET_KEY = "DragonReborn/常用设置/使用本地配置模式";
        private const string MENU_LOCAL_ASSET_PRIVATE_SERVER_KEY = "DragonReborn/常用设置/使用QA私服配置模式";
        private const string MENU_CLEAR_CONFIG_CACHE_KEY = "DragonReborn/常用设置/删除包外配置文件夹";

        [MenuItem(MENU_KEY, true, 31)]
        private static bool CheckUseLuacConfigsFromPack()
        {
            var usePack = EditorPrefs.GetBool(ScriptEngine.USE_PACK_MODE, false);
            Menu.SetChecked(MENU_KEY, usePack);
            return !EditorApplication.isPlaying && !EditorApplication.isCompiling && !EditorApplication.isPaused && !EditorApplication.isPlayingOrWillChangePlaymode;
        }

        [MenuItem(MENU_KEY, false, 31)]
        private static void FlipUseLuacConfigsFromPack()
        {
            var useLuaPack = EditorPrefs.GetBool(ScriptEngine.USE_PACK_MODE, false);
            EditorPrefs.SetBool(ScriptEngine.USE_PACK_MODE, !useLuaPack);
        }

        [MenuItem(MENU_GEN_KEY, true, 50)]
        private static bool CheckGenLuacConfigsPack()
        {
            if (EditorApplication.isPlaying || EditorApplication.isCompiling || EditorApplication.isPaused || EditorApplication.isPlayingOrWillChangePlaymode) 
            { 
                return false; 
            }

            var luacFolder = Path.Combine(Application.streamingAssetsPath, "GameAssets/Luac");
            var configsFolder = Path.Combine(Application.streamingAssetsPath, "GameAssets/Configs");
            return Directory.Exists(luacFolder) && Directory.Exists(configsFolder);
        }

        [MenuItem(MENU_GEN_KEY, false, 50)]
        private static void GenLuacConfigsPack()
        {
            LuaScriptLoader.GenerateLuacPack(false);
            LuaScriptLoader.GenerateConfigsPack(false);
            EditorUtility.DisplayDialog("Congrats", "GenLuacConfigsPack Succeed!", "OK");
        }

        [MenuItem(MENU_LOCAL_ASSET_KEY, true, 60)]
        private static bool CheckLocalConfig()
        {
	        var localConfig = EditorPrefs.GetBool(ScriptEngine.USE_LOCAL_CONFIG, false);
			Menu.SetChecked(MENU_LOCAL_ASSET_KEY, localConfig);
			return !EditorApplication.isPlaying && !EditorApplication.isCompiling && !EditorApplication.isPaused && !EditorApplication.isPlayingOrWillChangePlaymode;
        }

        [MenuItem(MENU_LOCAL_ASSET_KEY, false, 60)]
        private static void UseLocalConfig()
        {
	        var localConfig = EditorPrefs.GetBool(ScriptEngine.USE_LOCAL_CONFIG, false);
	        EditorPrefs.SetBool(ScriptEngine.USE_LOCAL_CONFIG, !localConfig);
        }
        
        [MenuItem(MENU_LOCAL_ASSET_PRIVATE_SERVER_KEY, true, 60)]
        private static bool CheckPrivateServerLocalConfig()
        {
	        var localConfig = EditorPrefs.GetBool(ScriptEngine.USE_PRIVATE_SERVER_LOCAL_CONFIG, false);
			Menu.SetChecked(MENU_LOCAL_ASSET_PRIVATE_SERVER_KEY, localConfig);
			return !EditorApplication.isPlaying && !EditorApplication.isCompiling && !EditorApplication.isPaused && !EditorApplication.isPlayingOrWillChangePlaymode;
        }

        [MenuItem(MENU_LOCAL_ASSET_PRIVATE_SERVER_KEY, false, 60)]
        private static void UsePrivateServerLocalConfig()
        {
	        var localConfig = EditorPrefs.GetBool(ScriptEngine.USE_PRIVATE_SERVER_LOCAL_CONFIG, false);
	        EditorPrefs.SetBool(ScriptEngine.USE_PRIVATE_SERVER_LOCAL_CONFIG, !localConfig);
        }

        [MenuItem(MENU_CLEAR_CONFIG_CACHE_KEY, true, 59)]
        private static bool CheckClearLocalConfigFolder()
        {
	        var documentCfgFolder = AssetPath.Combine(Application.persistentDataPath, "GameConfigs");
	        return Directory.Exists(documentCfgFolder);
        }

        [MenuItem(MENU_CLEAR_CONFIG_CACHE_KEY, false, 59)]
        private static void ClearLocalConfigFolder()
        {
	        var documentCfgFolder = AssetPath.Combine(Application.persistentDataPath, "GameConfigs");
	        Directory.Delete(documentCfgFolder, true);
        }
    }
}