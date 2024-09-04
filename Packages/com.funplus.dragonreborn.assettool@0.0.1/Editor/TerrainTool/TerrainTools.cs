using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class TerrainTools
	{
		private static string[] terrainFolders = new[] {
			"Assets/__Art/_Resources/Gve/gve_boss_1_Terrain",
			"Assets/__Art/_Resources/Kingdom/Map_1day/Terrain"
		}; 

		[MenuItem("DragonReborn/资源工具箱/Terrain工具/Terrain资源依赖检查")]
		public static void ReviewTerrain()
		{
			var guids = AssetDatabase.FindAssets("t:prefab", terrainFolders);
			var assetsRelations = AssetsDependenciesGetter.GenerateForAssets(guids);
			var checkResult = new SortedDictionary<string, List<string>>();
			foreach (var (path, dependencePaths) in assetsRelations)
			{
				foreach (var dependencePath in dependencePaths)
				{
					if (!IsDependencyValid(dependencePath))
					{
						if (!checkResult.ContainsKey(path))
						{
							checkResult.Add(path, new List<string>());
						}

						checkResult[path].Add(dependencePath);
					}
				}
			}

			var sb = new StringBuilder();
			foreach (var (source, errorDeps) in checkResult)
			{
				sb.AppendLine(source);
				foreach (var errorDep in errorDeps)
				{
					sb.Append("\t").AppendLine(errorDep.ToString());
				}
			}

			if (sb.Length > 0)
			{
				var savePath = Path.GetFullPath(Path.Combine(Application.dataPath, "../Logs/Terrain资源依赖检查.log"));
				NLogger.Error($"Terrain资源依赖有{checkResult.Count}组问题，请前往<a href=\"file:///{savePath}\">{savePath}</a>查看");
				File.WriteAllText(savePath, sb.ToString());
			}
			else
			{
				NLogger.Log("Terrain资源依赖情况良好");
			}
		}

		private static bool IsDependencyValid(string path)
		{
			if (!path.StartsWith("Assets/__Art")
				&& !path.StartsWith("Assets/__UI")
				&& !path.StartsWith("Assets/__Scene")
				&& !path.StartsWith("Assets/__Shader")
				&& !path.StartsWith("Resources/unity_builtin_extra"))
			{
				return false;
			}

			return true;
		}
	}
}
