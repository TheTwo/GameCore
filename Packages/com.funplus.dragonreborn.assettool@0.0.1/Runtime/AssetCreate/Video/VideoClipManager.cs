using System.Collections.Generic;
using UnityEngine.Video;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
	public class VideoClipManager : Singleton<VideoClipManager>, IManager
	{
		private Dictionary<string, AssetHandle> _allLoadedVideClip;

		public void OnGameInitialize(object configParam)
		{
			_allLoadedVideClip = new Dictionary<string, AssetHandle>();
		}

		public void Reset()
		{
			if (null == _allLoadedVideClip) return;
			foreach (var handle in _allLoadedVideClip.Values)
			{
				AssetManager.Instance.UnloadAsset(handle);
			}
			_allLoadedVideClip.Clear();
		}

		public VideoClip LoadVideoClip(string assetName)
		{
			if (null != _allLoadedVideClip && _allLoadedVideClip.TryGetValue(assetName, out var handle))
			{
				return handle.Asset as VideoClip;
			}

			// video clip 只能从resource 无压缩方式加载
			handle = AssetManager.Instance.LoadAsset(assetName, false, AssetManager.SyncLoadReason.ResourceLoad);
			if (handle.IsValid)
			{
				_allLoadedVideClip?.Add(assetName, handle);
				return handle.Asset as VideoClip;
			}
			NLogger.Error($"LoadVideoClip {assetName} failed.");
			return null;
		}

		public void UnloadVideoClip(string assetName)
		{
			if (null == _allLoadedVideClip || !_allLoadedVideClip.TryGetValue(assetName, out var handle)) return;
			_allLoadedVideClip.Remove(assetName);
			AssetManager.Instance.UnloadAsset(handle);
		}

		public void OnLowMemory()
		{

		}
	}
}
