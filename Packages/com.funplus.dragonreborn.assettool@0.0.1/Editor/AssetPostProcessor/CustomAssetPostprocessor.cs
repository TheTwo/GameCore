
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
    public partial class CustomAssetPostprocessor : AssetPostprocessor
    {
	    private static readonly Type MaterialType = typeof(Material);
	    private static readonly Type GameObjectType = typeof(GameObject);
	    private static readonly List<UnityEngine.Object> TempList = new();
	    
	    private static bool CheckIsSomePath(string path, string[] paths) 
	    {
		    if (path.Contains(" "))
		    {
			    NLogger.Error("文件名字含有空格:" + Path.GetFileNameWithoutExtension(path));
			    return false;
		    }
		    
		    foreach (string str in paths) 
			    if (path.StartsWith(str, StringComparison.Ordinal)) 
				    return true;
		    return false;
	    }
	    
		private static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths)
		{
			TempList.Clear();
			for (int i = 0; i < importedAssets.Length; i++)
			{
				var assetPath = importedAssets[i];
				var assetType = AssetDatabase.GetMainAssetTypeAtPath(assetPath);
				if (MaterialType.IsAssignableFrom(assetType))
				{
					if (!assetPath.StartsWith("Assets/__Script/Editor/"))
					{
						// 检查材质使用的shader
						var material = AssetDatabase.LoadAssetAtPath<Material>(assetPath);
						CheckMaterial(material);
					}
				}
				else if (GameObjectType.IsAssignableFrom(assetType))
				{
					TempList.Add(AssetDatabase.LoadAssetAtPath<GameObject>(assetPath));
				}
			}
			if (TempList.Count <= 0) return;
			PrefabRendersDefaultMaterialSetter.SetMaterials(TempList);
			TempList.Clear();
		}
	}
}
