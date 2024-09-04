using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class PrefabCleaner
	{
		[MenuItem("DragonReborn/资源工具箱/通用/清理Prefab无效引用")]
		public static void CleanUnusedRef()
		{
			var folders = new[]
			{
				"Assets/__Art/_Resources",
			};

			EditorUtility.DisplayProgressBar("正在清理", $"正在扫描prefab，请耐心等待", 0.5f);
			AssetDatabase.StartAssetEditing();
			var guids = AssetDatabase.FindAssets("t:GameObject", folders);
			foreach (var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
				EditorUtility.SetDirty(prefab);
			}
			AssetDatabase.StopAssetEditing();
			EditorUtility.ClearProgressBar();

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
		}
	}
}
