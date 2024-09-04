using System.IO;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public static class LuaBehaviourEditorUtils
    {
        public static byte[] FindTextAsset(string scriptName)
        {
            if (string.IsNullOrEmpty(scriptName))
            {
                return null;
            }

            if (LuaBehaviourFileWatcher.instance.GetFileFullPath(scriptName, out var fullPath) && File.Exists(fullPath))
            {
                return File.ReadAllBytes(fullPath);
            }

            var (rootPath,ext) = GetCurrentRootPath();
            return ReadAllBytes(rootPath, scriptName, ext);
        }
        
        public static (string,string) GetCurrentRootPath()
        {
            return true
                ? (LuaCExportTools.ExternalLuaSourcePathRoot, ".lua")
                : (LuaCExportTools.InternalLuaBinaryPathRoot, ".txt");
        }

        private static string GetPath(string folder, string scriptName, string ext)
        {
            var files = Directory.GetFiles(folder, scriptName + ext, SearchOption.AllDirectories);
            foreach (var file in files)
            {
                var fileName = Path.GetFileNameWithoutExtension(file);
                if (fileName == scriptName)
                {
                    return file;
                }
            }

            return string.Empty;
        }

        private static byte[] ReadAllBytes(string folder, string scriptName, string ext)
        {
            var path = GetPath(folder, scriptName, ext);
            if (string.IsNullOrEmpty(path))
            {
                return null;
            }
            
            return File.Exists(path) ? File.ReadAllBytes(path) : null;
        }
    }
}