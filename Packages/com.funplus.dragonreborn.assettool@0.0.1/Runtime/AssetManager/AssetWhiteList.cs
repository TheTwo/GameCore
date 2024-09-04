#if UNITY_DEBUG || UNITY_EDITOR
#define ASSET_DEBUG
#endif

using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;


#if ASSET_DEBUG
namespace DragonReborn.AssetTool
{
	public class AssetWhiteList
	{
		public static Func<string, string> sFindPathCallback;

		private HashSet<string> _assetWhiteList;
		private HashSet<string> _badAssets;

		private float _lastCheckTime;
		private const float CHECK_INTERVAL = 1f;
		private bool _dirty;
		
		public void Initialize()
		{
			_assetWhiteList = new();
			_badAssets = new();

			FillWhiteList("AssetsUsedByCode");
			FillWhiteList("AssetsUsedByConfig");
			FillWhiteList("AssetsUsedByCityDynamicLoad");
		}

		private void FillWhiteList(string assetIndex)
		{
			var text = AssetManager.Instance.LoadText(assetIndex, AssetManager.SyncLoadReason.ResourceLoad);

			string line;
			using (var reader = new StringReader(text))
			{
				while ((line = reader.ReadLine()) != null)
				{
					if (string.IsNullOrEmpty(line))
					{
						continue;
					}

					_assetWhiteList.Add(line);
				}
			}
		}

		private bool IsArtAsset(string assetIndex)
		{
			if (AssetManager.Instance.IsBundleMode())
			{
				var bundleAssetData = BundleAssetDataManager.Instance.GetAssetData(assetIndex);
				if (bundleAssetData != null)
				{
					var bundleName = bundleAssetData.BundleName;
					if (string.IsNullOrEmpty(bundleName))
					{
						return false;
					}

					if (bundleName.StartsWith("art@", StringComparison.OrdinalIgnoreCase))
					{
						return true;
					}
				}
			}
			else
			{
				var fullpath = GetAssetDatabasePath(assetIndex);
				if (fullpath != null && fullpath.Contains("__Art", StringComparison.OrdinalIgnoreCase))
				{
					return true;
				}
			}
			

			return false;
		}

		private string GetAssetDatabasePath(string assetPath)
		{
			if (sFindPathCallback != null)
			{
				var tempPath = sFindPathCallback(assetPath);
				if (!string.IsNullOrEmpty(tempPath))
				{
					return tempPath;
				}
			}

			return null;
		}

		public void CheckAsset(string assetIndex)
		{
			if (!Application.isPlaying) return;

			if (!_assetWhiteList.Contains(assetIndex) && IsArtAsset(assetIndex))
			{
				if (_badAssets.Add(assetIndex))
				{
					_dirty = true;
				}
			}
		}

		public void Reset()
		{
			_assetWhiteList.Clear();
			_badAssets.Clear();
		}

		public void Tick(float deltaTime)
		{
			if (!Application.isPlaying)
			{
				return;
			}

			if (!_dirty)
			{
				return;
			}

			_lastCheckTime += deltaTime;
			if (_lastCheckTime > CHECK_INTERVAL)
			{
				_lastCheckTime = 0f;
				_dirty = false;

				DumpBadAssets();
			}
		}

		public void DumpBadAssets()
		{
			if (_badAssets.Count <= 0)
			{
				return;
			}

			var path = Path.Combine(Application.persistentDataPath, "bad_assets.txt");
			using (var reader = new StreamWriter(path))
			{
				foreach (var line in _badAssets)
				{
					reader.WriteLine(line);
				}
			}
		}
	}
}

#endif
