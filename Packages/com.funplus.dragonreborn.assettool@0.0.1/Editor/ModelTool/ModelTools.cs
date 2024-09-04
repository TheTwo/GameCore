using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class ModelTools
	{
		private const string TAB = "\t";

		private static string[] FilterGuids(string[] guids)
		{
			var list = new List<string>();
			foreach (var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				if (path.Contains("GPUSkinning", StringComparison.OrdinalIgnoreCase))
				{
					continue;
				}
				list.Add(guid);
			}

			return list.ToArray();
		}

		// https://docs.google.com/document/d/161c_jpeFKEgAMY7H2C3F-HjWL0RJr95wqeg326F6-v0/edit
		// 不同Lod级别贴图的大小限制
		public static int GetModelTextureMaxSize(string assetPath)
		{
			var expectedSize = -1;
			var fileName = Path.GetFileNameWithoutExtension(assetPath);
			if (fileName.Contains("_MedRes"))
			{
				expectedSize = 1024;
			}
			else if (fileName.Contains("_HighRes"))
			{
				expectedSize = 2048;
			}
			else if (assetPath.Contains("Assets/__Art/StaticResources/KingdomMap/Landform", StringComparison.OrdinalIgnoreCase))
			{
				expectedSize = 1024;
			}
			else if (assetPath.Contains("Assets/__Scene/StaticResources/GveBoss", StringComparison.OrdinalIgnoreCase)
				|| assetPath.Contains("Assets/__Art/StaticResources/Kingdom", StringComparison.OrdinalIgnoreCase))
			{
				expectedSize = 1024;
			}
			else if (assetPath.Contains("Assets/__Art/StaticResources/City", StringComparison.OrdinalIgnoreCase)
				|| assetPath.Contains("Assets/__Art/StaticResources/Environment", StringComparison.OrdinalIgnoreCase)
				|| assetPath.Contains("Assets/__Art/StaticResources/Common", StringComparison.OrdinalIgnoreCase))
			{
				expectedSize = 512;
			}
			else if (assetPath.Contains("/lod0/", StringComparison.OrdinalIgnoreCase))
			{
				expectedSize = 1024;
			}
			else if (assetPath.Contains("/lod1/", StringComparison.OrdinalIgnoreCase))
			{
				if (assetPath.Contains("Assets/__Art/StaticResources/Characters/Boss"))
				{
					expectedSize = 512;
				}
				else
				{
					expectedSize = 256;
				}
			}
			else if (assetPath.Contains("/lod2/", StringComparison.OrdinalIgnoreCase))
			{
				if (assetPath.Contains("Assets/__Art/StaticResources/Characters/Boss"))
				{
					expectedSize = 512;
				}
				else
				{
					expectedSize = 128;
				}
			}

			return expectedSize;
		}

		//[MenuItem("DragonReborn/资源工具箱/资源规范/日常检查/3, 场景模型资源检查", false, 3)]
		public static void RunCityModelResourceCheck()
		{
			var folders = new[]
			{
				"Assets/__Art/_Resources/City/Building",
				"Assets/__Art/_Resources/City/Furnitures",
				"Assets/__Art/_Resources/City/Gameplay",
				"Assets/__Art/_Resources/Environment"
			};

			var guids = AssetDatabase.FindAssets("t:GameObject", folders);
			guids = FilterGuids(guids);

			// 获取实际依赖
			// AssetDatabase.GetDependencies()获得的依赖，包含了Modification记录，结果不符合预期
			var result = AssetsDependenciesGetter.GenerateForAssets(guids);
			var sb = new StringBuilder();
			var errGroup = 0;
			foreach (var (path, dependencePaths) in result)
			{
				var name = Path.GetFileName(path);
				var index = path.LastIndexOf(name);
				var prefix = path.Substring(0, index - 1).Replace("_Resources", "StaticResources");
				index = prefix.LastIndexOf("/");
				var prefixAnim = prefix.Substring(0, index) + "/Anim";
				var errorPaths = new List<string>();

				foreach (var dependencePath in dependencePaths)
				{
					if (dependencePath.EndsWith(".cs") || dependencePath.EndsWith(".shader"))
					{
						continue;
					}

					if (dependencePath.Equals(path))
					{
						continue;
					}

					if (dependencePath.StartsWith("Assets/__Art/StaticResources/Common/"))
					{
						continue;
					}

					if (dependencePath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
					{
						continue;
					}

					if (dependencePath.StartsWith(prefixAnim, StringComparison.OrdinalIgnoreCase))
					{
						continue;
					}

					errorPaths.Add(dependencePath);
				}

				if (errorPaths.Count > 0)
				{
					errGroup++;
					sb.AppendLine(path);
					foreach (var errorPath in errorPaths)
					{
						sb.Append(TAB).AppendLine(errorPath);
					}
					sb.AppendLine();
				}
			}

			if (sb.Length > 0)
			{
				var savePath = Path.GetFullPath(Path.Combine(Application.dataPath, "../Logs/场景模型检查结果.log"));
				NLogger.Error($"场景模型资源使用有{errGroup}组问题，请前往<a href=\"file:///{savePath}\">{savePath}</a>查看");
				File.WriteAllText(savePath, sb.ToString());
			}
			else
			{
				NLogger.Log("场景模型资源使用情况良好");
			}
		}


		//[MenuItem("DragonReborn/资源工具箱/资源规范/日常检查/4, 角色模型资源检查", false, 4)]
		public static void RunCharacterModelResourceCheck()
		{
			var folders = new[] 
			{ 
				"Assets/__Art/_Resources/Characters"
			};

			var guids = AssetDatabase.FindAssets("t:GameObject", folders);
			guids = FilterGuids(guids);

			// 获取实际依赖
			// AssetDatabase.GetDependencies()获得的依赖存在历史存在的依赖，结果不对
			var result = AssetsDependenciesGetter.GenerateForAssets(guids);
			var sb = new StringBuilder();
			var errGroup = 0;
			foreach (var (path, dependencePaths) in result)
			{
				var name = Path.GetFileName(path);
				var index = path.LastIndexOf(name);
				var prefix = path.Substring(0, index - 1).Replace("_Resources", "StaticResources");
				index = prefix.LastIndexOf("/");
				var prefixAnim = prefix.Substring(0, index) + "/Anim";
				var errorPaths = new List<string>();

				foreach (var dependencePath in dependencePaths)
				{
					if (dependencePath.EndsWith(".cs") || dependencePath.EndsWith(".shader"))
					{
						continue;
					}

					if (dependencePath.Equals(path))
					{
						continue;
					}

					// 公共文件夹
					if (dependencePath.StartsWith("Assets/__Art/StaticResources/Common/"))
					{
						continue;
					}

					if (dependencePath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
					{
						continue;
					}

					if (dependencePath.StartsWith(prefixAnim, StringComparison.OrdinalIgnoreCase))
					{
						continue;
					}

					if (prefix.Contains("/gpu")) 
					{
						var tmp = prefix.Replace("gpu", "Lod2");
						if (dependencePath.StartsWith(tmp, StringComparison.OrdinalIgnoreCase))
						{
							continue;
						}

						tmp = prefix.Replace("gpu", "Lod1");
						if (dependencePath.StartsWith(tmp, StringComparison.OrdinalIgnoreCase))
						{
							continue;
						}
					}

					errorPaths.Add(dependencePath);
				}

				if (errorPaths.Count > 0)
				{
					errGroup++;
					sb.AppendLine(path);
					foreach (var errorPath in errorPaths)
					{
						sb.Append(TAB).AppendLine(errorPath);
					}
					sb.AppendLine();
				}
			}

			if (sb.Length > 0)
			{
				var savePath = Path.GetFullPath(Path.Combine(Application.dataPath, "../Logs/角色模型检查结果.log"));
				NLogger.Error($"角色模型资源使用有{errGroup}组问题，请前往<a href=\"file:///{savePath}\">{savePath}</a>查看");
				File.WriteAllText(savePath, sb.ToString());
			}
			else
			{
				NLogger.Log("角色模型资源使用情况良好");
			}
		}

		[MenuItem("Assets/资源整理/选中并移动大世界资源")]
		private static void CreateFoldersAndMoveDependenciesForKingdomMap()
		{
			var guids = Selection.assetGUIDs;

			var whiteList = new List<string>
			{
				"Assets/__Art/_Resources/KingdomMap"
			};
			
			var blackList = new List<string>
			{
				"Assets/__Art/_Resources/",
				"Assets/__Art/StaticResources/KingdomMap/HexMap",
				"Assets/__Art/StaticResources/Characters",
				"Assets/__Art/StaticResources/Vfx",
				"Assets/__UI/StaticResources/VFX",
			};

			CreateFolders(guids, whiteList);
			MoveDependencies(guids, whiteList, blackList);
		}
		
		private static void CreateFolders(IEnumerable<string> guids, List<string> whiteList)
		{
			foreach (var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				if (!CheckWhiteList(path, whiteList))
				{
					continue;
				}
				
				var file = new FileInfo(path);
				if (string.IsNullOrEmpty(file.DirectoryName))
				{
					continue;
				}

				var dstDirectory = file.DirectoryName.Replace("_Resources", "StaticResources");
				var targetFolderPath = Path.Combine(dstDirectory, Path.GetFileNameWithoutExtension(path));
				if (Directory.Exists(targetFolderPath))
				{
					continue;
				}
				
				NLogger.Log($"目标文件夹{targetFolderPath}不存在，创建{targetFolderPath}");
				Directory.CreateDirectory(targetFolderPath);
			}

			AssetDatabase.Refresh();
		}

		private static bool CheckWhiteList(string path, List<string> whiteList)
		{
			foreach (var prefix in whiteList)
			{
				if (path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
				{
					return true;
				}
			}

			return false;
		}
		
		private static bool CheckBlackList(string path, List<string> blackList)
		{
			foreach (var prefix in blackList)
			{
				if (path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
				{
					return false;
				}
			}

			return true;
		}

		private static void MoveDependencies(IEnumerable<string> guids, List<string> whiteList, List<string> blackList)
		{
			var filteredGuids = new List<string>();
			var relativeRoot = Path.Combine(Application.dataPath, "../");

			foreach (var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				if (CheckWhiteList(path, whiteList))
				{
					filteredGuids.Add(guid);
				}
			}

			if (filteredGuids.Count == 0)
			{
				NLogger.Error("只能选Assets/__Art/_Resources/下的资源");
				return;
			}

			AssetDatabase.StartAssetEditing();
			var result = AssetsDependenciesGetter.GenerateForAssets(filteredGuids.ToArray());
			foreach (var (path, dependencePaths) in result)
			{
				var sourceFile = new FileInfo(path);
				if (string.IsNullOrEmpty(sourceFile.DirectoryName))
				{
					continue;
				}

				var dstDirectory = sourceFile.DirectoryName.Replace("_Resources", "StaticResources");

				NLogger.Log($"处理{path}的依赖资源...");
				foreach (var depPath in dependencePaths)
				{
					var file = new FileInfo(depPath);
					var depGuid = AssetDatabase.GUIDFromAssetPath(depPath);
					var extension = file.Extension;
					if (string.Compare(extension, ".cs", StringComparison.OrdinalIgnoreCase) == 0 ||
					    string.Compare(extension, ".shader", StringComparison.OrdinalIgnoreCase) == 0)
					{
						NLogger.Log($"忽略{depPath}，因为后缀为{extension}");
						continue;
					}

					if (!CheckBlackList(depPath, blackList))
					{
						continue;
					}

					if (!depPath.StartsWith("Assets/__Art/StaticResources/"))
					{
						NLogger.Error($"需要关注的异常：依赖资源不在Assets/__Art/StaticResources/内。DepPath = {depPath}");
					}

					var targetFolderPath = Path.Combine(dstDirectory, Path.GetFileNameWithoutExtension(path));
					if (!Directory.Exists(targetFolderPath))
					{
						NLogger.Error($"目标文件夹{targetFolderPath}不存在，请执行创建逻辑!");
						continue;
					}

					var targetPath = Path.GetRelativePath(relativeRoot, targetFolderPath + "/" + file.Name);
					NLogger.Log($"移动{depPath}到{targetPath}");
					AssetDatabase.MoveAsset(depPath, targetPath);
					AssetDatabase.SaveAssetIfDirty(depGuid);
				}

				NLogger.Log($"处理{path}的依赖资源完成...");
			}

			AssetDatabase.StopAssetEditing();
			AssetDatabase.Refresh();
		}

		public static bool CheckIsFbxAsPrefab(GameObject root)
		{
			var childCount = root.transform.childCount;
			if (childCount == 0)
			{
				NLogger.Error($"{root.name}没有任何子节点");
				return false;
			}

			var fbxRoot = root.transform.GetChild(0);
			if (!fbxRoot.name.StartsWith("fbx_", StringComparison.OrdinalIgnoreCase))
			{
				NLogger.Error($"{root.name}第一个子节点不是fbx，而是{fbxRoot.name}");
				return false;
			}

			if (PrefabUtility.IsAnyPrefabInstanceRoot(fbxRoot.gameObject))
			{
				return true;
			}

			return false;
		}
	}
}
