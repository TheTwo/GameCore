using System;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public static class PackBundleMark
	{
		public const string MarkerFileName = "__pack__";
		
		private delegate bool TryGetActiveFolderPathDelegate(out string path);

		private static bool PlaceHolder(out string path)
		{
			path = default;
			return false;
		}

		private static readonly TryGetActiveFolderPathDelegate TryGetActiveFolderPath;
		
		static PackBundleMark()
		{
			var t = typeof(ProjectWindowUtil);
			var method = t.GetMethod(nameof(TryGetActiveFolderPath),
				BindingFlags.Instance | BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
			TryGetActiveFolderPathDelegate methodDelegate = PlaceHolder;
			if (null != method)
			{
				try
				{
					methodDelegate =
						(TryGetActiveFolderPathDelegate)Delegate.CreateDelegate(typeof(TryGetActiveFolderPathDelegate),
							method);
				}
				catch (Exception)
				{
					// ignored
				}
			}
			TryGetActiveFolderPath = methodDelegate;
		}
		
		[MenuItem("Assets/Create/PackBundleFolderMarker", false, -1)]
		private static void CreateMarker()
		{
			if (!TryGetActiveFolderPath(out var path) || !path.StartsWith("Assets/")) return;
			if (CheckParentFolderHasFile(path, MarkerFileName, out var target))
			{
				if (EditorUtility.DisplayDialog("创建失败", $"父目录已经存在:{MarkerFileName}文件", "确定"))
				{
					EditorGUIUtility.PingObject(target);
				}
				return;
			}
			if (CheckSubFolder(path, MarkerFileName, out target))
			{
				if (EditorUtility.DisplayDialog("创建失败", $"子目录下已经存在:{MarkerFileName}文件", "确定"))
				{
					EditorGUIUtility.PingObject(target);
				}
				return;
			}
			var filePath = Path.Combine(Application.dataPath, path["Assets/".Length..],MarkerFileName);
			using var writer = File.CreateText(filePath);
			AssetDatabase.ImportAsset(path + "/" + MarkerFileName);
		}

		[MenuItem("Assets/Create/PackBundleFolderMarker", true, -1)]
		private static bool CheckCreateMarker()
		{
			if (!TryGetActiveFolderPath(out var path) || !path.StartsWith("Assets/")) return false;
			var filePath = Path.Combine(Application.dataPath, path["Assets/".Length..], MarkerFileName);
			return !File.Exists(filePath);
		}

		private static bool CheckParentFolderHasFile(string assetFolder, string name, out UnityEngine.Object target)
		{
			do
			{
				target = AssetDatabase.LoadAssetAtPath<DefaultAsset>($"{assetFolder}/{name}");
				if (target) return true;
				var index = assetFolder.LastIndexOf('/');
				if (index < 0) break;
				assetFolder = assetFolder[..index];
			} while (true);
			return (target);
		}

		private static bool CheckSubFolder(string assetFolder, string name, out UnityEngine.Object target)
		{
			target = null;
			var guids = AssetDatabase.FindAssets($"{name} t:DefaultAsset", new[] { assetFolder });
			foreach (var guid in guids)
			{
				var p = AssetDatabase.GUIDToAssetPath(guid);
				target = AssetDatabase.LoadAssetAtPath<DefaultAsset>(p);
				if (target)
				{
					return true;
				}
			}
			return false;
		}
	}
}
