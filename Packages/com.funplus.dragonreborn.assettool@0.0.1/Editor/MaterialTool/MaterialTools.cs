using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class MaterialTools
	{
		public static readonly string[] ResPathArray = new[] {
			"Assets/__Art",
			"Assets/__UI"
		};

		public static IReadOnlyList<string> AllowedMaterialPaths => ResPathArray;

		public static readonly string[] ShaderPathArray = new[] { 
			"Assets/__Shader",
			"Assets/ThirdParty/PowerVFX",
			"Packages/com.funplus.vxtools",
			"Packages/com.funplus.gpuskinning",
			"Packages/com.esotericsoftware.spine.spine-unity"
		};

		public static IReadOnlyList<string> AllowedShaderPathArray => ShaderPathArray;

		public class MaterialScanResult
		{
			public string MaterialPath;
			public string ShaderName;

			public override string ToString()
			{
				return $"{MaterialPath},{ShaderName}";
			}
		}

		private static Shader _errorShader;
		public static Shader ErrorShader
		{
			get
			{
				if (_errorShader == null)
				{
					_errorShader = Shader.Find("Hidden/InternalErrorShader");
				}

				return _errorShader;
			}
		}

		public static Dictionary<string, string> ShaderWhiteList()
		{
			var dict = new Dictionary<string, string>();
			var guids = AssetDatabase.FindAssets("t:shader", ShaderPathArray);
			foreach (var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				var shader = AssetDatabase.LoadAssetAtPath<Shader>(path);
				if (!dict.ContainsKey(shader.name))
				{
					//NLogger.Log($"{shader.name} add into whitelist");
					dict.Add(shader.name, path);
				}
				else
				{
					NLogger.Error($"duplicate {shader.name} in {path}");
				}
			}

			return dict;
		}

		[MenuItem("DragonReborn/资源工具箱/材质工具/扫描所有材质并替换错误使用shader")]
		public static void MaterialScanAndFix()
		{
			DoScanAllMaterials(true);
		}

		//[MenuItem("DragonReborn/资源工具箱/材质工具/扫描所有材质")]
		//public static void MaterialScan()
		//{
		//	DoScanAllMaterials(false);
		//}

		private static void DoScanAllMaterials(bool withFix)
		{
			var shaderWhiteList = ShaderWhiteList();

			var guids = AssetDatabase.FindAssets("t:material", ResPathArray);
			var list = new List<MaterialScanResult>();
			foreach (var guid in guids)
			{
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				var mat = AssetDatabase.LoadMainAssetAtPath(assetPath) as Material;
				if (!mat)
				{
					continue;
				}

				var shader = mat.shader;
				if (!shaderWhiteList.ContainsKey(shader.name))
				{
					if (withFix)
					{
						mat.shader = ErrorShader;
						list.Add(new MaterialScanResult
						{
							MaterialPath = assetPath,
							ShaderName = ErrorShader.name
						});
					}
					else 
					{
						list.Add(new MaterialScanResult
						{
							MaterialPath = assetPath,
							ShaderName = shader.name
						});
					}
				}
			}

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();

			var savePath = Path.Combine(Application.dataPath, "../Logs/MaterialScan.csv");
			var writer = new StreamWriter(savePath);
			writer.WriteLine("MaterialPath,ShaderName");
			foreach (var result in list)
			{
				writer.WriteLine(result.ToString());
			}
			writer.Flush();
			writer.Close();

			if (list.Count > 0)
			{
				NLogger.Error($"材质扫描发现有{list.Count}处异常，详情前往<a href=\"file:///{savePath}\">{savePath}</a>查看");
			}
			else
			{
				NLogger.Error("材质扫描结束，没有发现问题");
			}
		}
	}
}
