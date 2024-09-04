using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using YamlDotNet.Serialization;

namespace DragonReborn.AssetTool.Editor
{
	public class VfxTools
	{
		// 特效贴图的尺寸限制
		// https://funplus.yuque.com/slgtech/gazp4w/tz9qwsg8twdfroms
		public const string VFX_LABEL_HIGH = "A_high";
		public const string VFX_LABEL_SHEET = "A_sheet";
		public const string VFX_LABEL_UI = "A_UI";

		public const int TEXTURE_SIZE_NORMAL = 128;
		public const int TEXTURE_SIZE_HIGH = 256;
		public const int TEXTURE_SIZE_SHEET = 512;
		public const int TEXTURE_SIZE_UI = 1024;

		public const string VFX_TEXTURE_FOLDER = "Assets/__Art/StaticResources/Vfx/Textures";
		public const string VFX_PREFAB_FOLDER = "Assets/__Art/_Resources/Vfx";

		public readonly static string[] VfxTextureFolders = new[] {
			VFX_TEXTURE_FOLDER
		};
		
		// 废弃用下面的
		// asset在import阶段，是无法从AssetDatabase.GetLabels()拿到数据的
		// 所以从meta文件直接读取
		public static string[] GetLabelsFromAssetMetaFile(string assetPath)
		{
			var metaFilePath = $"{assetPath}.meta";
			var content = File.ReadAllText(metaFilePath);
			var input = new StringReader(content);
			var deserializer = new DeserializerBuilder().Build();
			var yamlObject = deserializer.Deserialize(input);
			var serializer = new SerializerBuilder()
				.JsonCompatible()
				.Build();
			var json = serializer.Serialize(yamlObject);
			var dataDict = DataUtils.FromJson<Dictionary<string, object>>(json);
			if (dataDict.ContainsKey("labels"))
			{
				var tmp = dataDict["labels"];
				if (tmp == null) return null;
				var labelsArrayStr = tmp.ToString();
				if (string.IsNullOrWhiteSpace(labelsArrayStr)) return null;
				var labels = DataUtils.FromJson<string[]>(labelsArrayStr);
				return labels;
			}

			return null;
		}
		
		// 新添加获取Labels
		public static string[] GetdAssetLabels(string assetPath)
		{
			string metaFilePath = $"{assetPath}.meta";
			if (!File.Exists(metaFilePath))
			{
				Debug.Log("Meta file not found.");
				return null;
			}

			var content = File.ReadAllText(metaFilePath);
			var deserializer = new DeserializerBuilder().Build();
			var yamlDictionary = deserializer.Deserialize<Dictionary<string, object>>(content);

			if (yamlDictionary.TryGetValue("labels", out object labelsValue) && labelsValue is List<object> labelsList)
			{
				// 将List<object>转换为string[]
				string[] labels = labelsList.ConvertAll(item => item.ToString()).ToArray();
				return labels;
			}

			return null;
		}

		public static int GetMaxTextureSize(string assetPath)
		{
			var labels = GetdAssetLabels(assetPath);
			if (labels != null && labels.Length > 0)
			{
				foreach (var label in labels)
				{
					if (string.Compare(VFX_LABEL_HIGH, label, true) == 0)
					{
						return TEXTURE_SIZE_HIGH;
					}

					if (string.Compare(VFX_LABEL_SHEET, label, true) == 0)
					{
						return TEXTURE_SIZE_SHEET;
					}

					if (string.Compare(VFX_LABEL_UI, label, true) == 0)
					{
						return TEXTURE_SIZE_UI;
					}
				}
			}

			return TEXTURE_SIZE_NORMAL;
		}

		public static string[] GetAllVfxTextureAssets()
		{
			return AssetDatabase.FindAssets("t:texture", VfxTextureFolders);
		}

		public static bool HasInvalidAssetLabels(string guid, out HashSet<string> set)
		{
			set = new HashSet<string>();

			var assetPath = AssetDatabase.GUIDToAssetPath(guid);
			var asset = AssetDatabase.LoadAssetAtPath<Object>(assetPath);
			var labels = AssetDatabase.GetLabels(asset);
			if (labels != null && labels.Length > 0)
			{
				foreach (var label in labels)
				{
					if (string.Compare(VFX_LABEL_HIGH, label, true) != 0
						&& string.Compare(VFX_LABEL_SHEET, label, true) != 0
						&& string.Compare(VFX_LABEL_UI, label, true) != 0)
					{
						set.Add(VFX_LABEL_HIGH);
					}
				}
			}

			return set.Count > 0;
		}

		public static void RemoveInvalidAssetLabels(string guid, HashSet<string> invalidSet)
		{
			var assetPath = AssetDatabase.GUIDToAssetPath(guid);
			var asset = AssetDatabase.LoadAssetAtPath<Object>(assetPath);
			var labels = AssetDatabase.GetLabels(asset);
			var currentLabels = new HashSet<string>(labels);
			currentLabels.Except(invalidSet);
			AssetDatabase.SetLabels(asset, currentLabels.ToArray());
		}
	}
}
