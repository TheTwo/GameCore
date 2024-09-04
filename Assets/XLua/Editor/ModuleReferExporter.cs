using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using UnityEditor;

namespace DragonReborn
{
    public static class ModuleReferExporter
    {
        static ModuleReferExporter()
        {
            BaseModuleRegex = new Regex(@"class\(['""](\w+)['""],BaseModule\)");
        }

        private static Regex BaseModuleRegex;

        // [MenuItem("DragonReborn/XLua/生成ModuleRefer智能提示文件", false, 20)]
        public static void GenerateModuleRefer()
        {
            var sb = new StringBuilder();
            var rootFolder = LuaCExportTools.ExternalLuaSourcePathRoot;
            var files = Directory.GetFiles(rootFolder, "*Module.lua", SearchOption.AllDirectories);
            var list = new List<string>();

            if (EditorUtility.DisplayCancelableProgressBar("Starting Exporting ModuleReferHint", "Collecting", 0))
                return;
	        int index = 0;
            var task = Task.Run(() =>
            {
	            for (; index < files.Length; index++)
	            {
		            var file = files[index];
		            using StreamReader reader = new StreamReader(file);
		            string content = reader.ReadToEnd();
		            string nonSpace = content.Replace(" ", "");
		            if (BaseModuleRegex.IsMatch(nonSpace))
		            {
			            list.Add(BaseModuleRegex.Match(nonSpace).Groups[1].Value);
		            }
	            }
            });

            EditorApplication.CallbackFunction tickFunc = null;
            tickFunc = TickProcess;
            EditorApplication.update += tickFunc;
            
            void TickProcess()
            {
	            var cancel = false;
	            do
	            {
		            if (task.IsCompleted) break;
		            var file = files[index];
		            if (EditorUtility.DisplayCancelableProgressBar(
			                $"Exporting ModuleReferHint ({index}/{files.Length})",
			                file,
			                (float)index / files.Length))
		            {
			            EditorUtility.ClearProgressBar();
			            cancel = true;
			            break;
		            }
		            return;
	            } while (false);
	            if (!cancel && !task.IsFaulted)
					Continue();
	            if (null != tickFunc)
	            {
		            EditorApplication.update -= tickFunc;
	            }
            }

            void Continue()
            {
	            if (EditorUtility.DisplayCancelableProgressBar("Exporting ModuleReferHint", "Collecting Finish", 1))
		            return;

	            sb.Append("---@class ModuleRefer\n");
	            list.Sort(StringComparer.Ordinal);
	            foreach (var module in list)
	            {
		            sb.Append($"---@field {module} {module}\n");
	            }

	            EditorUtility.DisplayProgressBar("Starting Writing File", "Waiting", 1);
	            var writer = File.CreateText(Path.Combine(rootFolder, "ModuleRefer_LuaHint.lua"));
	            writer.Write(sb.ToString());
	            writer.Flush();
	            writer.Close();
	            EditorUtility.ClearProgressBar();
	            AssetDatabase.Refresh();
            }
        }
    }
}