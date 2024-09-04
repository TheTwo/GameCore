using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using UnityEngine;

namespace DragonReborn
{
	public static partial class ConfigReferExporter
	{
		#region V3

		private static string ConfigRepo { get; }
		private static readonly Dictionary<string, EnumType> _enumTypesMap = new();
		private static readonly Dictionary<string, TableType> _tableTypesMap = new();
		private static readonly Dictionary<string, CSVTable> _csvTablesMap = new();
		private static readonly Dictionary<string, Export> _exportsMap = new();

		private static readonly Dictionary<string, string> _numberTypeMap = new()
		{
			{ "short", "(Int16)" },
			{ "ushort", "(UInt16)" },
			{ "int", "(Int32)" },
			{ "uint", "(UInt32)" },
			{ "byte", "(UInt8)" },
			{ "sbyte", "(Int8)" },
			{ "long", "(Int64)" },
			{ "ulong", "(UInt16)" },
			{ "int8", "(Int8)" },
			{ "int16", "(Int16)" },
			{ "int32", "(Int32)" },
			{ "int64", "(Int64)" },
			{ "uint8", "(UInt8)" },
			{ "uint16", "(UInt16)" },
			{ "uint32", "(UInt32)" },
			{ "uint64", "(UInt64)" },
			
			{ "float", "(Float32)" },
			{ "double", "(Float64)" },
			{ "float32", "(Float32)" },
			{ "float64", "(Float64)" },
			{ "duration", "(Int64(单位ns, 使用时需注意))"}
		};

		// [UnityEditor.MenuItem("DragonReborn/ZZZ &#H")]
		public static void GenerateConfigReferV3()
		{
			if (!Directory.Exists(ConfigRepo))
				return;

			_enumTypesMap.Clear();
			_tableTypesMap.Clear();
			_csvTablesMap.Clear();
			_exportsMap.Clear();
			
			foreach (var file in Directory.GetFiles(ConfigRepo, "*.xml"))
			{
				try
				{
					using var fileStream = new FileStream(file, FileMode.Open);
					using var reader = new StreamReader(fileStream);
					var content = reader.ReadToEnd();
					var document = new XmlDocument();
					document.LoadXml(content.Trim());

					var lastNode = document.LastChild;
					if (lastNode is { Name: "cfgo" })
					{
						for (int i = 0; i < lastNode.ChildNodes.Count; i++)
						{
							var child = lastNode.ChildNodes[i];
							switch (child.Name)
							{
								case "enum":
									CollectEnum(child);
									break;
								case "csv":
									CollectCsvAndExport(child);
									break;
								case "struct":
									CollectStruct(child);
									break;
								case "export":
									CollectExport(child);
									break;
								case "csv_const":
									CollectConstTable(child);
									break;
							}
						}
					}
				}
				catch (Exception)
				{
					Debug.LogErrorFormat("Exception when processing file:{0}", file);
					throw;
				}
			}

			TransExportToType();
			var array = _tableTypesMap.Values.ToList();
			PostProcessEnumAndSpecialType(array, _enumTypesMap);
			PostProcessNumber(array);
			GenV3();
		}

		private static void CollectConstTable(XmlNode node)
		{
			if (node.Attributes == null || node.Attributes.Count == 0)
				return;

			var nameAttr = node.Attributes["name"];
			if (nameAttr == null)
				return;

			var descAttr = node.Attributes?["desc"];
			var constTable = new TableType()
			{
				name = nameAttr.Value,
				fields = new(),
				isConst = true,
				desc = descAttr?.Value ?? string.Empty,
			};

			for (int i = 0; i < node.ChildNodes.Count; i++)
			{
				var export = false;
				var fieldNode = node.ChildNodes[i];
				if (fieldNode is not XmlElement)
					continue;

				if (fieldNode.Attributes?["export"] is { Value: "s" })
					continue;

				if (fieldNode.Attributes?["export"].Value?.Contains("c") ?? false)
					export = true;

				var typeName = fieldNode.Attributes["type"].Value;
				var realTypeName = typeName;
				var isRef = false;
				if (typeName.IndexOf('@') > 0)
				{
					realTypeName = realTypeName.Substring(typeName.IndexOf('@') + 1);
					isRef = true;
				}
				if (realTypeName.IndexOf('[') > 0)
					realTypeName = realTypeName.Substring(0, realTypeName.IndexOf('['));
				var fieldType = new FieldType()
				{
					name = fieldNode.Attributes["name"].Value,
					isEnum = fieldNode.Attributes["type"].Value.StartsWith("enum@"),
					isArray = fieldNode.Attributes["type"].Value.EndsWith("]"),
					desc = fieldNode.Attributes["colName"]?.Value + (isRef ? $"@{realTypeName}" :string.Empty),
					type = isRef ? "number" : realTypeName,
					export = export,
				};
				constTable.fields.Add(fieldType);
			}

			if (constTable.fields.Count > 0)
			{
				_tableTypesMap.Add(constTable.name, constTable);
			}
		}

		private static void CollectExport(XmlNode node)
		{
			if (node.Attributes == null || node.Attributes.Count == 0)
				return;

			var nameAttr = node.Attributes["name"];
			if (nameAttr == null)
				return;

			var toAttr = node.Attributes["to"];
			if (toAttr == null || !toAttr.Value.Contains('c'))
				return;

			var refCsv = nameAttr.Value;
			var fromAttr = node.Attributes["from"];
			if (fromAttr != null)
			{
				refCsv = fromAttr.Value;
			}

			var customAttr = node.Attributes["custom"];
			var allCustom = customAttr is { Value: "true" };

			if (allCustom && refCsv == nameAttr.Value)
			{
				var tableType = new TableType()
				{
					name = nameAttr.Value,
					isStruct = false,
					fields = new(),
					desc = string.Empty,
				};

				for (int i = 0; i < node.ChildNodes.Count; i++)
				{
					var fieldNode = node.ChildNodes[i];
					if (fieldNode is not XmlElement)
						continue;

					if (fieldNode.Attributes?["export"] is { Value: "s" })
						continue;

					var typeName = fieldNode.Attributes["type"].Value;
					var realTypeName = typeName;
					var isRef = false;
					if (realTypeName.IndexOf('@') > 0)
					{
						realTypeName = realTypeName.Substring(realTypeName.IndexOf('@') + 1);
						isRef = true;
					}
					if (realTypeName.IndexOf('[') > 0)
						realTypeName = realTypeName.Substring(0, realTypeName.IndexOf('['));
					var fieldType = new FieldType()
					{
						name = fieldNode.Attributes["name"].Value,
						isEnum = fieldNode.Attributes["type"].Value.StartsWith("enum@"),
						isArray = fieldNode.Attributes["type"].Value.EndsWith("]"),
						desc = fieldNode.Attributes["colName"]?.Value + (isRef ? $"@{realTypeName}" :string.Empty),
						type = isRef ? "number" : realTypeName,
						export = true
					};
					tableType.fields.Add(fieldType);
				}

				if (tableType.fields.Count > 0)
				{
					if (!_tableTypesMap.TryAdd(tableType.name, tableType))
					{
						Debug.LogError(tableType.name);
					}
				}
			}
			else
			{
				var export = new Export()
				{
					name = nameAttr.Value,
					refName = refCsv,
					fields = new(),
					customFields = new()
				};

				for (int i = 0; i < node.ChildNodes.Count; i++)
				{
					var fieldNode = node.ChildNodes[i];
					if (allCustom || fieldNode.Attributes?["custom"] != null &&
					    fieldNode.Attributes["custom"].Value == "true")
					{
						var customField = new ExportCustomField()
						{
							name = fieldNode.Attributes["name"].Value,
							type = fieldNode.Attributes["type"].Value,
						};
						export.customFields.Add(customField);
					}
					else
					{
						export.fields.Add(fieldNode.Attributes?["name"].Value);
					}
				}

				_exportsMap.Add(export.name, export);
			}
		}

		private static void CollectStruct(XmlNode node)
		{
			if (node.Attributes == null || node.Attributes.Count == 0)
				return;

			var nameAttr = node.Attributes["name"];
			if (nameAttr == null)
				return;

			var structType = new TableType()
			{
				name = nameAttr.Value,
				isStruct = true,
				fields = new(),
				desc = string.Empty,
			};

			for (int i = 0; i < node.ChildNodes.Count; i++)
			{
				var export = false;
				var fieldNode = node.ChildNodes[i];
				if (fieldNode is not XmlElement)
					continue;

				if (fieldNode.Attributes?["export"] is { Value: "s" })
					continue;

				var exportAttr = fieldNode.Attributes?["export"];
				if (exportAttr != null && exportAttr.Value.Contains("c"))
					export = true;

				var typeName = fieldNode.Attributes["type"].Value;
				var realTypeName = typeName;
				var isRef = false;
				if (realTypeName.IndexOf('@') > 0)
				{
					realTypeName = realTypeName.Substring(realTypeName.IndexOf('@') + 1);
					isRef = true;
				}
				if (realTypeName.IndexOf('[') > 0)
					realTypeName = realTypeName.Substring(0, realTypeName.IndexOf('['));
				var fieldType = new FieldType()
				{
					name = fieldNode.Attributes["name"].Value,
					isEnum = fieldNode.Attributes["type"].Value.StartsWith("enum@"),
					isArray = fieldNode.Attributes["type"].Value.EndsWith("]"),
					desc = fieldNode.Attributes["colName"]?.Value + (isRef ? $"@{realTypeName}" :string.Empty),
					type = isRef ? "number" : realTypeName,
					export = export,
				};
				structType.fields.Add(fieldType);
			}

			if (structType.fields.Count > 0)
			{
				if (!_tableTypesMap.TryAdd(structType.name, structType))
				{
					Debug.LogError(structType.name);
				}
			}
		}

		private static void CollectCsvAndExport(XmlNode node)
		{
			if (node.Attributes == null || node.Attributes.Count == 0)
				return;

			var nameAttr = node.Attributes["name"];
			if (nameAttr == null)
				return;

			var descAttr = node.Attributes?["desc"];
			var csvTable = new CSVTable()
			{
				name = nameAttr.Value,
				desc = descAttr?.Value,
				fields = new()
			};

			var needExport = false;
			for (int i = 0; i < node.ChildNodes.Count; i++)
			{
				var fieldNode = node.ChildNodes[i];
				var curExport = false;
				// 跳过注释
				if (fieldNode is not XmlElement)
					continue;

				if (fieldNode.Attributes["export"] is { Value: "s" })
					continue;

				if (fieldNode.Attributes["export"] is not null && fieldNode.Attributes["export"].Value.Contains("c"))
				{
					needExport = true;
					curExport = true;
				}

				var typeName = fieldNode.Attributes["type"].Value;
				var realTypeName = typeName;
				var isRef = false;
				if (realTypeName.IndexOf('@') > 0)
				{
					realTypeName = realTypeName.Substring(realTypeName.IndexOf('@') + 1);
					isRef = true;
				}
				if (realTypeName.IndexOf('[') > 0)
					realTypeName = realTypeName.Substring(0, realTypeName.IndexOf('['));
				var fieldType = new FieldType()
				{
					name = fieldNode.Attributes["name"].Value,
					isEnum = fieldNode.Attributes["type"].Value.StartsWith("enum@"),
					isArray = fieldNode.Attributes["type"].Value.EndsWith("]"),
					desc = fieldNode.Attributes["colName"]?.Value + (isRef ? $"@{realTypeName}" :string.Empty),
					type = isRef ? "number" : realTypeName,
					export = curExport,
				};
				csvTable.fields.Add(fieldType.name, fieldType);
			}

			if (csvTable.fields.Count > 0)
			{
				if (needExport)
				{
					var tableType = csvTable.ToTableType(false);
					_tableTypesMap.Add(tableType.name, tableType);
				}
				else
				{
					_csvTablesMap.Add(csvTable.name, csvTable);
				}
			}
		}

		private static void CollectEnum(XmlNode node)
		{
			if (node.Attributes == null || node.Attributes.Count == 0)
				return;

			var nameAttr = node.Attributes["name"];
			if (nameAttr == null)
				return;

			var enumType = new EnumType()
			{
				name = nameAttr.Value,
				type = "number",
				values = new()
			};

			for (int i = 0; i < node.ChildNodes.Count; i++)
			{
				var childNode = node.ChildNodes[i];
				if (childNode is not XmlElement)
					continue;

				if (childNode.Attributes is null)
					continue;

				var value = new EnumValue()
				{
					name = childNode.Attributes["name"].Value,
					value = childNode.Attributes["value"].Value,
				};
				enumType.values.Add(value);
			}

			_enumTypesMap.Add(enumType.name, enumType);
		}

		private static void TransExportToType()
		{
			foreach (var (name, export) in _exportsMap)
			{
				if (!_csvTablesMap.TryGetValue(export.refName, out var refCsv))
				{
					Debug.LogError(export.name);
					continue;
				}

				var tableType = new TableType
				{
					name = name,
					fields = new(),
					isConst = false,
					isStruct = false,
					desc = refCsv.desc
				};

				foreach (var field in export.fields)
				{
					try
					{
						if (!refCsv.fields.TryGetValue(field, out var fieldType))
						{
							Debug.LogError(field);
							continue;
						}

						fieldType.export = true;
						tableType.fields.Add(fieldType);
					}
					catch
					{
						Debug.LogError(field);
						Debug.LogError(refCsv.name);
					}
				}

				foreach (var customField in export.customFields)
				{
					var typeName = customField.type;
					var realTypeName = typeName;
					var isRef = false;
					if (realTypeName.IndexOf('@') > 0)
					{
						realTypeName = realTypeName.Substring(realTypeName.IndexOf('@') + 1);
						isRef = true;
					}
					if (realTypeName.IndexOf('[') > 0)
						realTypeName = realTypeName.Substring(0, realTypeName.IndexOf('['));
					var fieldType = new FieldType
					{
						name = customField.name,
						isEnum = typeName.StartsWith("enum@"),
						isArray = typeName.EndsWith("]"),
						desc = isRef ? $"@{realTypeName}" :string.Empty,
						type = isRef ? "number" : realTypeName,
						export = true,
					};
					tableType.fields.Add(fieldType);
				}

				if (!_tableTypesMap.TryAdd(name, tableType))
				{
					Debug.LogError(name);
				}
			}
		}
		
		private static void PostProcessEnumAndSpecialType(List<TableType> typeList, Dictionary<string, EnumType> enumDic)
		{
			foreach (var typ in typeList)
			{
				foreach (var field in typ.fields)
				{
					if (string.CompareOrdinal(field.type, "bool") == 0)
						field.type = "boolean";
					else if (string.CompareOrdinal(field.type, "i18n") == 0)
					{
						field.type = "string";
						if (field.desc == null)
							field.desc = "(多语言key)";
						else
							field.desc += "(多语言key)";
					}
					else if (enumDic.ContainsKey(field.type))
					{
						field.isEnum = true;
						field.enumType = enumDic[field.type];
						field.type = NumberMap.Contains(enumDic[field.type].type) ? "number" : enumDic[field.type].type;
					}
				}
			}
		}

		private static void PostProcessNumber(List<TableType> typeList)
		{
			foreach (var typ in typeList)
			{
				foreach (var field in typ.fields)
				{
					if (_numberTypeMap.TryGetValue(field.type, out var desc))
					{
						field.type = "number";
						if (field.desc == null)
							field.desc = desc;
						else
							field.desc += desc;
					}
				}
			}
		}

		private static void GenV3()
		{
			var sb = new StringBuilder();
			sb.AppendLine("---@class ConfigRefer");

			var classDeclarer = new StringBuilder();

			foreach (var tableType in _tableTypesMap.Values.OrderBy(x => !x.isConst).ThenBy(x => x.isStruct)
				         .ThenBy(x => x.name))
			{
				if (tableType.isConst)
				{
					sb.AppendLine($"---@field {tableType.name} {tableType.name}{tableType.Postfix}");
					classDeclarer.AppendLine($"---@class {tableType.name}{tableType.Postfix}");
					foreach (var fieldType in tableType.fields)
					{
						if (!fieldType.export) continue;
						if (fieldType.isArray)
						{
							classDeclarer.AppendLine(
								$"---@field {fieldType.Name} fun(self:{tableType.name}, index:number):{fieldType.type}{fieldType.Postfix}");
							classDeclarer.AppendLine(
								$"---@field {fieldType.Name}Length fun(self:{tableType.name}):number");
						}
						else
						{
							classDeclarer.AppendLine(
								$"---@field {fieldType.Name} fun(self:{tableType.name}):{fieldType.type}{fieldType.Postfix}");
						}
					}

					classDeclarer.AppendLine("");
				}
				else
				{
					if (tableType.isStruct)
					{
						classDeclarer.AppendLine($"---@class {tableType.name}{tableType.Postfix}");
						foreach (var fieldType in tableType.fields)
						{
							classDeclarer.AppendLine(
								$"---@field {fieldType.Name} fun(self:{tableType.name}):{fieldType.type}{fieldType.Postfix}");
							if (fieldType.isArray)
							{
								classDeclarer.AppendLine(
									$"---@field {fieldType.Name}Length fun(self:{tableType.name}):number");
							}
						}

						classDeclarer.AppendLine("");
					}
					else
					{
						sb.AppendLine($"---@field {tableType.name} {tableType.name}Config{tableType.Postfix}");
						classDeclarer.AppendLine($"---@class {tableType.name}ConfigCell");
						foreach (var fieldType in tableType.fields)
						{
							if (!fieldType.export) continue;
							if (fieldType.isArray)
							{
								classDeclarer.AppendLine(
									$"---@field {fieldType.Name} fun(self:{tableType.name}ConfigCell, index:number):{fieldType.type}{fieldType.Postfix}");
								classDeclarer.AppendLine(
									$"---@field {fieldType.Name}Length fun(self:{tableType.name}ConfigCell):number");
							}
							else
							{
								classDeclarer.AppendLine(
									$"---@field {fieldType.Name} fun(self:{tableType.name}ConfigCell):{fieldType.type}{fieldType.Postfix}");
							}
						}

						classDeclarer.AppendLine("");
						classDeclarer.AppendLine($"---@class {tableType.name}Config{tableType.Postfix}");
						classDeclarer.AppendLine(
							$"---@field Find fun(self:{tableType.name}Config, key:number):{tableType.name}ConfigCell");
						classDeclarer.AppendLine($"---@field length number @表格长度");
						classDeclarer.AppendLine(
							$"---@field pairs fun(self:{tableType.name}Config):fun():number, {tableType.name}ConfigCell @无序遍历");
						classDeclarer.AppendLine(
							$"---@field ipairs fun(self:{tableType.name}Config):fun():number, {tableType.name}ConfigCell @正序遍历");
						classDeclarer.AppendLine(
							$"---@field inverse_ipairs fun(self:{tableType.name}Config):fun():number, {tableType.name}ConfigCell @倒序遍历");
						classDeclarer.AppendLine("");
					}
				}
			}

			sb.AppendLine("");

			var writer =
				File.CreateText(Path.Combine(LuaCExportTools.ExternalLuaSourcePathRoot, "ConfigRefer_LuaHint.lua"));
			writer.Write(sb.ToString());
			writer.Write(classDeclarer.ToString());
			writer.Flush();
			writer.Close();
		}

		#endregion
	}
}
