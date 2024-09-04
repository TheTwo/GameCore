using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public static class PrefabRendersDefaultMaterialSetter
	{
		private const string TempMatPath = "Assets/__Art/StaticResources/City/Material/City/mat_city_prefab_default_toonsimplelit.mat";


		[MenuItem("DragonReborn/资源工具箱/通用/选定节点批量使用默认材质替换丢失材质", false, 0)]
		private static void SetMaterial()
		{
			SetMaterials(Selection.gameObjects);
		}

		private static LazyLoadReference<Material> TempMatRef;
		
		public static void SetMaterials(IEnumerable<Object> objs)
		{
			if (!TempMatRef.isSet || TempMatRef.isBroken)
			{
				TempMatRef = AssetDatabase.LoadAssetAtPath<Material>(TempMatPath);
			}
			var mat = TempMatRef.asset;
			var needSave = false;
			AssetDatabase.StartAssetEditing();
			try
			{
				foreach (var obj in objs)
				{
					if (obj is not GameObject go) continue;
					if (!go) return;
					if (!CheckPrefab(obj, out var assetPath)) continue;
					if (string.IsNullOrWhiteSpace(assetPath)) return;
					if (!BatchMissingMaterialSetter(go, mat)) continue;
					EditorUtility.SetDirty(go);
					needSave = true;
				}
			}
			finally
			{
				AssetDatabase.StopAssetEditing();
			}
			if (needSave) AssetDatabase.SaveAssets();
		}

		[MenuItem("DragonReborn/资源工具箱/通用/选定节点批量使用默认材质替换丢失材质", true, 0)]
		private static bool CheckSetMaterial()
		{
			return Selection.gameObjects.Any(go => CheckPrefab(go, out _));
		}

		private static bool CheckPrefab(Object obj, out string assetPath)
		{
			assetPath = default;
			if (!obj) return false;
			if (!EditorUtility.IsPersistent(obj)) return false;
			if (!PrefabUtility.IsPartOfPrefabAsset(obj)) return false;
			assetPath = AssetDatabase.GetAssetPath(obj);
			return !string.IsNullOrWhiteSpace(assetPath);
		}

		public static bool BatchMissingMaterialSetter(GameObject root, Material material)
		{
			var isDirty = false;
			var renders = root.GetComponentsInChildren<Renderer>(true);
			foreach (var renderer in renders)
			{
				var needSet = false;
				var sharedMaterials = renderer.sharedMaterials;
				for (var i = 0; i < sharedMaterials.Length; i++)
				{
					if (sharedMaterials[i]) continue;
					sharedMaterials[i] = material;
					needSet = true;
					isDirty = true;
				}
				if (!needSet) continue;
				renderer.sharedMaterials = sharedMaterials;
			}
			return isDirty;
		}
	}
}
