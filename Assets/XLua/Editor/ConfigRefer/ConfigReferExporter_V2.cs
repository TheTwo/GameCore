using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace DragonReborn
{
	public static partial class ConfigReferExporter
	{
		#region V2

		private const string TABLE_DEFINE = @"table (\w+) \{";
		private const string STRUCT_DEFINE = @"struct (\w+) \{";
		private const string FIELD_DEFINE = @"(\w+):(\[?\w+\]?);";
		private const string FIELD_WITH_DEFAULT = @"(\w+):(\[?\w+\]?) = (\w+);";
		private const string ROOT_TYPE = @"root_type (\w+);";
		private const string ARRAY_DEFINE = @"\[(.+)\]";
		private const string ENUM_DEFINE = @"enum (\w+):(\w+) \{";
		private const string ENUM_VALUE = @"(\w+) = (\w+),";

		private static HashSet<string> NumberMap = new HashSet<string>()
		{
			"byte",
			"sbyte",
			"short",
			"ushort",
			"int",
			"uint",
			"float",
			"long",
			"ulong",
			"double",
			"int8",
			"uint8",
			"int16",
			"uint16",
			"int32",
			"uint32",
			"int64",
			"uint64",
			"float32",
			"float64",
			"duration",
		};

		public static void GenerateConfigReferV2()
		{
			var fbsRoot = LogicRepo;
			if (!Directory.Exists(fbsRoot))
			{
				Debug.LogError("fbs目录不存在，无法生成提示代码");
				return;
			}

			var files = Directory.GetFiles(fbsRoot, "*.fbs", SearchOption.AllDirectories);
			var array = new List<TableType>();
			var rootArray = new List<TableType>();
			var enumArray = new List<EnumType>();
			foreach (var file in files)
			{
				GetSchemaFromFbs(file, out var types, out var root_type, out var enums);
				array.AddRange(types);
				if (root_type != null)
				{
					rootArray.Add(root_type);
				}

				enumArray.AddRange(enums);
			}

			PostProcessFieldType(array, enumArray.ToDictionary(x => x.name));
			Gen(array, rootArray);
		}

		private static void Gen(List<TableType> array, List<TableType> rootArray)
		{
			var sb = new StringBuilder();
			sb.AppendLine("---@class ConfigRefer");
			foreach (var root in rootArray)
			{
				var name = Is2DTable(root) ? Get2DTableName(root) : root.name;
				sb.AppendLine($"---@field {name} {root.name}");
			}

			sb.AppendLine("");
			foreach (var table in array)
			{
				if (Is2DTable(table))
				{
					sb.AppendLine($"---@class {table.name}:ConfigWrap");
					sb.AppendLine($"---@field Find fun(self:{table.name}, key:number):{table.name}Cell");
					sb.AppendLine($"---@field length number");
					sb.AppendLine($"---@field ipairs fun(self:{table.name}):fun():number, {table.name}Cell");
				}
				else
				{
					sb.AppendLine($"---@class {table.name}");
					foreach (var field in table.fields)
					{
						if (field.isArray)
						{
							sb.AppendLine($"---@field {field.name} fun(self:{table.name}, index:number):{field.type}");
							sb.AppendLine($"---@field {field.name}Length fun(self:{table.name}):number");
						}
						else if (field.isEnum)
						{
							sb.AppendLine(
								$"---@field {field.name} fun(self:{table.name}):{field.type} 枚举来自{field.enumType.name}");
						}
						else
						{
							sb.AppendLine($"---@field {field.name} fun(self:{table.name}):{field.type}");
						}
					}
				}

				sb.AppendLine("");
			}

			var writer =
				File.CreateText(Path.Combine(LuaCExportTools.ExternalLuaSourcePathRoot, "ConfigRefer_LuaHint.lua"));
			writer.Write(sb.ToString());
			writer.Flush();
			writer.Close();
			AssetDatabase.Refresh();
		}

		private static bool Is2DTable(TableType root)
		{
			return root.fields.Count == 1 && root.fields[0].name == "Cells";
		}

		private static string Get2DTableName(TableType root)
		{
			return root.name[..^6];
		}

		private static void PostProcessFieldType(List<TableType> typeList, Dictionary<string, EnumType> enumDic)
		{
			foreach (var typ in typeList)
			{
				foreach (var field in typ.fields)
				{
					if (NumberMap.Contains(field.type))
						field.type = "number";
					else if (string.CompareOrdinal(field.type, "bool") == 0)
						field.type = "boolean";
					else if (enumDic.ContainsKey(field.type))
					{
						field.isEnum = true;
						field.enumType = enumDic[field.type];
						field.type = NumberMap.Contains(enumDic[field.type].type) ? "number" : enumDic[field.type].type;
					}
				}
			}
		}

		private static void GetSchemaFromFbs(string fileName, out List<TableType> types, out TableType root_type,
			out List<EnumType> enums)
		{
			using StreamReader reader = new StreamReader(fileName);
			string line = reader.ReadLine();
			int state = 0;

			var typeMap = new Dictionary<string, TableType>();

			types = new List<TableType>();
			root_type = null;
			enums = new List<EnumType>();

			TableType newTable = null;
			EnumType newEnum = null;
			while (line != null)
			{
				if (state == 0)
				{
					if (Regex.Match(line, TABLE_DEFINE).Success)
					{
						newTable = new TableType()
						{
							name = Regex.Match(line, TABLE_DEFINE).Groups[1].Value,
							fields = new List<FieldType>()
						};
						state = 1;
					}

					if (Regex.Match(line, STRUCT_DEFINE).Success)
					{
						newTable = new TableType()
						{
							name = Regex.Match(line, STRUCT_DEFINE).Groups[1].Value,
							fields = new List<FieldType>(),
							isStruct = true,
						};
						state = 1;
					}

					if (Regex.Match(line, ROOT_TYPE).Success)
					{
						root_type = typeMap[Regex.Match(line, ROOT_TYPE).Groups[1].Value];
					}

					if (Regex.Match(line, ENUM_DEFINE).Success)
					{
						newEnum = new EnumType()
						{
							name = Regex.Match(line, ENUM_DEFINE).Groups[1].Value,
							type = Regex.Match(line, ENUM_DEFINE).Groups[2].Value,
							values = new List<EnumValue>()
						};
						state = 2;
					}
				}

				if (state == 1)
				{
					if (Regex.Match(line, FIELD_WITH_DEFAULT).Success)
					{
						var newField = new FieldType()
						{
							name = Regex.Match(line, FIELD_WITH_DEFAULT).Groups[1].Value,
							type = Regex.Match(line, FIELD_WITH_DEFAULT).Groups[2].Value,
							defaultValue = Regex.Match(line, FIELD_WITH_DEFAULT).Groups[3].Value,
						};
						if (Regex.Match(newField.type, ARRAY_DEFINE).Success)
						{
							newField.type = Regex.Match(newField.type, ARRAY_DEFINE).Groups[1].Value;
							newField.isArray = true;
						}

						newTable.fields.Add(newField);
					}
					else if (Regex.Match(line, FIELD_DEFINE).Success)
					{
						var newField = new FieldType()
						{
							name = Regex.Match(line, FIELD_DEFINE).Groups[1].Value,
							type = Regex.Match(line, FIELD_DEFINE).Groups[2].Value
						};
						if (Regex.Match(newField.type, ARRAY_DEFINE).Success)
						{
							newField.type = Regex.Match(newField.type, ARRAY_DEFINE).Groups[1].Value;
							newField.isArray = true;
						}

						newTable.fields.Add(newField);
					}

					if (line.StartsWith('}'))
					{
						typeMap.Add(newTable.name, newTable);
						newTable = null;
						state = 0;
					}
				}

				if (state == 2)
				{
					if (Regex.Match(line, ENUM_VALUE).Success)
					{
						var newEnumValue = new EnumValue()
						{
							name = Regex.Match(line, ENUM_VALUE).Groups[1].Value,
							value = Regex.Match(line, ENUM_VALUE).Groups[2].Value
						};
						newEnum.values.Add(newEnumValue);
					}

					if (line.StartsWith('}'))
					{
						enums.Add(newEnum);
						newEnum = null;
						state = 0;
					}
				}

				line = reader.ReadLine();
			}

			types = typeMap.Values.ToList();
		}

		#endregion
	}
}
