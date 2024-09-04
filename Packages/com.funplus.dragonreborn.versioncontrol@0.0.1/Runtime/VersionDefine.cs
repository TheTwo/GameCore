using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Scripting;

namespace DragonReborn
{
	[Preserve]
	[Serializable]
	public class VersionDefine
	{
		[Preserve]
		[Serializable]
		public class VersionCell
		{
			// ReSharper disable InconsistentNaming
			public string Md5;
			public uint Crc;
			public long RawBytes;
			public long ZipBytes;
			// ReSharper restore InconsistentNaming
		}

		public Dictionary<string, VersionCell> VersionDic = new();

		private static Dictionary<string, string> _bundlePathMap = new();

		private static Dictionary<string, Dictionary<string, VersionCell>> _folderPathVersionCells = new();

		public static VersionDefine CreateFromJson(string json)
		{
			return DataUtils.FromJson<VersionDefine>(json);
		}

		// 预创建 VersionDic 包含在 paths 内的 Dictionary<string, VersionCell> 
		public void PreCreateVersionDic(string[] folderPaths)
		{
			_folderPathVersionCells.Clear();

			foreach (var (path, cell) in VersionDic)
			{
				// 缓存folderPath对应的VersionCell
				string match = folderPaths.FirstOrDefault(folderPath => path.StartsWith(folderPath));
				if (match != null)
				{
					if (!_folderPathVersionCells.ContainsKey(match))
					{
						_folderPathVersionCells.Add(match, new Dictionary<string, VersionCell>());
					}

					_folderPathVersionCells[match][path] = cell;
				}
			}
		}

		private static Dictionary<string, VersionCell> _allPackVersionCells;
		public Dictionary<string, VersionCell> GetAllPackVersionCells()
		{
			if (_allPackVersionCells != null)
			{
				return _allPackVersionCells;
			}

			_allPackVersionCells = new Dictionary<string, VersionCell>();
			foreach (var (path, cell) in VersionDic)
			{
				// 缓存所有pack文件对应的VersionCell
				if (path.EndsWith(".pack"))
				{
					_allPackVersionCells[path] = cell;
				}
			}
			return _allPackVersionCells;
		}

		/// <summary>
		/// 通过目录名称进行前缀过滤
		/// </summary>
		/// <param name="folderPath"></param>
		/// <returns></returns>
		public Dictionary<string, VersionCell> FilterVersionCellsByFolderPath(string folderPath)
		{
			if (_folderPathVersionCells.TryGetValue(folderPath, out var byFolderPath))
			{
				return byFolderPath;
			}

			var result = new Dictionary<string, VersionCell>();
			foreach (var (path, cell) in VersionDic)
			{
				if (path.StartsWith(folderPath))
				{
					result[path] = cell;
				}
			}

			_folderPathVersionCells[folderPath] = result;

			return result;
		}

		/// <summary>
		/// 通过AssetBundle名称进行过滤
		/// </summary>
		/// <param name="bundleList"></param>
		/// <returns></returns>
		public Dictionary<string, VersionCell> FilterVersionCellsByBundleCollection(ICollection<string> bundleList)
		{
			var result = new Dictionary<string, VersionCell>();
			if (bundleList == null)
			{
				return result;
			}

			foreach (var bundleName in bundleList)
			{
				var relPath = GetBundleRelativePath(bundleName);
				if (VersionDic.ContainsKey(relPath))
				{
					result[relPath] = VersionDic[relPath];
				}
			}

			return result;
		}

		/// <summary>
		/// 通过AssetBundle名称进行过滤
		/// </summary>
		/// <param name="bundleList"></param>
		/// <returns></returns>
		public Dictionary<string, VersionCell> FilterVersionCellsByBundleParams(params string[] bundleArgs)
		{
			var result = new Dictionary<string, VersionCell>();

			foreach (var bundleName in bundleArgs)
			{
				var relPath = GetBundleRelativePath(bundleName);
				if (VersionDic.ContainsKey(relPath))
				{
					result[relPath] = VersionDic[relPath];
				}
			}

			return result;
		}

		/// <summary>
		/// 从total中，排除掉bundles
		/// </summary>
		/// <param name="total"></param>
		/// <param name="bundles"></param>
		/// <returns></returns>
		public Dictionary<string, VersionCell> Excludes(Dictionary<string, VersionCell> total, Dictionary<string, VersionCell> bundles)
		{
			var result = new Dictionary<string, VersionCell>();
			foreach (var (key, cell) in total)
			{
				if (bundles.ContainsKey(key))
				{
					continue;
				}

				result[key] = cell;
			}

			return result;
		}

		public VersionCell GetVersion(string file)
		{
			return VersionDic.TryGetValue(file, out var version) ? version : new VersionCell();
		}

		public void SetVersion(string file, VersionCell cell)
		{
			/*
	        if (VersionDic.ContainsKey(file))
            {
	            VersionDic[file] =  cell;
            }
	        else
            {
	            VersionDic.Add(file, cell);
            }
            */

			// 直接使用索引器设置值，如果键不存在将自动添加
			VersionDic[file] = cell;
		}

		public static string GetBundleRelativePath(string bundleName)
		{
			if (_bundlePathMap.TryGetValue(bundleName, out var path))
			{
				return path;
			}

			var fullpath = $"GameAssets/AssetBundle/{GetBundlePlatformFolderName()}/{bundleName}.ab";
			_bundlePathMap.Add(bundleName, fullpath);
			return fullpath;
		}

		public static string GetBundlePlatformFolderName()
		{
#if UNITY_EDITOR
#if USE_BUNDLE_ANDROID
            return "Android";
#elif USE_BUNDLE_IOS
            return "IOS";
#endif
#endif
			switch (Application.platform)
			{
				case RuntimePlatform.Android:
					return "Android";
				case RuntimePlatform.IPhonePlayer:
					return "IOS";
				case RuntimePlatform.OSXEditor:
				case RuntimePlatform.OSXPlayer:
					return "OSX";
				case RuntimePlatform.WindowsEditor:
				case RuntimePlatform.WindowsPlayer:
					return "Windows";
				default:
					throw new System.NotImplementedException();
			}
		}
	}
}

