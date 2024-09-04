using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using UnityEditor;
using UnityEngine;
using XLua;

namespace DragonReborn
{
    public static partial class ConfigReferExporter
    {
        static ConfigReferExporter()
        {
            LogicRepo = Path.Combine(UnityEngine.Application.dataPath, "../../../../ssr-logic/fbs");
            LogicRepo = Path.GetFullPath(LogicRepo);
            ConfigRepo = Path.Combine(Application.dataPath, "../../../../ssr-logic/ConfigMeta");
            ConfigRepo = Path.GetFullPath(ConfigRepo);
        }

        private static string LogicRepo { get; }

        #region V1
        private const string CONST_FILENAME = "CfgConst";
        // [MenuItem("DragonReborn/XLua/生成ConfigRefer智能提示文件", false, 20)]
        public static async void GenerateConfigRefer()
        {
            var sb = new StringBuilder();
            var rootFolder = Path.Combine(LuaCExportTools.ExternalLuaSourcePathRoot, "__Config");
            var configs = Directory.GetFiles(rootFolder, "*Config.lua", SearchOption.AllDirectories);
            var list = new List<string>();
            
            var constList = new List<string>();

            foreach (var fileName in configs)
            {
                var configName = Path.GetFileName(fileName).Replace("Config.lua", "");
                list.Add(configName);
            }

            if (File.Exists(Path.Combine(LuaCExportTools.ExternalLuaSourcePathRoot, $"Framework/Config/{CONST_FILENAME}.lua")))
            {
                // var env = new LuaEnv();
                // env.AddLoader(LoadEditor);
                //
                // var call = env.LoadString($"return require(\"{CONST_FILENAME}\")");
                // var table = call.Func<LuaTable>(a);
                //
                // table.ForEach<int, string>((x, y) =>
                // {
                //     constList.Add(y);
                // });
                // env.Dispose();
            }

            sb.AppendLine("---@class ConfigRefer");
            foreach (var configName in list)
            {
                sb.AppendLine($"---@field {configName} {configName}Config");
            }
            foreach (var constConfigName in constList)
            {
                sb.AppendLine($"---@field {constConfigName} {constConfigName}");
            }
            sb.AppendLine("");
            
            foreach (var configName in list)
            {
                sb.AppendLine($"---@class {configName}Config");
                sb.AppendLine($"---@field Find fun(self:{configName}Config, key):{configName}ConfigCell");
                sb.AppendLine($"---@field length number");
                sb.AppendLine($"---@field ipairs fun(self:{configName}Config)");
                sb.AppendLine("");
            }
            
            var configCells = Directory.GetFiles(rootFolder, "*ConfigCell.lua", SearchOption.AllDirectories);

            foreach (var fileName in configCells)
            {
                var configName = Path.GetFileName(fileName).Replace("ConfigCell.lua", "");
                if (!list.Contains(configName))
                    continue;
                
                using StreamReader reader = new StreamReader(fileName);
                string content = await reader.ReadToEndAsync();

                sb.AppendLine($"---@class {configName}ConfigCell");
                var regex = new Regex($"function {configName}ConfigCell_mt:(\\w+)\\((.*)\\)");
                foreach (Match function in regex.Matches(content))
                {
                    if (function.Groups[1].Value == "Init")
                        continue;
                    
                    if (function.Groups.Count > 2 && function.Groups[2].Length > 0)
                        sb.AppendLine($"---@field {function.Groups[1].Value} fun(self:{configName}ConfigCell, {function.Groups[2].Value})");
                    else
                        sb.AppendLine($"---@field {function.Groups[1].Value} fun(self:{configName}ConfigCell)");
                }

                sb.AppendLine("");
            }

            sb.AppendLine("-----Const Config-----");
            var constFiles = Directory.GetFiles(rootFolder, "*.lua", SearchOption.AllDirectories).Where(x => !x.EndsWith("Config.lua") && !x.EndsWith("ConfigCell.lua"));
            foreach (var fileName in constFiles)
            {
                var configName = Path.GetFileName(fileName).Replace(".lua", "");
                if (!constList.Contains(configName))
                    continue;
                
                using StreamReader reader = new StreamReader(fileName);
                string content = await reader.ReadToEndAsync();
                sb.AppendLine($"---@class {configName}");
                var regex = new Regex($"function {configName}_mt:(\\w+)\\((.*)\\)");
                foreach (Match function in regex.Matches(content))
                {
                    if (function.Groups[1].Value == "Init")
                        continue;
                    
                    if (function.Groups.Count > 2 && function.Groups[2].Length > 0)
                        sb.AppendLine($"---@field {function.Groups[1].Value} fun(self:{configName}, {function.Groups[2].Value})");
                    else
                        sb.AppendLine($"---@field {function.Groups[1].Value} fun(self:{configName})");
                }

                sb.AppendLine("");
            }

            sb.AppendLine("----Structs-----");
            var structsRootPath = Path.Combine(LuaCExportTools.ExternalLuaSourcePathRoot, "__Config/structs");
            var structFiles = Directory.GetFiles(structsRootPath, "*.lua", SearchOption.TopDirectoryOnly);
            foreach (var fileName in structFiles)
            {
                var configName = Path.GetFileName(fileName).Replace(".lua", "");
                using StreamReader reader = new StreamReader(fileName);
                string content = await reader.ReadToEndAsync();

                sb.AppendLine($"---@class {configName}");
                var regex = new Regex($"function {configName}_mt:(\\w+)\\((.*)\\)");
                foreach (Match function in regex.Matches(content))
                {
                    if (function.Groups[1].Value == "Init")
                        continue;
                    
                    if (function.Groups.Count > 2 && function.Groups[2].Length > 0)
                        sb.AppendLine($"---@field {function.Groups[1].Value} fun(self:{configName}, {function.Groups[2].Value})");
                    else
                        sb.AppendLine($"---@field {function.Groups[1].Value} fun(self:{configName})");
                }

                sb.AppendLine("");
            }

            var writer = File.CreateText(Path.Combine(LuaCExportTools.ExternalLuaSourcePathRoot, "ConfigRefer_LuaHint.lua"));
            await writer.WriteAsync(sb.ToString());
            await writer.FlushAsync();
            writer.Close();
            AssetDatabase.Refresh();
        }
        
        private static byte[] LoadEditor(ref string scriptName)
        {
            try
            {
                return LuaBehaviourEditorUtils.FindTextAsset(scriptName);
            }
            catch (Exception e)
            {
                UnityEngine.Debug.LogError($"[LuaBehaviourEditor] Error = {e}");
                return null;
            }
        }
        #endregion

        public class TableType
        {
            public string name;
            public List<FieldType> fields;
            public bool isStruct;
            public bool isConst;
            public string desc;

            public string Postfix
            {
	            get
	            {
		            if (!desc.IsNullOrEmpty())
			            return $" @{desc}";
		            return string.Empty;
	            }
            }
        }

        public class FieldType
        {
            public string name;
            public string type;
            public string defaultValue;
            public bool isArray;
            public bool isEnum;
            public EnumType enumType;
            public string desc;
            public bool export;

            public string Name
            {
	            get
	            {
		            if (!name.Contains('_')) return ToUpperInitial(name);
		            var builder = new StringBuilder();
		            foreach (var s in name.Split('_', StringSplitOptions.RemoveEmptyEntries))
		            {
			            builder.Append(ToUpperInitial(s));
		            }

		            return builder.ToString();
	            }
            }

            public string Postfix
            {
	            get
	            {
		            if (!desc.IsNullOrEmpty())
			            return $" @{desc}";
		            return string.Empty;
	            }
            }

            private string ToUpperInitial(string word)
            {
	            return word[..1].ToUpper() + word[1..];
            }
        }

        public class EnumType
        {
            public string name;
            public string type;
            public List<EnumValue> values;
        }

        public class EnumValue
        {
            public string name;
            public string value;
        }

        public class CSVTable
        {
	        public string name;
	        public string desc;
	        public Dictionary<string, FieldType> fields;

	        public TableType ToTableType(bool isStruct)
	        {
		        return new TableType()
		        {
			        name = this.name,
			        desc = this.desc,
			        isStruct = isStruct,
			        fields = this.fields.Values.ToList(),
		        };
	        }
        }

        public class Export
        {
	        public string name;
	        public string refName;
	        public List<string> fields;
	        public List<ExportCustomField> customFields;
        }

        public class ExportCustomField
        {
	        public string name;
	        public string type;
        }
    }
}