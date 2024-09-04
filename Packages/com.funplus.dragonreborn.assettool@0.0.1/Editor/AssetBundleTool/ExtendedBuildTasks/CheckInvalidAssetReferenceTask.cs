using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Pipeline.Tasks;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 提供基于资源路径的检查， 记录不符合预期的资源
	/// </summary>
	public class CheckInvalidAssetReferenceTask : IBuildTask
	{
		int IBuildTask.Version => 1;
	    
		// ReSharper disable ArrangeTypeMemberModifiers
		// ReSharper disable InconsistentNaming
		[InjectContext(ContextUsage.In)] IInValidAssetCheckRule m_CheckRule;
		[InjectContext(ContextUsage.In)] IDependencyData m_DependencyData;
		[InjectContext(ContextUsage.In, true)] IBundleExplictObjectLayout m_Layout;
		// ReSharper disable once NotAccessedField.Local
		[InjectContext(ContextUsage.Out, true)] IInValidAssetReferenceRecord m_Record;
		// ReSharper restore InconsistentNaming
		// ReSharper restore ArrangeTypeMemberModifiers

		// ReSharper disable once UnusedMember.Local
		private const int ErrorLogCountLimit = 20;

		private CheckInvalidAssetReferenceTask() { }

		ReturnCode IBuildTask.Run()
		{
			var failBuild = m_CheckRule.FailBuildIfNotPass;
			var ignoreGuids = m_CheckRule.IgnoreGuids;
			var errorReferencedPaths = new Dictionary<ObjectIdentifier, (string, HashSet<string>)>();
			var errorGuids = new HashSet<GUID>();
			var allObjectIdentifier = new HashSet<ObjectIdentifier>();
			allObjectIdentifier.UnionWith(m_DependencyData.AssetInfo.SelectMany(t=>t.Value.includedObjects));
			allObjectIdentifier.UnionWith(m_DependencyData.AssetInfo.SelectMany(t=>t.Value.referencedObjects));
			allObjectIdentifier.UnionWith(m_DependencyData.SceneInfo.SelectMany(t=>t.Value.referencedObjects));
			if (null != m_Layout)
			{
				//已经显示指定bundle的资源 认为是合法资源 不管原始路径是啥
				allObjectIdentifier.ExceptWith(m_Layout.ExplicitObjectLocation.Keys);
			}
			foreach (var objectIdentifier in allObjectIdentifier)
			{
				if (ignoreGuids.Contains(objectIdentifier.guid)) continue;
				if (IsAssetPathValid(in objectIdentifier, out var assetPath)) continue;
				if (errorReferencedPaths.TryGetValue(objectIdentifier, out var info)) continue;
				info = (assetPath, new HashSet<string>());
				errorReferencedPaths.Add(objectIdentifier, info);
				errorGuids.Add(objectIdentifier.guid);
			}
			foreach (var (guid, assetLoadInfo) in m_DependencyData.AssetInfo)
			{
				if (errorGuids.Contains(guid)) continue;
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				foreach (var referencedObject in assetLoadInfo.referencedObjects)
				{
					if (!errorReferencedPaths.TryGetValue(referencedObject, out var info)) continue;
					info.Item2.Add(assetPath);
				}
			}
			foreach (var (guid, sceneDependencyInfo) in m_DependencyData.SceneInfo)
			{
				if (errorGuids.Contains(guid)) continue;
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				foreach (var referencedObject in sceneDependencyInfo.referencedObjects)
				{
					if (!errorReferencedPaths.TryGetValue(referencedObject, out var info)) continue;
					info.Item2.Add(assetPath);
				}
			}
			if (errorReferencedPaths.Count > 0)
			{
				m_Record = new InValidAssetReferenceRecord(errorReferencedPaths);
			}
			if (failBuild && errorReferencedPaths.Count > 0)
			{
				return ReturnCode.Error;
			}
			return ReturnCode.Success;
		}

		private bool IsAssetPathValid(in ObjectIdentifier objectIdentifier, out string assetPath)
		{
			return m_CheckRule.IsAssetPathValid(in objectIdentifier, out assetPath);
		}
	    
		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks)
		{
			if (null == buildTasks) return false;
			var ret = BuildTaskHelper.AttachBuildTask<CheckInvalidAssetReferenceTask, PostDependencyCallback>(buildTasks,
				() => new CheckInvalidAssetReferenceTask(), false);
			return ret;
		}

		public class InValidAssetReferenceRecord : IInValidAssetReferenceRecord
		{
			private readonly Dictionary<ObjectIdentifier, (string, HashSet<string>)> _record;

			public InValidAssetReferenceRecord(Dictionary<ObjectIdentifier, (string, HashSet<string>)> record)
			{
				_record = record;
			}

			void IInValidAssetReferenceRecord.WriteToFile(string path)
			{
				var tmpDic =
					new Dictionary<string, Dictionary<string, HashSet<ObjectIdentifier>>>();
				foreach (var (referencedObj, (objectPath, referenceAssetPaths)) in _record)
				{
					if (!tmpDic.TryGetValue(objectPath, out var info))
					{
						info = new Dictionary<string, HashSet<ObjectIdentifier>>();
						tmpDic.Add(objectPath, info);
					}
					foreach (var referenceAssetPath in referenceAssetPaths)
					{
						if (!info.TryGetValue(referenceAssetPath, out var refObjSet))
						{
							refObjSet = new HashSet<ObjectIdentifier>();
							info.Add(referenceAssetPath, refObjSet);
						}
						refObjSet.Add(referencedObj);
					}
					
				}
				var values = tmpDic.Select(kv => (kv.Key, kv.Value)).ToList();
				values.Sort((a,b)=>string.CompareOrdinal(a.Item1, b.Item1));
			    
				using var sw = new StreamWriter(path, false, Encoding.UTF8);
				using JsonWriter writer = new JsonTextWriter(sw);
				writer.Formatting = Formatting.Indented;
				writer.WriteStartObject();
				foreach (var (assetPath, refMap) in values)
				{
					writer.WritePropertyName(assetPath);
					writer.WriteStartObject();
					writer.WritePropertyName("ref by");
					writer.WriteStartArray();
					var refList = refMap.ToArray();
					Array.Sort(refList, (a,b)=>string.CompareOrdinal(a.Key, b.Key));
					foreach (var kv in refList)
					{
						writer.WriteStartObject();
						writer.WritePropertyName("asset");
						writer.WriteValue(kv.Key);
						writer.WritePropertyName("ObjectIdentifiers:");
						writer.WriteStartArray();
						var tmpArray = kv.Value.ToArray();
						Array.Sort(tmpArray, (obj1, obj2) =>
						{
							var ret = obj1.guid.CompareTo(obj2.guid);
							if (ret == 0)
							{
								ret = obj1.localIdentifierInFile.CompareTo(obj2.localIdentifierInFile);
							}
							return ret;
						});
						foreach (var type in tmpArray)
						{
							writer.WriteStartObject();
							writer.WritePropertyName("guid");
							writer.WriteValue(type.guid.ToString());
							writer.WritePropertyName("localIdentifierInFile");
							writer.WriteValue(type.localIdentifierInFile);
							writer.WritePropertyName("filePath");
							writer.WriteValue(type.filePath);
							writer.WritePropertyName("fileType");
							writer.WriteValue(type.fileType.ToString());
							writer.WritePropertyName("types");
							writer.WriteStartArray();
							foreach (var usedType in BuildTaskHelper.GetSortedUniqueTypesForObject(type))
							{
								writer.WriteValue(usedType.FullName);
							}
							writer.WriteEndArray();
							writer.WriteEndObject();
						}
						writer.WriteEndArray();
						writer.WriteEndObject();
					}
					writer.WriteEndArray();
					writer.WriteEndObject();
				}
				writer.WriteEndObject();

				GeneratePlainVersion(values, "Assets/__UI/", "资源异常UI.log");
				GeneratePlainVersion(values, "Assets/__Art/", "资源异常Art.log");
			}

			// ReSharper disable once InconsistentNaming
			private const int MAX_DISPLAY = 999;
			private void GeneratePlainVersion(IReadOnlyList<(string, Dictionary<string, HashSet<ObjectIdentifier>>)> values, string filter, string logFilename)
			{
				var logPath = Path.Combine(Application.dataPath, $"../Logs/{logFilename}");
				if (File.Exists(logPath))
				{
					File.Delete(logPath);
				}

				if (values == null)
				{
					return;
				}

				var sb = new StringBuilder();
				var hasItem = false;
				foreach (var (assetPath, refMap) in values)
				{
					var refList = refMap.ToArray();
					Array.Sort(refList, (a, b) => string.CompareOrdinal(a.Key, b.Key));

					refList = Filter(refList, filter);
					if (refList.Length > 0)
					{
						hasItem = true;
						sb.AppendLine($"{assetPath}");

						var counter = 0;
						foreach (var (usedAssetPath, _) in refList)
						{
							counter++;
							if (counter > MAX_DISPLAY)
							{
								sb.AppendLine("\t...");
								break;
							}

							sb.AppendLine($"\t{usedAssetPath}");
						}
					}
				}

				if (hasItem)
				{
					File.WriteAllText(logPath, sb.ToString());
				}
			}

			private KeyValuePair<string, HashSet<ObjectIdentifier>>[] Filter(KeyValuePair<string, HashSet<ObjectIdentifier>>[] refList, string filter)
			{
				var list = new List<KeyValuePair<string, HashSet<ObjectIdentifier>>>();
				foreach (var (usedAssetPath, usageTypes) in refList)
				{
					if (usedAssetPath.Contains(filter))
					{
						list.Add(new KeyValuePair<string, HashSet<ObjectIdentifier>>(usedAssetPath, usageTypes));
					}
				}
				return list.ToArray();
			}

			[MenuItem("DragonReborn/资源工具箱/资源规范/导出需要检查的异常引用资源清单(需要打包后)")]
			private static void Do()
			{
				var inputFile = Path.GetFullPath("Logs/InValidAssetReferenceRecord.json");//EditorUtility.OpenFilePanel("", Application.dataPath, "*");
				if (!File.Exists(inputFile)) return;
				var all = File.ReadAllText(inputFile);
				using var reader = new StringReader(all);
				using var json = new JsonTextReader(reader);
				var output = EditorUtility.SaveFilePanel("", Application.dataPath, "", "xlsx");
				var wb = new XSSFWorkbook();
				WriteAssetsSheet(wb, json);
				using var fs = new FileStream(output, FileMode.Create);
				wb.Write(fs);
				fs.Close();
			}
			
			private static void WriteAssetsSheet(XSSFWorkbook wb, JsonReader jsonReader)
			{
				var tmpMap = new Dictionary<string, Dictionary<string, Tuple<string, HashSet<long>>>>();
				var jsonData = (JObject)JToken.ReadFrom(jsonReader);
				var sheet1 = wb.CreateSheet("检查清单");
				sheet1.SetColumnWidth(0, 100 * 256);

				foreach (var (referencedAssetPath, jData) in jsonData)
				{
					var array = jData?.Value<JArray>("ref by");
					if (array is not { Count: > 0 }) continue;
					foreach (var value in array)
					{
						var assetPath = value.Value<string>("asset");
						if (string.IsNullOrWhiteSpace(assetPath)) continue;
						var refObj = value.Value<JArray>("ObjectIdentifiers:");
						if (refObj is not { Count: > 0 }) continue;
						if (!tmpMap.TryGetValue(assetPath, out var tuples))
						{
							tuples = new Dictionary<string, Tuple<string, HashSet<long>>>();
							tmpMap.Add(assetPath, tuples);
						}

						foreach (var objectIdentifier in refObj)
						{
							var guid = objectIdentifier.Value<string>("guid");
							var localId = objectIdentifier.Value<long>("localIdentifierInFile");
							if (string.IsNullOrWhiteSpace(guid)) continue;
							if (!tuples.TryGetValue(referencedAssetPath, out var tuple))
							{
								tuple = new Tuple<string, HashSet<long>>(guid, new HashSet<long>());
								tuples.Add(referencedAssetPath, tuple);
							}

							tuple.Item2.Add(localId);
						}
					}
				}

				var maxRefCol = tmpMap.Max(v => v.Value.Count);
				var baseStyle = wb.CreateCellStyle();
				var integerFormat = wb.CreateDataFormat().GetFormat("0");
				baseStyle.FillPattern = FillPattern.SolidForeground;
				baseStyle.FillForegroundColor = IndexedColors.White.Index;
				baseStyle.DataFormat = integerFormat;
				var titleRow = sheet1.CreateRow(0);
				var cell = titleRow.CreateCell(0);
				cell.SetCellType(CellType.String);
				cell.SetCellValue("资源路径");
				for (var i = 0; i < maxRefCol; i++)
				{
					cell = titleRow.CreateCell(3 * i + 1);
					cell.SetCellType(CellType.String);
					cell.SetCellValue($"异常引用路径({i + 1})");
					cell = titleRow.CreateCell(3 * i + 2);
					cell.SetCellType(CellType.String);
					cell.SetCellValue("guid");
					cell = titleRow.CreateCell(3 * i + 3);
					cell.SetCellType(CellType.String);
					cell.SetCellValue("localFileId");
				}

				var dicKeys = tmpMap.Keys.ToList();
				dicKeys.Sort(string.CompareOrdinal);
				for (var i = 0; i < dicKeys.Count; i++)
				{
					titleRow = sheet1.CreateRow(i + 1);
					cell = titleRow.CreateCell(0);
					var assetPath = dicKeys[i];
					cell.SetCellType(CellType.String);
					cell.SetCellValue(assetPath);
					var refDic = tmpMap[assetPath];
					var refKeys = refDic.Keys.ToList();
					refKeys.Sort(StringComparer.Ordinal);
					for (var j = 0; j < refKeys.Count; j++)
					{
						cell = titleRow.CreateCell(3 * j + 1);
						cell.SetCellType(CellType.String);
						var refAssetPath = refKeys[j];
						cell.SetCellValue(refAssetPath);
						var refValue = refDic[refAssetPath];
						cell = titleRow.CreateCell(3 * j + 2);
						cell.SetCellType(CellType.String);
						cell.SetCellValue(refValue.Item1);
						var localIds = refValue.Item2.ToList();
						localIds.Sort();
						cell = titleRow.CreateCell(3 * j + 3);
						cell.SetCellType(CellType.String);
						cell.SetCellValue(string.Join(',', localIds));
					}
				}

				sheet1.CreateFreezePane(1, 1);
			}
		}
	}
}
