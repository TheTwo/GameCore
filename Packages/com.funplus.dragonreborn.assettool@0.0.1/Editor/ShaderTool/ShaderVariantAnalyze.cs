using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class ShaderVariantAnalyze
	{
		public class ShaderAnalyzeResult
		{
			public string shaderName;
			public string shaderNameWithPass;
			public string shaderPath;
			public string useByMaterials;
			public int curRemain;
			public int curVaraint;
			public int totalRemain;
			public int totalVaraint;
			public double timeCost;

			private string GetShaderName()
			{
				var index = shaderNameWithPass.IndexOf("(");
				return shaderNameWithPass[..index].Trim();
			}

			public static ShaderAnalyzeResult ParseFrom(string line)
			{
				var pattern = @"STRIPPING:\s*(.+)\s+-\s+.+variants\s*=\s*(\d+)/(\d+).+-\s*Total\s*=\s*(\d+)/(\d+).+TimeMs=([\d\.]+)";
				if (Regex.IsMatch(line, pattern)) 
				{
					var groups = Regex.Match(line, pattern).Groups;
					var result = new ShaderAnalyzeResult();
					result.shaderNameWithPass = groups[1].ToString();
					result.shaderName = result.GetShaderName();
					result.curRemain = Convert.ToInt32(groups[2].ToString());
					result.curVaraint = Convert.ToInt32(groups[3].ToString());
					result.totalRemain = Convert.ToInt32(groups[4].ToString());
					result.totalVaraint = Convert.ToInt32(groups[5].ToString());
					result.timeCost = Convert.ToDouble(groups[6].ToString());
					return result;
				}

				return null;
			}

			public override string ToString()
			{
				var tmp = string.IsNullOrEmpty(shaderPath) ? "Unknown" : shaderPath.Trim();
				return $"{shaderNameWithPass},{tmp},{curRemain},{curVaraint},{totalRemain},{totalVaraint},{timeCost}";
			}
		}

		private static void AnalyzeBuildLog(string logPath)
		{
			NLogger.Log("---------------------- begin AnalyzeBuildLog --------------------------------");
			
			if (string.IsNullOrEmpty(logPath) || !File.Exists("logPath"))
			{
				logPath = Application.consoleLogPath;
			}

			var sourcePath = logPath;
			if (string.IsNullOrEmpty(sourcePath))
			{
				NLogger.Error($"{Application.platform}: current platform does not support log files");
				return;
			}

			if (!File.Exists(sourcePath))
			{
				NLogger.Error($"{Application.platform}: current platform log file not exists. {sourcePath}");
				return;
			}

			var targetTmpPath = Path.Combine(Application.dataPath, "../Logs/ShaderAnalyze.tmp");
			if (File.Exists(targetTmpPath))
			{
				File.Delete(targetTmpPath);
			}
			File.Copy(sourcePath, targetTmpPath, true);

			var resultList = GetAnalyzeResult(targetTmpPath);

			SaveToCsv(resultList);
			
			NLogger.Log("---------------------- end AnalyzeBuildLog --------------------------------");
		}

		public static Dictionary<string, ShaderAnalyzeResult> GetAnalyzeResult(string logPath)
		{
			var resultDict = new Dictionary<string, ShaderAnalyzeResult>();
			var stream = new StreamReader(logPath);
			{
				string line;
				while ((line = stream.ReadLine()) != null)
				{
					var shaderResult = ShaderAnalyzeResult.ParseFrom(line);
					if (shaderResult == null)
					{
						continue;
					}

					if (!resultDict.ContainsKey(shaderResult.shaderNameWithPass))
					{
						resultDict.Add(shaderResult.shaderNameWithPass, shaderResult);
					}
				}
			}

			// add ShaderPath
			var allShaderGuids = AssetDatabase.FindAssets("t:Shader");
			var shaderName2Paths = new Dictionary<string, HashSet<string>>();
			foreach (var guid in allShaderGuids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				var shader = AssetDatabase.LoadAssetAtPath<Shader>(path);
				if (!shaderName2Paths.ContainsKey(shader.name))
				{
					shaderName2Paths.Add(shader.name, new HashSet<string>());
				}

				shaderName2Paths[shader.name].Add(path);
			}

			// add useByMaterials
			var allMaterialGuids = AssetDatabase.FindAssets("t:Material", ShaderVariantCollector.ResPathArray);
			var shaderName2Materials = new Dictionary<string, HashSet<string>>();
			foreach (var guid in allMaterialGuids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
				if (!shaderName2Materials.ContainsKey(mat.shader.name))
				{
					shaderName2Materials.Add(mat.shader.name, new HashSet<string>());
				}

				shaderName2Materials[mat.shader.name].Add(path);
			}

			foreach (var (_, r) in resultDict)
			{
				var shaderName = r.shaderName;
				if (shaderName2Paths.ContainsKey(shaderName))
				{
					r.shaderPath = GetJoinString(shaderName2Paths[shaderName]);
				}

				if (shaderName2Materials.ContainsKey(shaderName))
				{
					r.useByMaterials = GetJoinString(shaderName2Materials[shaderName]);
				}
			}

			return resultDict;
		}

		private static string GetJoinString(HashSet<string> sets)
		{
			var sb = new StringBuilder();
			sb.AppendJoin(';', sets);
			return sb.ToString();
		}

		[MenuItem("DragonReborn/资源工具箱/Shader工具/分析实际产生的shader变体（依赖打包log）")]
		public static void AnalyzeBuildLog()
		{
			var sourcePath = Application.consoleLogPath;
			AnalyzeBuildLog(sourcePath);
		}

		public static void SaveToCsv(Dictionary<string, ShaderAnalyzeResult> result)
		{
			var savePath = Path.Combine(Application.dataPath, "../Logs/ShaderAnalzye.csv");
			if (File.Exists(savePath))
			{
				File.Delete(savePath);
			}

			var list = result.Values.ToList();
			list.Sort((x, y) => y.curRemain.CompareTo(x.curRemain));
			var writer = new StreamWriter(savePath);
			writer.WriteLine("ShaderName,ShaderPath,Remain,Total,FinalRemain,FinalTotal,TimeCost(ms)");
			foreach (var item in list)
			{
				writer.WriteLine(item.ToString());
			}
			writer.Flush();
			writer.Close();
		}
	}
}
