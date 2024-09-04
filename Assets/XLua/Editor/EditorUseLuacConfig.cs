using System.IO;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    /// <summary>
    /// 开发模式快速切换luac开关
    /// </summary>
    public static class EditorUseLuacConfig
    {
        private const string KEY = "DISABLE_LUA_DEV_FOLDER";

        private const string MENU_KEY = "DragonReborn/XLua/禁用直读ssr-logic模式";
        private const string MENU_CLEAN_KEY = "DragonReborn/XLua/清空persistentDataPath目录下的Luac目录";
        
        [MenuItem(MENU_KEY, true, 31)]
        private static bool Check_disable_lua_dev_folder()
        {
            var disable = EditorPrefs.GetBool(KEY, false);
            Menu.SetChecked(MENU_KEY, disable);
            return !EditorApplication.isPlaying && !EditorApplication.isCompiling && !EditorApplication.isPaused && !EditorApplication.isPlayingOrWillChangePlaymode;
        }
        
        [MenuItem(MENU_KEY, false, 31)]
        private static void Flip_disable_lua_dev_folder()
        {
            var b = EditorPrefs.GetBool(KEY, false);
            EditorPrefs.SetBool(KEY, !b);
        }
        
        [MenuItem(MENU_CLEAN_KEY, true, 50)]
        private static bool CheckClearPersistentLuac()
        {
            if (EditorApplication.isPlaying || EditorApplication.isCompiling || EditorApplication.isPaused || EditorApplication.isPlayingOrWillChangePlaymode) return false;
            var targetFolder = Path.Combine(Application.persistentDataPath, "GameAssets/Luac");
            return Directory.Exists(targetFolder);
        }

        [MenuItem(MENU_CLEAN_KEY, false, 50)]
        private static void ClearPersistentLuac()
        {
            var targetFolder = Path.Combine(Application.persistentDataPath, "GameAssets/Luac");
            if (Directory.Exists(targetFolder))
            {
                Directory.Delete(targetFolder, true);
            }
        }
    }
}