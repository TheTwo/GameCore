using System.IO;
using UnityEngine;

namespace DragonReborn
{
    public static class LuaCExportTools
    {
        public static readonly string ExternalLuaSourcePathRoot;
        public static readonly string InternalLuaBinaryPathRoot;

        private static readonly string DataPath;
        private static readonly string StreamingAssetsPath;
        private static readonly string LuaC;

        static LuaCExportTools()
        {
            DataPath = Application.dataPath;
            StreamingAssetsPath = Application.streamingAssetsPath;
            
            ExternalLuaSourcePathRoot = Path.Combine(DataPath, "../../../../ssr-logic/Lua/");
            ExternalLuaSourcePathRoot = Path.GetFullPath(ExternalLuaSourcePathRoot);

            switch (Application.platform)
            {
                case RuntimePlatform.OSXEditor:
                    LuaC = Path.Combine(DataPath, "../../../../ssr-logic/Tools/luac/Mac/luac");
                    break;
                
                case RuntimePlatform.WindowsEditor:
                    LuaC = Path.Combine(DataPath, "../../../../ssr-logic/Tools/luac/Win/luac.exe");
                    break;
            }
            
            LuaC = Path.GetFullPath(LuaC);
            
            InternalLuaBinaryPathRoot = Path.Combine(DataPath, "../Luac");
        }
    }
}