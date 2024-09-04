using UnityEditor;
using System.IO;
using CSVConfigReader.Formattor;
using System.Text;
using UnityEngine;
using System;

namespace DragonReborn.AssetTool.Editor
{
	public class AssetCheckTool
	{
		//[MenuItem("DragonReborn/资源工具箱/资源规范/日常检查/1, 配置表资源检查", false, 1)]
		public static void RunCsvResourceChecker()
		{
			var folder = Path.GetFullPath(SsrCsvConfigReader.PATH_CSV_FOLDER);
			var artResourcePath = Path.Combine(folder, SsrCsvConfigReader.ART_RESOURCE);
			if (!File.Exists(artResourcePath))
			{
				NLogger.Error("找不到ArtResource.csv");
				return;
			}

			var artResourceTable = SsrCsvConfigReader.ReadConfigCellsFromPath<ArtResource>(artResourcePath);
			if (artResourceTable == null)
			{
				NLogger.Error("ArtResource解析失败");
				return;
			}

			var artUIResourcePath = Path.Combine(folder, SsrCsvConfigReader.ART_RESOURCE_UI);
			if (!File.Exists(artUIResourcePath))
			{
				NLogger.Error("找不到ArtResourceUI.csv");
				return;
			}

			var artResourceUITable = SsrCsvConfigReader.ReadConfigCellsFromPath<ArtResourceUI>(artUIResourcePath);
			if (artResourceUITable == null)
			{
				NLogger.Error("ArtResourceUI解析失败");
				return;
			}

			AssetDatabaseLoader.sFindPathCallback = AssetPathService.GetSavePath;
			var sb = new StringBuilder();
			var errCount = 0;
			sb.AppendLine("ArtResource.csv配置不存在资源列表：");
			foreach (var cell in artResourceTable)
			{
				var asset = cell.Path.Trim();
				if (!AssetManager.Instance.ExistsInAssetSystem(asset))
				{
					sb.AppendLine($"{cell.Id},{cell.Path}");
					errCount++;
				}
			}

			sb.AppendLine();
			sb.AppendLine("ArtResourceUI.csv配置不存在资源列表：");
			foreach (var cell in artResourceUITable)
			{
				var asset = cell.Path.Trim();
				if (!AssetManager.Instance.ExistsInAssetSystem(asset))
				{
					sb.AppendLine($"{cell.Id},{cell.Path}");
					errCount++;
				}
			}

			if (errCount > 0)
			{
				try
				{
					var filePath = Path.Combine(Application.dataPath, "../Logs/资源配置表检查结果.log");
					filePath = Path.GetFullPath(filePath);
					File.WriteAllText(filePath, sb.ToString());
					NLogger.Error($"发现{errCount}组不存在资源，请前往<a href=\"file:///{filePath}\">{filePath}</a>查看");
				}
				catch (Exception e)
				{
					NLogger.Error(e.ToString());
				}
			}
			else
			{
				NLogger.Log("配置表资源检查完毕");
			}
		}
	}
}
