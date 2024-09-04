using UnityEditor;
using UnityEngine;
using System.IO;
namespace DragonReborn.UI.Editor
{
    
    public static class LuaBaseComponentEditorUtility
    {
        private static readonly string LuaDirectoryPath = "../../../ssr-logic/Lua/";
        public static string FindLuaFilePath(string luaPath)
        {
            if (Directory.Exists(LuaDirectoryPath) && !string.IsNullOrEmpty(luaPath))
            {
                var files = Directory.GetFiles(LuaDirectoryPath, $"{luaPath}.lua",SearchOption.AllDirectories);
                if (files != null && files.Length > 0)
                {
                    return files[0];
                }
            }
            return null;
        }

        public static void OnInspectorGUI(ILuaComponent component)
        {
			if (component == null || !Directory.Exists(LuaDirectoryPath)) return;
			
			string luaScriptName = component.LuaScriptPath();
			if (string.IsNullOrEmpty(luaScriptName))
			{
				EditorGUILayout.HelpBox("必须配置Lua脚本名!", MessageType.Error);
				return;
			}
			string fullPath = component.LuaScriptFullPath();
			if(string.IsNullOrEmpty(fullPath) || !File.Exists(fullPath))
			{	
				fullPath = FindLuaFilePath(luaScriptName);
				component.SetLuaScriptFullPath(fullPath);
			}
			if (string.IsNullOrEmpty(fullPath))
			{
				EditorGUILayout.HelpBox($"找不到文件: {luaScriptName}!!", MessageType.Error);
			}
			else
			{
				EditorGUILayout.HelpBox($"Lua路径: {fullPath}", MessageType.Info);
				if (GUILayout.Button("查看Lua文件"))
				{
					EditorUtility.RevealInFinder(Path.GetFullPath(fullPath));
				}
			}

			
        }

		
      
      
    }
    #if USE_XLUA
    [CustomEditor(typeof(LuaBaseComponent),true)]
    public class LuaBaseComponentInspector : UnityEditor.Editor
    {
        private LuaBaseComponent editorObj = null;
        private void OnEnable()
        {
            editorObj = target as LuaBaseComponent;
        }
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            LuaBaseComponentEditorUtility.OnInspectorGUI(editorObj);
        }
    }
    #endif
}
