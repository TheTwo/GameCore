using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class TextureTools
	{
		[MenuItem("DragonReborn/资源工具箱/贴图工具/检查贴图规范")]
		public static void ScanAllTextures()
		{
			var folders = new[] {
				"Assets/__Art",
				"Assets/__UI"
			};

			var guids = AssetDatabase.FindAssets(null, folders);
			var sb = new StringBuilder();
			foreach (var guid in guids)
			{
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
				if (importer == null)
				{
					
					continue;
				}


				if (importer.isReadable)
				{
					sb.AppendLine(assetPath);
				}
			}

			if (sb.Length > 0)
			{
				sb.Insert(0, "发现开了读写的贴图，如下：\n");
			}

			var path = Path.Combine(Application.dataPath, "../Logs/贴图检查结果.log");
			File.WriteAllText(path, sb.ToString());
			NLogger.Error("完事");
		}

		public static void PruneTextures()
		{
			var readableTextureGuids = GetReadableTextureGuids();
			var total = readableTextureGuids.Count;
			if (total == 0)
			{
				return;
			}

			EditorUtility.DisplayProgressBar("Analyze...", "Analyze textures", 0.0f);
			var curIndex = 0;
			AssetDatabase.StartAssetEditing();
			try
			{
				foreach (var guid in readableTextureGuids)
				{
					var assetPath = AssetDatabase.GUIDToAssetPath(guid);
					if (AssetImporter.GetAtPath(assetPath) is not TextureImporter importer) continue;
					var progress = Mathf.Clamp01(curIndex / (float)total);
					EditorUtility.DisplayProgressBar("Analyze...", assetPath, progress);
					NLogger.Log($"PruneTextures: {assetPath} set isReadable false");
					importer.isReadable = false;
					importer.SaveAndReimport();
				}
			}
			finally
			{
				AssetDatabase.StopAssetEditing();
			}

			EditorUtility.ClearProgressBar();

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
		}

		private static List<string> GetReadableTextureGuids()
		{
			var list = new List<string>();

			var folders = new[] {
				"Assets/__Art",
				"Assets/__UI"
			};

			var guids = AssetDatabase.FindAssets(null, folders);
			foreach (var guid in guids)
			{
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				if (assetPath.Contains("/__DontFixMe/") || assetPath.Contains("\\__DontFixMe\\"))
					continue;
				var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
				if (importer == null)
				{
					continue;
				}

				if (importer.isReadable)
				{
					list.Add(guid);				
				}
			}

			return list;
		}
	}
}
