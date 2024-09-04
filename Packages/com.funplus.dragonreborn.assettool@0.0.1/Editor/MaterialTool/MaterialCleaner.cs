using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Reflection;

namespace DragonReborn.AssetTool.Editor
{
	public static class MaterialCleaner
	{
		private static Dictionary<Shader, HashSet<string>> _shaderKeywordsCache;
		private static string[] _folders = new[] { "Assets/__Art" }; 

		[MenuItem("DragonReborn/资源工具箱/材质工具/材质清洗")]
		public static void ClearMaterials()
		{
			if (_shaderKeywordsCache == null)
			{
				_shaderKeywordsCache = new Dictionary<Shader, HashSet<string>>();
			}
			else
			{
				_shaderKeywordsCache.Clear();
			}

			float totalSizeBefore = 0f;
			float totalSizeAfter = 0f;
			string[] allGuids = AssetDatabase.FindAssets("t:Material", _folders);
			float percent = 1.0f / allGuids.Length;
			string matPath;
			Material curMat = null;
			FileInfo matFileInfo = null;
			for (int i = 0; i < allGuids.Length; ++i)
			{
				matPath = AssetDatabase.GUIDToAssetPath(allGuids[i]);
				curMat = AssetDatabase.LoadAssetAtPath(matPath, typeof(Material)) as Material;
				NLogger.Log($"matPath: {matPath}");
				RemoveUnusedShaderKeywords(curMat);

				EditorUtility.DisplayProgressBar("正在清理", $"正在清理第{(i + 1)}个材质{curMat.name}", percent * i);

				matFileInfo = new FileInfo(AssetDatabase.GetAssetPath(curMat));
				totalSizeBefore += matFileInfo.Length;
				SerializedObject serialize = new SerializedObject(curMat);
				SerializedProperty savedProperties = serialize.FindProperty("m_SavedProperties");//代表存储的属性
				SerializedProperty texEnvProperties = savedProperties.FindPropertyRelative("m_TexEnvs");//存储所有纹理的结点，还有m_Floats、m_Colors等等。
				SerializedProperty floatProperties = savedProperties.FindPropertyRelative("m_Floats");
				SerializedProperty colorProperties = savedProperties.FindPropertyRelative("m_Colors");
				CleanMaterialSerializedProperty(texEnvProperties, curMat);
				CleanMaterialSerializedProperty(floatProperties, curMat);
				CleanMaterialSerializedProperty(colorProperties, curMat);
				serialize.ApplyModifiedProperties();

				EditorUtility.SetDirty(curMat);
			}

			EditorUtility.ClearProgressBar();
			AssetDatabase.Refresh();
			AssetDatabase.SaveAssets();

			// 统计清理之后的材质总大小
			for (int j = 0; j < allGuids.Length; ++j)
			{
				EditorUtility.DisplayProgressBar("正在统计", "正在统计第" + (j + 1) + "个材质", percent * j);
				matPath = AssetDatabase.GUIDToAssetPath(allGuids[j]);
				matFileInfo = new FileInfo(matPath);
				totalSizeAfter += matFileInfo.Length;
			}

			EditorUtility.ClearProgressBar();

			var beforeSize = (float)totalSizeBefore / (1024f * 1024f);
			var afterSize = (float)totalSizeAfter / (1024f * 1024f);
			NLogger.Log($"Size Before: {beforeSize} Mb Size After: {afterSize} Mb");
		}

		private static void RemoveUnusedShaderKeywords(Material mat)
		{
			// 清理无效的ShaderKeywords
			if (mat.shader != null)
			{
				if (!_shaderKeywordsCache.TryGetValue(mat.shader, out var shaderKeywords))
				{
					shaderKeywords = GetShaderKeyWords(mat.shader);
					_shaderKeywordsCache.Add(mat.shader, shaderKeywords);
				}

				if (shaderKeywords != null)
				{
					NLogger.Log(mat.shader.name + "    " + shaderKeywords.Count);

					List<string> containKeyWorlds = new List<string>();

					if (mat.shaderKeywords != null && mat.shaderKeywords.Length > 0)
					{
						for (int i = 0; i < mat.shaderKeywords.Length; i++)
						{
							if (shaderKeywords.Contains(mat.shaderKeywords[i]))
							{

								NLogger.Log($"{mat.name} Add Keyword {mat.shaderKeywords[i]}");
								containKeyWorlds.Add(mat.shaderKeywords[i]);

							}
						}
					}

					var validKeywords = containKeyWorlds.ToArray();

					var tmp = mat.shaderKeywords;
					foreach (string key in tmp)
					{
						mat.DisableKeyword(key);
					}

					foreach (string key in validKeywords)
					{
						mat.EnableKeyword(key);
					}

					foreach (string key in mat.shaderKeywords)
					{
						NLogger.Log($"{mat.name} Modify Keyword {key}");
					}
				}
				else
				{
					mat.shaderKeywords = null;
				}
			}
		}

		private static void CleanMaterialSerializedProperty(SerializedProperty property, Material mat)
		{
			for (int j = property.arraySize - 1; j >= 0; j--)
			{
				string propertyName = property.GetArrayElementAtIndex(j).FindPropertyRelative("first").stringValue;

				if (!mat.HasProperty(propertyName))//如果没有了，就删除
				{
					if (propertyName.Equals("_MainTex"))
					{
						//_MainTex是内建属性，是置空不删除，否则UITexture等控件在获取mat.maintexture的时候会报错
						if (property.GetArrayElementAtIndex(j).FindPropertyRelative("second").FindPropertyRelative("m_Texture").objectReferenceValue != null)
						{
							property.GetArrayElementAtIndex(j).FindPropertyRelative("second").FindPropertyRelative("m_Texture").objectReferenceValue = null;
						}
					}
					else
					{
						property.DeleteArrayElementAtIndex(j);
					}
				}
			}
		}

		//[MenuItem("DragonReborn/常用工具/材质工具/打印Shader的KeyWords")]
		//public static void LogShaderKeyWords()
		//{
		//	if (Selection.activeObject == null)
		//	{
		//		Debug.LogError("您没选中任何Shader文件");
		//		return;
		//	}

		//	if (Selection.activeObject.GetType() != typeof(Shader))
		//	{
		//		Debug.LogError("您选中的不是Shader文件");
		//		return;
		//	}

		//	Shader shader = Selection.activeObject as Shader;
		//	GetShaderKeyWords(shader);
		//}

		public static HashSet<string> GetShaderKeyWords(Shader shader)
		{
			System.Type t = typeof(ShaderUtil);
			HashSet<string> totalKeywords = new HashSet<string>();

			//获取Shader中的LoacalKeywords
			MethodInfo GetlocalKeyWordsMethod = t.GetMethod("GetShaderLocalKeywords", BindingFlags.NonPublic | BindingFlags.Static);
			string[] localKeyWords = (string[])GetlocalKeyWordsMethod.Invoke(null, new object[] { shader });

			for (int i = 0; i < localKeyWords.Length; i++)
			{
				NLogger.Log("Local:" + localKeyWords[i]);
				totalKeywords.Add(localKeyWords[i]);
			}

			//获取Shader中的GlobalKeywords
			MethodInfo GetGlobalKeyWordsMethod = t.GetMethod("GetShaderGlobalKeywords", BindingFlags.NonPublic | BindingFlags.Static);
			string[] globalKeyWords = (string[])GetGlobalKeyWordsMethod.Invoke(null, new object[] { shader });

			for (int j = 0; j < globalKeyWords.Length; j++)
			{
				NLogger.Log("Global:" + globalKeyWords[j]);
				totalKeywords.Add(globalKeyWords[j]);
			}

			return totalKeywords;
		}
	}
}
