using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class ShaderBinary2TextVaraintInfo
	{
		public string passName;
		public List<int> keywordsIndices;
	}

	public class ShaderBinary2TextInfo
	{
		public string shaderName;
		public List<string> shaderKeywords;
		public List<ShaderBinary2TextVaraintInfo> shaderVaraints;
	}

	public class ShaderTools
	{
		private const int TIME_OUT = 1000 * 60;

		[MenuItem("DragonReborn/资源工具箱/Shader工具/解析ab分析shader变体")]
		public static void ParseShaderBinary2TextFileOpenWindow()
		{
			const string saveKey = nameof(ParseShaderBinary2TextFileOpenWindow) + "_LAST_FOLDER";
			var lastFolder = EditorPrefs.GetString(saveKey, string.Empty);
			if (string.IsNullOrWhiteSpace(lastFolder) || !Directory.Exists(lastFolder))
			{
				lastFolder = Path.GetFullPath(".");
			}
			var abPath = EditorUtility.OpenFilePanel("选择shader@all.ab", lastFolder, "ab");
			if (File.Exists(abPath))
			{
				EditorPrefs.SetString(saveKey, Path.GetDirectoryName(abPath));
			}
			EditorUtility.ClearProgressBar();
			EditorUtility.DisplayProgressBar("处理文件中", abPath, 0f);
			UnityBuiltinDumpWindow.DoExForExternal(abPath, (handle, list) =>
			{
				try
				{
					foreach (var (success, path) in list)
					{
						if (!success || !Directory.Exists(path)) continue;
						var files = Directory.GetFiles(path, "CAB-*.txt");
						foreach (var file in files)
						{
							var p = ParseShaderBinary2TextFile(file);
							if (p < 0) return;
						}
					}
				}
				finally
				{
					EditorUtility.ClearProgressBar();
					handle?.Dispose();
				}
			});
		}

		public static int ParseShaderBinary2TextFile(string path)
		{
			//var path = "d:/Work/shader@all.ab_data/CAB-409b20f9ce0f1fab7ab8686587dbe66b.txt";
			//var path = "d:/Work/shader@all.ab_data/ToonSimpleLit.data";
			// var path = "d:/Work/shader2@all.ab_data/CAB-409b20f9ce0f1fab7ab8686587dbe66b.txt";
			if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                EditorUtility.DisplayDialog("错误", "文件不存在", "确定");
                return -1;
            }

			var allShaderInfo = new Dictionary<string, ShaderBinary2TextInfo>();
			ShaderBinary2TextInfo shaderInfo = null;
			string passName = null;
			var isGetkeywords = false;
			var lineCounter = 0;
			using (var reader = new StreamReader(path))
			{
				while (!reader.EndOfStream)
				{
					var line = reader.ReadLine();
					lineCounter++;
					// 一个新的shader数据开始
					if (line.Contains("ClassID: 48"))
					{
						shaderInfo = new ShaderBinary2TextInfo();
						shaderInfo.shaderVaraints = new List<ShaderBinary2TextVaraintInfo>();
						shaderInfo.shaderKeywords = new List<string>();
						isGetkeywords = false;
					}

					// 一个pass信息开始
					if (line.Contains("SerializedShaderState"))
					{
						line = reader.ReadLine();
						lineCounter++;

						var startIdx = line.IndexOf("\"") + 1;
						var endIdx = line.LastIndexOf("\"");
						passName = line.Substring(startIdx, endIdx - startIdx);
					}

					// 一个shader变体信息开始
					if (line.Contains("m_KeywordIndices"))
					{
						line = reader.ReadLine();
						lineCounter++;
						line = reader.ReadLine();
						lineCounter++;

						if (shaderInfo == null)
						{
							throw new System.Exception("shaderInfo is null");
						}

						var shaderVaraintInfo = new ShaderBinary2TextVaraintInfo();
						shaderVaraintInfo.passName = passName;
						shaderVaraintInfo.keywordsIndices = new List<int>();
						shaderInfo.shaderVaraints.Add(shaderVaraintInfo);

						var indicesStr = line.Split("#0: ");
						if (indicesStr.Length == 2)
						{
							var array = indicesStr[1].Split(' ');
							foreach (var str in array)
							{
								shaderVaraintInfo.keywordsIndices.Add(int.Parse(str));
							}
						}
					}

					// shader关键字开始
					if (line.Contains("m_KeywordNames"))
					{
						line = reader.ReadLine();
						lineCounter++;
						while (!line.Contains("m_CustomEditorName"))
						{
							line = reader.ReadLine();
							lineCounter++;
							if (line.Contains("data \"") && line.Contains("\" (string)"))
							{
								var startIdx = line.IndexOf("\"") + 1;
								var endIdx = line.LastIndexOf("\"");
								var keyword = line.Substring(startIdx, endIdx - startIdx);
								shaderInfo.shaderKeywords.Add(keyword);
								isGetkeywords = true;
							}

							if (line.Contains("m_Name \"") && line.Contains("\" (string)") && isGetkeywords)
							{
								var startIdx = line.IndexOf("\"") + 1;
								var endIdx = line.LastIndexOf("\"");
								var shaderName = line.Substring(startIdx, endIdx - startIdx);
								shaderInfo.shaderName = shaderName;
								allShaderInfo.Add(shaderName, shaderInfo);
							}
						}
					}
				}
			}

			var ret = Print(allShaderInfo);

			UnityEngine.Debug.Log($"结束: {DataUtils.ToJson(allShaderInfo)}");
			return ret;
		}

		private static int Print(Dictionary<string, ShaderBinary2TextInfo> allShaderInfo)
		{
			const string saveFolderKey = nameof(ParseShaderBinary2TextFile) + "_" + nameof(Print) + "_SAVE_KEY";
			if (allShaderInfo == null)
			{
				NLogger.Error("allShaderInfo is null");
				return 0;
			}

			var sb = new StringBuilder();
			foreach (var (shaderName, shaderInfo) in allShaderInfo)
			{
				var idx = 0;
				foreach (var shaderVaraintInfo in shaderInfo.shaderVaraints)
				{
					sb.AppendLine($"{shaderName} ({shaderVaraintInfo.passName}) {idx++} {GetShaderKeywords(shaderInfo.shaderKeywords, shaderVaraintInfo)}");
				}
			}

			var lastFolder = EditorPrefs.GetString(saveFolderKey, string.Empty);
			if (string.IsNullOrWhiteSpace(lastFolder) || !Directory.Exists(lastFolder))
			{
				lastFolder = Path.GetFullPath(".");
			}

			var savePath = EditorUtility.SaveFilePanel("保存导出分析", lastFolder,
				$"shader_result_{DateTime.Now.ToString("yy-MM-dd HH-mm-ss")}", "txt");
			if (string.IsNullOrWhiteSpace(savePath))
			{
				return -1;
			}
			
			EditorPrefs.SetString(saveFolderKey, Path.GetDirectoryName(savePath));

			// File.WriteAllText("d://Work/shader2@all.ab_data/result.txt", sb.ToString());
			File.WriteAllText(savePath, sb.ToString());
			return 1;
		}

		private static string GetShaderKeywords(List<string> allKeywords, ShaderBinary2TextVaraintInfo shaderVaraintInfo)
		{
			if (allKeywords == null || allKeywords.Count == 0 || shaderVaraintInfo.keywordsIndices == null || shaderVaraintInfo.keywordsIndices.Count == 0)
			{
				return string.Empty;
			}

			var set = new HashSet<string>();
			foreach (var idx in shaderVaraintInfo.keywordsIndices)
			{
				set.Add(allKeywords[idx]);
			}

			return string.Join(",", set.ToArray());
		}
	}
}
