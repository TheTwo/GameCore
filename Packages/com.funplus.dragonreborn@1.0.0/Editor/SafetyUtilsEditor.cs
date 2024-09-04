using System.IO;
using DragonReborn;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
internal static class SafetyUtilsEditor
{
	[MenuItem("DragonReborn/资源工具箱/安全工具/异或加解密选中文件")]
	private static void EncryptXorSelectionFile()
	{
		if (!Selection.activeObject) return;
		var p = AssetDatabase.GetAssetPath(Selection.activeObject);
		if (!p.StartsWith("Assets/")) return;
		p = Path.Combine(Application.dataPath, p["Assets/".Length..]);
		SafetyUtils.EncryptXOR(p);
	}
	
	[MenuItem("DragonReborn/资源工具箱/安全工具/异或加解密选中文件", true)]
	private static bool CheckEncryptXorSelectionFile()
	{
		return Selection.activeObject
		       && EditorUtility.IsPersistent(Selection.activeObject)
		       && AssetDatabase.IsMainAsset(Selection.activeObject)
		       && AssetDatabase.GetAssetPath(Selection.activeObject).StartsWith("Assets/")
		       && !AssetDatabase.IsValidFolder(AssetDatabase.GetAssetPath(Selection.activeObject));
	}
}
