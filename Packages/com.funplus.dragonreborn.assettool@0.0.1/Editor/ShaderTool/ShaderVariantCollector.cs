using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using System.Linq;
using System.Drawing.Drawing2D;
using System.CodeDom;

namespace DragonReborn.AssetTool.Editor
{
	public class ShaderVariantCollector : UnityEditor.Editor
	{
		public static readonly string ShaderVariantPath = "Assets/__Shader/ShaderCollector";
		public static readonly string[] ResPathArray = new[] {
			"Assets/__Art",
			"Assets/__UI"
		};

		private class SVRShader
		{
			public string shaderName;
			public List<SVRShaderVaraint> shaderVaraints;
		}

		private class SVRShaderVaraint
		{
			public List<string> keywords;
			public List<string> usedByMaterials;
		}

		private static Dictionary<string, SVRShader> _scanResults = new();


		[MenuItem("DragonReborn/资源工具箱/Shader工具/收集shader变体")]
		public static void CollectShaders()
		{
			try
			{
				_scanResults.Clear();
				DoCollect();
			}
			catch (Exception e)
			{
				NLogger.Error($"{e.Message} {e.StackTrace}");
			}
			finally
			{
				EditorUtility.ClearProgressBar();
			}
		}

		[MenuItem("DragonReborn/资源工具箱/Shader工具/删除所有shader变体")]
		public static void ClearShaderVariant()
		{
			SafeClearDir(ShaderVariantPath);
			NLogger.Log("Delete all shader variant completed!");
		}

		[MenuItem("DragonReborn/资源工具箱/Shader工具/静态分析shader变体")]
		public static void AnalyzeShaderVaraints()
		{
			var finalMats = CollectFinalMats();
			ExportCsv(finalMats);
		}

		private const string TargetShaderName = "ToonSimpleLit";
		[MenuItem("DragonReborn/资源工具箱/材质工具/自动调整材质RenderQueue")]
		public static void BatchModifyRenderQueue()
		{
			var finalMats = CollectFinalMats();
			AutoModifyRenderQueue(finalMats);
		}

		[MenuItem("DragonReborn/资源工具箱/材质工具/自动恢复材质RenderQueue")]
		public static void BatchRestoreRenderQueue()
		{
			var finalMats = CollectFinalMats();
			AutoRestoreRenderQueue(finalMats);
		}

		private static void AutoModifyRenderQueue(Dictionary<string, Dictionary<string, List<Material>>> finalMats)
		{
			foreach (var (shaderName, matDict) in finalMats)
			{
				if (!shaderName.EndsWith(TargetShaderName))
				{
					NLogger.Log($"{shaderName}忽略...");
					continue;
				}

				ProcessMaterials(shaderName, matDict);
			}
		}

		private static void AutoRestoreRenderQueue(Dictionary<string, Dictionary<string, List<Material>>> finalMats)
		{
			var backupPath = Path.Combine(Application.dataPath, $"../Save/MaterialRenderQueueModify.json");
			if (!File.Exists(backupPath))
			{
				NLogger.Error($"恢复材质RenderQueue失败，没有找到{backupPath}");
				return;
			}

			var allContents = File.ReadAllText(backupPath);
			var history = DataUtils.FromJson<Dictionary<string, RQModifyHistory>>(allContents);
			foreach (var (shaderName, matDict) in finalMats)
			{
				if (!shaderName.EndsWith(TargetShaderName))
				{
					NLogger.Log($"{shaderName}忽略...");
					continue;
				}

				foreach (var (keywords, matList) in matDict)
				{
					foreach (var mat in matList)
					{
						if (history.ContainsKey(mat.name))
						{
							var rqModify = history[mat.name];
							if (mat.renderQueue == rqModify.newRQ)
							{
								mat.renderQueue = rqModify.oldRQ;
								NLogger.Log($"材质{mat.name}的RenderQueue恢复: 从{rqModify.newRQ}到{rqModify.oldRQ}");
							}
						}
					}
				}
			}

			NLogger.Log("恢复材质RenderQueue完成");
			File.Delete(backupPath);

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
		}

		private class RQModifyHistory
		{
			public int oldRQ;
			public int newRQ;
		}

		private static void ProcessMaterials(string shaderName, Dictionary<string, List<Material>> dict)
		{
			NLogger.Log($"{shaderName}开始调整关联材质的RenderQueue");

			var path = Path.Combine(Application.dataPath, $"../Logs/MaterialRenderQueueInfo.csv");
			using var writer = new StreamWriter(path);
			writer.WriteLine("ShaderName,Keywords,oldRQs,newRQs");

			var keywordsList = dict.Keys.ToList<string>();
			keywordsList.Sort();

			int offset = 1;
			var allHistory = new Dictionary<string, RQModifyHistory>();
			foreach (var keywords in keywordsList)
			{
				var materials = dict[keywords];
				HashSet<int> set = new();
				foreach (var mat in materials)
				{
					var materialName = mat.name;
					var modifyLog = new RQModifyHistory();
					allHistory[materialName] = modifyLog;

					set.Add(mat.renderQueue);
					modifyLog.oldRQ = mat.renderQueue;
					mat.renderQueue += offset;
					modifyLog.newRQ = mat.renderQueue;
					NLogger.Log($"材质{materialName}的RenderQueue调整，从{modifyLog.oldRQ}到{modifyLog.newRQ}");
				}
				
				var listOld = new List<string>();
				var listNew = new List<string>();
				foreach (var rq in set)
				{
					listOld.Add(rq.ToString());
					listNew.Add((rq + offset).ToString());
				}

				writer.WriteLine($"{shaderName},{keywords},{string.Join(";", listOld)},{string.Join(";", listNew)}");

				offset++;
			}

			writer.Flush();
			writer.Close();

			var rqModifyLog = DataUtils.ToJson(allHistory, Newtonsoft.Json.Formatting.Indented);
			var rqModifyLogPath = Path.Combine(Application.dataPath, $"../Save/MaterialRenderQueueModify.json");
			File.WriteAllText(rqModifyLogPath, rqModifyLog);

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
		}

		static void CreateDir(string folderPath)
		{
			if (!Directory.Exists(folderPath))
			{
				Directory.CreateDirectory(folderPath);
			}
		}

		static void DeleteDirectory(string dirPath)
		{
			string[] files = Directory.GetFiles(dirPath);
			string[] dirs = Directory.GetDirectories(dirPath);

			foreach (string file in files)
			{
				File.SetAttributes(file, FileAttributes.Normal);
				File.Delete(file);
			}

			foreach (string dir in dirs)
			{
				DeleteDirectory(dir);
			}

			Directory.Delete(dirPath, false);
		}

		static bool SafeClearDir(string folderPath)
		{
			try
			{
				if (Directory.Exists(folderPath))
				{
					DeleteDirectory(folderPath);
				}
				Directory.CreateDirectory(folderPath);
				return true;
			}
			catch (System.Exception ex)
			{
				NLogger.Error(string.Format("SafeClearDir failed! path = {0} with err = {1}", folderPath, ex.Message));
				return false;
			}

		}

		static ShaderVariantCollector()
		{
		}
/*
 ShaderUtil.GetShaderVariantEntriesFiltered
internal static void GetShaderVariantEntriesFiltered(
      Shader shader,
      int maxEntries,
      string[] filterKeywords,
      ShaderVariantCollection excludeCollection,
      out int[] passTypes,
      out string[] keywordLists,
      out string[] remainingKeywords)
 */
		private delegate void GetShaderVariantEntriesFilteredFunc(Shader shader,
			int maxEntries,
			string[] filterKeywords,
			ShaderVariantCollection excludeCollection,
			out int[] passTypes,
			out string[] keywordLists,
			out string[] remainingKeywords);
		
		private static GetShaderVariantEntriesFilteredFunc _getShaderVariantEntries;
		private static ShaderVariantCollection _excludeCollectionDummy;
		public struct ShaderVariantData
		{
			public int[] passTypes;
			public string[] keywordLists;
			public string[] remainingKeywords;
		}

		private static ShaderVariantData GetShaderVariantEntriesFiltered(Shader shader, string[] SelectedKeywords)
		{
			if (_getShaderVariantEntries == null)
			{
				var methodInfo = typeof(ShaderUtil).GetMethod("GetShaderVariantEntriesFiltered", BindingFlags.NonPublic | BindingFlags.Static);
				if (null != methodInfo)
				{
					_getShaderVariantEntries =
						(GetShaderVariantEntriesFilteredFunc)Delegate.CreateDelegate(
							typeof(GetShaderVariantEntriesFilteredFunc), methodInfo);
				}
			}
			_excludeCollectionDummy ??= new ShaderVariantCollection();

			var types = Array.Empty<int>();
			var keywords = Array.Empty<string>();
			var remainingKeywords = Array.Empty<string>();
			_getShaderVariantEntries?.Invoke(shader, 32, SelectedKeywords, _excludeCollectionDummy, out types, out keywords, out remainingKeywords );

			var passTypes = new List<int>();
			foreach (var type in types)
			{
				if (!passTypes.Contains(type))
				{
					passTypes.Add(type);
				}
			}

			ShaderVariantData svd = new ShaderVariantData()
			{
				passTypes = passTypes.ToArray(),
				keywordLists = keywords,
				remainingKeywords = remainingKeywords
			};

			return svd;
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="path"></param>
		/// <returns></returns>
		private static Dictionary<string, List<Material>> FindAllMaterials(string[] pathArray)
		{
			var materials = AssetDatabase.FindAssets("t:Material", pathArray);

			int idx = 0;
			var matDic = new Dictionary<string, List<Material>>();
			foreach (var guid in materials)
			{
				var matPath = AssetDatabase.GUIDToAssetPath(guid);
				EditorUtility.DisplayProgressBar($"Collect Shader {matPath}", "Find All Materials", (float)idx++ / materials.Length);
				var mat = AssetDatabase.LoadMainAssetAtPath(matPath) as Material;
				if (mat)
				{
					if (matDic.TryGetValue(mat.shader.name, out var list) == false)
					{
						list = new List<Material>();
						matDic.Add(mat.shader.name, list);
					}
					list.Add(mat);
				}
			}
			return matDic;
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="increment">是否增量打包</param>
		private static void DoCollect(bool increment = false)
		{
			if (increment)
			{
				CreateDir(ShaderVariantPath);
			}
			else
			{
				ClearShaderVariant();
				AssetDatabase.Refresh();
			}

			//---------------------------------------------------------------
			// collect all key words
			var finalMats = CollectFinalMats();

			//---------------------------------------------------------------
			// collect all variant
			CreateOrUpdateShaderVaraints(finalMats);

			//---------------------------------------------------------------
			// export log
			ExportCsv(finalMats);
		}

		private static Dictionary<string, Dictionary<string, List<Material>>> CollectFinalMats()
		{
			// find all materials
			var matDic = FindAllMaterials(ResPathArray);

			Dictionary<string, Dictionary<string, List<Material>>> finalMats = new();
			List<string> temp = new List<string>();
			int idx = 0;
			foreach (var item in matDic)
			{
				var shaderName = item.Key;
				EditorUtility.DisplayProgressBar($"Collect Shader {shaderName}", "Collect Key words", (float)idx++ / matDic.Count);
				if (finalMats.TryGetValue(shaderName, out var matDict) == false)
				{
					matDict = new();
					finalMats.Add(shaderName, matDict);
				}

				foreach (var mat in item.Value)
				{
					temp.Clear();
					string[] keyWords = mat.shaderKeywords;
					temp.AddRange(keyWords);

					if (mat.enableInstancing)
					{
						temp.Add("enableInstancing");
					}

					if (temp.Count == 0)
					{
						continue;
					}

					temp.Sort();
					string pattern = string.Join(";", temp);
					if (!matDict.ContainsKey(pattern))
					{
						matDict.Add(pattern, new List<Material>());
					}
					var list = matDict[pattern];
					list.Add(mat);
				}
			}

			EditorUtility.ClearProgressBar();
			return finalMats;
		}

		private static void CreateOrUpdateShaderVaraints(Dictionary<string, Dictionary<string, List<Material>>> finalMats)
		{
			int idx = 0;
			
			AssetDatabase.StartAssetEditing();
			try
			{
				foreach (var kv in finalMats)
				{
					var shaderFullName = kv.Key;
					var matDict = kv.Value;
	
					if (matDict.Count == 0)
					{
						continue;
					}
	
					EditorUtility.DisplayProgressBar($"Collect Shader {shaderFullName}", "General Shader Variant", (float)idx++ / finalMats.Count);
					if (shaderFullName.Contains("InternalErrorShader"))
					{
						continue;
					}
	
					var shader = Shader.Find(shaderFullName);
					var path = $"{ShaderVariantPath}/{shaderFullName.Replace("/", "_")}.shadervariants";
					bool alreadyExsit = true;
					var shaderCollection = AssetDatabase.LoadAssetAtPath<ShaderVariantCollection>(path);
					if (shaderCollection == null)
					{
						alreadyExsit = false;
						shaderCollection = new ShaderVariantCollection();
					}
	
					foreach (var (keywords, matList) in matDict)
					{
						var svd = GetShaderVariantEntriesFiltered(shader, matList[0].shaderKeywords);
						foreach (var passType in svd.passTypes)
						{
							var shaderVariant = new ShaderVariantCollection.ShaderVariant()
							{
								shader = shader,
								passType = (UnityEngine.Rendering.PassType)passType,
								keywords = matList[0].shaderKeywords,
							};
							if (!shaderCollection.Contains(shaderVariant))
							{
								shaderCollection.Add(shaderVariant);
							}
						}
					}
	
					if (alreadyExsit)
					{
						EditorUtility.SetDirty(shaderCollection);
					}
					else
					{
						AssetDatabase.CreateAsset(shaderCollection, path);
					}
				}
			}
			finally
			{
				AssetDatabase.StopAssetEditing();
			}

			// save
			EditorUtility.DisplayProgressBar("Collect Shader", "Save Assets", 1f);
			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();

			EditorUtility.ClearProgressBar();
			NLogger.Log("Collect all shader variant completed!");
		}

		private static void ExportCsv(Dictionary<string, Dictionary<string, List<Material>>> finalMats)
		{
			var sb = new StringBuilder();
			sb.AppendLine("ShaderName,Keywords,Materials");
			foreach (var (shaderName, dict) in finalMats)
			{
				foreach (var (keywords, list) in dict)
				{
					var mats = new List<string>();
					foreach (var mat in list)
					{
						mats.Add(mat.name);
					}
					sb.AppendLine($"{shaderName},{keywords},{string.Join(";", mats)}");
				}
			}
			var dstPath = Path.Combine(Application.dataPath, "../Logs/ShaderVaraintsCollect.csv");
			File.WriteAllText(dstPath, sb.ToString());

			NLogger.Log($"生成shader变体分析报告，详情前往<a href=\"file:///{dstPath}\">{dstPath}</a>查看");
		}
	}
}
