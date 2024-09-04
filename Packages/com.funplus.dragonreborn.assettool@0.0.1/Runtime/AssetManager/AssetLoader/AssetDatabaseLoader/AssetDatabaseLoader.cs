// #define EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
#if UNITY_EDITOR
using System;
using System.Collections;
using UnityEditor;
using UnityEngine;
using Unity.EditorCoroutines.Editor;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public class AssetDatabaseLoader : IAssetLoader
    {
	    // ReSharper disable once InconsistentNaming
	    public static Func<string, string> sFindPathCallback;
		private const string LOG_CHANNEL = "AssetDatabaseLoader";
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
	    private readonly LoadAssetErrorChecker _loadAssetErrorChecker = new LoadAssetErrorChecker();
#endif

        public void Initialize()
        {
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
	        _loadAssetErrorChecker.Init();
#endif
		}

        public void Reset()
        {
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
	        _loadAssetErrorChecker.Release();
#endif
        }

        public UnityEngine.Object LoadAsset(BundleAssetData data, bool isSprite)
        {
	        var path = GetAssetDatabasePath(data.AssetName);
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
	        using (_loadAssetErrorChecker.Mark(path)){
#endif
	        if (isSprite)
            {
                return AssetDatabase.LoadAssetAtPath<Sprite>(path);    
            }
	        return AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(path);
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
	        }
#endif
        }

        public bool LoadAssetAsync(BundleAssetData data, Action<UnityEngine.Object> callback, bool isSprite)
        {
            var path = GetAssetDatabasePath(data.AssetName);
			try
			{
				UnityEngine.Object asset;
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
				using (_loadAssetErrorChecker.Mark(path)){
#endif

				if (isSprite)
				{
					asset = AssetDatabase.LoadAssetAtPath<Sprite>(path);
				}
				else
				{
					asset = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(path);
				}
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
				}
#endif
				if (asset != null)
				{
					IEnumerator Delay(int frameCount)
					{
						while (frameCount > 0)
						{
							yield return null;
							--frameCount;
						}

						callback(asset);
					}

					var randomDely = UnityEngine.Random.Range(1, 5);
					EditorCoroutineUtility.StartCoroutine(Delay(randomDely), this);
					return true;
				}
			}
			catch (Exception e)
			{
				NLogger.ErrorChannel(LOG_CHANNEL, $"LoadAssetAsync {path} fail. Msg: {e.Message}");
			}

            callback(null);
            return false;
        }

        public bool AssetExist(string assetName)
        {
            var path = GetAssetDatabasePath(assetName);
            return !string.IsNullOrEmpty(path);
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

        public bool IsAssetReady(string assetName)
        {
            return AssetExist(assetName);
        }
    }
    
    
#if EDITOR_RECURSIVE_SERIALIZATION_ERROR_DIAGNOSTICS
	internal class LoadAssetErrorChecker
	{
		private readonly System.Collections.Generic.Stack<string> _lastAsset = new();
		private int _enterCheckBlock;
		private bool _inWriteErrorBlock;
		private bool _init;
		
		public void Init()
		{
			if (_init) return;
			_init = true;
			Application.logMessageReceived += OnLogMessageReceived;
		}

		public void Release()
		{
			if (!_init) return;
			_init = false;
			Application.logMessageReceived -= OnLogMessageReceived;
		}

		private void OnLogMessageReceived(string condition, string stackTrace, LogType type)
		{
			if (type != LogType.Error) return;
			if (_inWriteErrorBlock) return;
			if (_enterCheckBlock <= 0) return;
			WriteError();
		}

		public IDisposable Mark(string asset)
		{
			PushCheck(asset);
			return new Handle(this);
		}

		private void PushCheck(string asset)
		{
			++_enterCheckBlock;
			_lastAsset.Push(asset);
		}

		private void PopCheck()
		{
			if (_lastAsset.Count <= 0) return;
			_lastAsset.Pop();
			--_enterCheckBlock;
		}

		private void WriteError()
		{
			_inWriteErrorBlock = true;
			if (_lastAsset.TryPeek(out var lastAsset))
			{
				Debug.LogErrorFormat("Load Asset:{0} error occured", lastAsset);
			}
			_inWriteErrorBlock = false;
		}
		
		public class Handle : IDisposable
		{
			private LoadAssetErrorChecker _host;

			public Handle(LoadAssetErrorChecker host)
			{
				_host = host;
			}

			void IDisposable.Dispose()
			{
				_host?.PopCheck();
				_host = null;
			}
		}
	}
#endif
}
#endif
