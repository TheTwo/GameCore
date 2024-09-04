using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.IO;
using System.Linq;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using Object = System.Object;
using DragonReborn.AssetTool.Editor;

namespace DragonReborn.Utilities.Editor
{
	public class EditorUtils
	{
		public static bool EnableHierarchyChanged = true;
	
		public static List<string> GetSpecificResourcesInSpecificFolder(string[] paths, string tarname)
		{
			List<string> assets = new List<string>();
			List<string> tmpAssets = null;
			Regex reg = new Regex(tarname);

			string assetPath;

			for(int i = 0; i < paths.Length; ++i)
			{
				tmpAssets = FileUtils.GetAllResources(paths[i],Application.dataPath);

				for(int j = 0; j < tmpAssets.Count; ++j)
				{
					assetPath = tmpAssets[j];
					if(reg.IsMatch(assetPath))
					{
						//assets.Add("Assets" + assetPath);
						assets.Add(assetPath);
					}
				}
			}

			return assets;
		}

		public static void FindChildrenWithPrefix (Transform root, string prefix, bool exclusive, List<Transform> children)
		{
			if (!root)
			{
				return;
			}

			if (root.gameObject.name.StartsWith (prefix, StringComparison.InvariantCultureIgnoreCase))
			{
				children.Add (root);
				if (exclusive)
				{
					return;
				}
			}

			for (int i = 0; i < root.childCount; ++i)
			{
				var child = root.GetChild (i);
				FindChildrenWithPrefix (child, prefix, exclusive, children);
			}
		}

		static public T EnsureComponent<T>(GameObject go) where T : Component
		{
			if (!go)
			{
				return null;
			}

			T comp = go.GetComponent<T> ();
			if (!comp)
			{
				comp = go.AddComponent<T> ();
			}
			return comp;
		}

		public static void PrepareAssetPath()
		{
			AssetPathProvider.PrepareAssetPath();
		}

		public static string GetSavePath(string fileName)
		{
			return AssetPathService.GetSavePath(fileName);
		}

		public static void SavePrefab(string prefabPath,GameObject prefab)
		{
			var path = Path.GetDirectoryName(prefabPath);
			if (!Directory.Exists(path))
			{
				Directory.CreateDirectory(path);
			}
			PrefabUtility.SaveAsPrefabAsset(prefab, prefabPath);
			AssetDatabase.SaveAssets();
		}

		public static AnimationClip DuplicateAnimationClip (AnimationClip sourceClip)
		{
			if (sourceClip)
			{
				var path = AssetDatabase.GetAssetPath(sourceClip);
				path = Path.GetDirectoryName(path);
				path = Path.Combine(path, sourceClip.name).Replace('\\', '/') + ".anim";
				var targetClip = UnityEngine.Object.Instantiate(sourceClip);
				AssetDatabase.CreateAsset(targetClip, path);
				return targetClip;
			}
			return null;
		}

		public static string GetTransformFullPath (Transform t, string sep = "/")
		{
			string s = t.gameObject.name;

			t = t.parent;

			while (t) {
				s = t.name + sep +  s;

				t = t.parent;
			}

			return s;
		}

		/// <summary>
		/// 遍历全部ui场景的通用代码
		/// </summary>
		/// <param name="onVisit"></param>
		public static void TraversalAllUIScenes(string title, System.Action<Scene> onVisit, System.Action onComplete)
		{
			const string SCENE_PATH = "Assets/__Scene/StaticResources/UIScenes";
			var allUIScenes = AssetDatabase.FindAssets("t:scene", new string[] {SCENE_PATH});

			//var database = new UIMediatorPropertyDatabase();

			var activeScene = EditorSceneManager.GetActiveScene();
			var previousScene = activeScene.path;

			EditorUtils.PrepareAssetPath ();

			for (int i = 0; i < allUIScenes.Length; i++)
			{
				string scene = allUIScenes[i];
				string scenePath = AssetDatabase.GUIDToAssetPath(scene);

				UnityEditor.EditorUtility.DisplayProgressBar(String.Format("{0}({1}/{2})", title, i + 1, allUIScenes.Length), scenePath,
					i / (float) allUIScenes.Length);

				var openedScene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);

				// 做实际的事情
				onVisit?.Invoke(openedScene);
			}

			onComplete?.Invoke();

			// 全部结束后的单独事件
			UnityEditor.EditorUtility.ClearProgressBar();
			EditorSceneManager.OpenScene(previousScene);
		}

		public static IList<string> FindOtherAssetWithSameName(string filePath, string[] folders)
		{			
			var fileName = Path.GetFileName(filePath);
			var assetName = Path.GetFileNameWithoutExtension(filePath);
			if (string.IsNullOrWhiteSpace(assetName))
			{
				Debug.LogErrorFormat("filePath:{0}, assetName is Empty!", filePath);
				return Array.Empty<string>();
			}
			string[] guids = null;
			guids = folders is { Length: > 0 } ? AssetDatabase.FindAssets(assetName, folders) : AssetDatabase.FindAssets(assetName);
			if(guids == null || guids.Length == 0)
			{
				return Array.Empty<string>();
			}
			var files = new List<string>();
			foreach( var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				if (string.IsNullOrWhiteSpace(path)) continue;
				if(path == filePath)
				{
					continue;
				}
				var name = Path.GetFileName(path);
				if(name == fileName)
				{
					files.Add(path);
				}
			}
			return files;
		}

		public static bool MoveOtherAssetWithSameName(string filePath, string[] folders)
		{			
			var delFiles = FindOtherAssetWithSameName(filePath, folders);
			if (delFiles.Count <= 0) return true;
			if(!File.Exists(filePath) && delFiles.Count == 1)
			{
				var moveLog = AssetDatabase.MoveAsset(delFiles[0], filePath);
				if (!string.IsNullOrEmpty(moveLog))
				{
					Debug.LogError($"[MoveAssetWithSameName] 移动文件出错！{delFiles[0]} to {filePath} Error:{moveLog}");
					return false;
				}
				return true;
			}
			else if(delFiles.Count > 1)
			{	
				for (int i = 0; i < delFiles.Count; i++)
				{
					string toRemoveAsset = delFiles[i];
					Debug.LogError($"[MoveAssetWithSameName] 找到了多个同名文件 {toRemoveAsset}");
				}
				return false;
			}
			return true;

		}
	}
}
