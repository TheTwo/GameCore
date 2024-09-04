using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;
using UnityEngine.Pool;
using UnityEngine.SceneManagement;

namespace DragonReborn.AssetTool
{
    public class SceneLoadUtility
    {
        // ReSharper disable once InconsistentNaming
        private const string LOG_CHANNEL = "SceneLoadUtility";
        private static readonly Dictionary<string, SceneLoadInfo> SceneLoadInfos = new(StringComparer.Ordinal);
        
        public static string GetSceneName(string scenePath)
        {
            return Path.GetFileNameWithoutExtension(scenePath);
        }
        
        public static GameObject GetRoot(string name)
        {
            var curScene = SceneManager.GetActiveScene();
            var rootGos = curScene.GetRootGameObjects();
            return rootGos is not { Length: > 0 } ? null : rootGos.FirstOrDefault(go => go.name == name);
        }

        public static void PreLoadSceneAsync(string scenePath)
        {
            if (SceneLoadInfos.TryGetValue(scenePath, out var info))
            {
                if (info.TargetStatus < SceneLoadStatus.SceneLoading)
                {
                    info.LoadButNoActive();
                }
                return;
            }
            info = new SceneLoadInfo(scenePath);
            SceneLoadInfos.Add(scenePath, info);
            info.LoadButNoActive();
        }

        public static bool HasPreLoadScene(string scenePath)
        {
            return SceneLoadInfos.TryGetValue(scenePath, out var info) && info.PreloadFlag.HasValue && info.PreloadFlag.Value;
        }

        public static bool IsReadyForAllowSceneActivation(string scenePath)
        {
            return SceneLoadInfos.TryGetValue(scenePath, out var info) && info.ReadyForAllowSceneActivation;
        }

        public static bool HasLoadedScene(string scenePath)
        {
            return SceneLoadInfos.TryGetValue(scenePath, out var info) && info.Status >= SceneLoadStatus.SceneLoaded;
        }

        public static void ClearAll()
        {
            using (ListPool<SceneLoadInfo>.Get(out var list))
            {
                list.Clear();
                list.AddRange(SceneLoadInfos.Values);
                SceneLoadInfos.Clear();
                foreach (var sceneLoadInfo in list)
                {
                    sceneLoadInfo.Unload(true, null);
                }
            }
        }

        public static void LoadSceneAsync(string scenePath, Action onSceneLoadFinish, Action<bool> onSceneActive)
        {
            if (SceneLoadInfos.TryGetValue(scenePath, out var info))
            {
                info.LoadAndActive(onSceneLoadFinish, onSceneActive);
                return;
            }
            info = new SceneLoadInfo(scenePath);
            SceneLoadInfos.Add(scenePath, info);
            info.LoadAndActive(onSceneLoadFinish, onSceneActive);
        }

        public static void UnloadSceneAsync(string scenePath, Action onSceneUnloadFinish)
        {
            if (!SceneLoadInfos.Remove(scenePath, out var info)) return;
            info.Unload(false, onSceneUnloadFinish);
        }

        public static void UnloadScene(string scenePath)
        {
            if (!SceneLoadInfos.Remove(scenePath, out var info)) return;
            info.Unload(true, null);
        }
        
        private static bool SetActiveScene(string sceneName)
        {
#if !UNITY_EDITOR || USE_BUNDLE_IOS || USE_BUNDLE_ANDROID || USE_BUNDLE_STANDALONE
            var scene = SceneManager.GetSceneByName(sceneName);
#else
            var scene = SceneManager.GetSceneByPath(sceneName);
#endif
            if (scene.IsValid())
            {
                if (!SceneManager.SetActiveScene(scene))
                {
                    NLogger.ErrorChannel(LOG_CHANNEL, $"Set scene {sceneName} active failed");    
                }
                else
                {
                    return true;
                }
            }
            else
            {
                NLogger.ErrorChannel(LOG_CHANNEL, $"Get scene error {sceneName}");
            }
            return false;
        }

        public enum SceneLoadStatus
        {
            None = 0,
            BundlePreparing = 1,
            BundlePrepared = 2,
            SceneLoading = 3,
            SceneLoaded = 4,
            SceneActive = 5,
        }
        
        public class SceneLoadInfo
        {
            public bool? PreloadFlag { get; private set; }
            public readonly string SceneAssetPath;
            public readonly string ScenePathFullPath;
            public SceneLoadStatus Status { get; private set; }
            public SceneLoadStatus TargetStatus { get; private set; }
            public bool ReadyForAllowSceneActivation =>
                Status >= SceneLoadStatus.SceneLoaded
                || (Status == SceneLoadStatus.SceneLoading && _sceneAsyncLoadOp is
                {
                    allowSceneActivation: false,
                    progress: >= 0.9f
                });

            private Action _onSceneLoaded;
            private Action<bool> _onSceneActive;
            private Action _onSceneUnloadFinished;
            private bool _syncUnload;
            private AsyncOperation _sceneAsyncLoadOp;
            private bool _allowSceneActivation;

            public SceneLoadInfo(string scenePathFullPath)
            {
                SceneAssetPath = Path.GetFileNameWithoutExtension(scenePathFullPath);
                ScenePathFullPath = scenePathFullPath;
                Status = SceneLoadStatus.None;
                TargetStatus = SceneLoadStatus.None;
            }

            private void DoBundlePreparing()
            {
                Status = SceneLoadStatus.BundlePreparing;
                if (AssetManager.Instance.IsBundleMode())
                {
                    var cacheIndex = Path.GetFileNameWithoutExtension(SceneAssetPath);    // scene name and lowercase
                    // 取得scene和AssetBundle的关系
                    var bundleAssetData = BundleAssetDataManager.Instance.GetAssetData(cacheIndex);
                    if (bundleAssetData != null && bundleAssetData.IsScene)
                    {
                        // AssetBundleCache引用计数加一
                        AssetManager.Instance.AssetCachePool.AssetLoaderProxy.AssetBundleLoader.OnAssetCacheCreate(bundleAssetData);
	                
                        // 下载依赖的AssetBundle
                        var allBundleNeedSync = new List<string>();
                        var dependenceData = BundleDependenceManager.Instance.GetBundleDependence(bundleAssetData.BundleName);
                        if(dependenceData != null && dependenceData.HasDependence())
                        {
                            allBundleNeedSync.AddRange(dependenceData.Dependence);
                        }
                        allBundleNeedSync.Add(bundleAssetData.BundleName);
                        AssetBundleSyncManager.Instance.SyncAssetBundles(allBundleNeedSync, (_) =>
                        {
                            // 加载依赖的AssetBundle
#if USING_ORIGIN_BUNDLE_REF_COUNTER
                            AssetManager.Instance.AssetCachePool.AssetLoaderProxy.AssetBundleLoader.LoadBundle(bundleAssetData, false);
#else
                            AssetManager.Instance.AssetCachePool.AssetLoaderProxy.AssetBundleLoader.LoadBundle(bundleAssetData);
#endif
                            OnBundlePrepared();
                        }, null, (int)DownloadPriority.High);
                    }
                }
                else
                {
                    OnBundlePrepared();
                }
            }

            private void DoBundleUnloading()
            {
                Status = SceneLoadStatus.BundlePreparing;
                if (AssetManager.Instance.IsBundleMode())
                {
                    var bundleAssetData = BundleAssetDataManager.Instance.GetAssetData(SceneAssetPath);
                    if (bundleAssetData != null)
                        AssetManager.Instance.AssetCachePool.AssetLoaderProxy.AssetBundleLoader.OnAssetCacheRelease(bundleAssetData);
                }
                Status = SceneLoadStatus.None;
                if (TargetStatus > Status)
                {
                    DoBundlePreparing();
                }
            }

            private void OnBundlePrepared()
            {
                Status = SceneLoadStatus.BundlePrepared;
                if (TargetStatus > Status)
                {
                    DoSceneLoading();
                }
                else if (TargetStatus < Status)
                {
                    DoBundleUnloading();
                }
            }

            private void OnSceneUnloaded(AsyncOperation _)
            {
                Status = SceneLoadStatus.BundlePrepared;
                var callback = _onSceneUnloadFinished;
                _onSceneUnloadFinished = null;
                callback?.Invoke();
                if (TargetStatus < Status)
                {
                    DoBundleUnloading();
                }else if (TargetStatus > Status)
                {
                    DoSceneLoading();
                }
            }

            private void DoSceneLoading()
            {
                Status = SceneLoadStatus.SceneLoading;
                if (AssetManager.Instance.IsBundleMode())
                {
                    _sceneAsyncLoadOp = SceneManager.LoadSceneAsync(SceneAssetPath, new LoadSceneParameters(LoadSceneMode.Additive, LocalPhysicsMode.Physics3D));
                    if (_sceneAsyncLoadOp == null)
                    {
                        NLogger.ErrorChannel(LOG_CHANNEL, $"Load scene {SceneAssetPath} error");
                    }
                    else
                    {
                        _sceneAsyncLoadOp.allowSceneActivation = _allowSceneActivation;
                        _sceneAsyncLoadOp.completed += OnSceneLoaded;
                    }
                }
                else
                {
#if UNITY_EDITOR
                    _sceneAsyncLoadOp = UnityEditor.SceneManagement.EditorSceneManager.LoadSceneAsyncInPlayMode(ScenePathFullPath, new LoadSceneParameters(LoadSceneMode.Additive, LocalPhysicsMode.Physics3D));
                    _sceneAsyncLoadOp.allowSceneActivation = _allowSceneActivation;
                    _sceneAsyncLoadOp.completed += OnSceneLoaded;
#else
                    NLogger.ErrorChannel(LOG_CHANNEL, $"Load scene {SceneAssetPath} error, should load from AssetBundle");
#endif
                }
            }
            
            private void DoSceneUnloading()
            {
                var syncUnload = _syncUnload;
                _syncUnload = false;
                Status = SceneLoadStatus.SceneLoading;
                if (AssetManager.Instance.IsBundleMode())
                {
                    if (syncUnload)
                    {
#pragma warning disable CS0618 // Type or member is obsolete
                        SceneManager.UnloadScene(SceneAssetPath);
#pragma warning restore CS0618 // Type or member is obsolete
                        OnSceneUnloaded(null);
                        return;
                    }
                    var asyncOp = SceneManager.UnloadSceneAsync(SceneAssetPath);
                    if (asyncOp == null)
                    {
                        NLogger.ErrorChannel(LOG_CHANNEL, $"UnLoading scene {SceneAssetPath} error");
                        OnSceneUnloaded(null);
                    }
                    else
                    {
                        asyncOp.completed += OnSceneUnloaded;
                    }
                }
                else
                {
#if UNITY_EDITOR
                    if (syncUnload)
                    {
#pragma warning disable CS0618 // Type or member is obsolete
                        SceneManager.UnloadScene(ScenePathFullPath);
#pragma warning restore CS0618 // Type or member is obsolete
                        return;
                    }
                    var asyncOp = SceneManager.UnloadSceneAsync(ScenePathFullPath);
                    if (asyncOp == null)
                    {
                        NLogger.ErrorChannel(LOG_CHANNEL, $"UnLoading scene {SceneAssetPath} error");
                        OnSceneUnloaded(null);
                    }
                    else
                    {
                        asyncOp.completed += OnSceneUnloaded;
                    }
#else
                    NLogger.ErrorChannel(LOG_CHANNEL, $"UnLoading scene {ScenePathFullPath} error, should load from AssetBundle");
#endif
                }
            }

            private void OnSceneLoaded(AsyncOperation _)
            {
                _sceneAsyncLoadOp = null;
                _allowSceneActivation = false;
                Status = SceneLoadStatus.SceneLoaded;
                var c = _onSceneLoaded;
                _onSceneLoaded = null;
                c?.Invoke();
                if (TargetStatus > Status)
                {
                    OnSceneActive();
                }else if (TargetStatus < Status)
                {
                    DoSceneUnloading();
                }
            }

            private void OnSceneActive()
            {
                Status = SceneLoadStatus.SceneActive;
                var success = SetActiveScene(AssetManager.Instance.IsBundleMode() ? SceneAssetPath : ScenePathFullPath);
                var c = _onSceneActive;
                _onSceneActive = null;
                c?.Invoke(success);
            }

            public void LoadButNoActive()
            {
                PreloadFlag ??= true;
                TargetStatus = SceneLoadStatus.SceneLoaded;
                _allowSceneActivation = false;
                switch (Status)
                {
                    case SceneLoadStatus.None:
                        DoBundlePreparing();
                        break;
                    case SceneLoadStatus.BundlePreparing:
                        break;
                    case SceneLoadStatus.BundlePrepared:
                        DoSceneLoading();
                        break;
                    case SceneLoadStatus.SceneLoading:
                    case SceneLoadStatus.SceneLoaded:
                    case SceneLoadStatus.SceneActive:
                        break;
                    default:
                        NLogger.ErrorChannel(LOG_CHANNEL, "LoadAndActive but current status:{0} not support", Status);
                        break;
                }
            }

            public void LoadAndActive(Action onSceneLoaded, Action<bool> onSceneActive)
            {
                PreloadFlag = false;
                _onSceneLoaded = onSceneLoaded;
                _onSceneActive = onSceneActive;
                _allowSceneActivation = true;
                TargetStatus = SceneLoadStatus.SceneActive;
                switch (Status)
                {
                    case SceneLoadStatus.None:
                        DoBundlePreparing();
                        break;
                    case SceneLoadStatus.BundlePreparing:
                        break;
                    case SceneLoadStatus.BundlePrepared:
                        DoSceneLoading();
                        break;
                    case SceneLoadStatus.SceneLoading:
                        if (_sceneAsyncLoadOp != null)
                        {
                            _sceneAsyncLoadOp.allowSceneActivation = _allowSceneActivation;
                        }
                        break;
                    case SceneLoadStatus.SceneLoaded:
                    {
                        var c = _onSceneLoaded;
                        _onSceneLoaded = null;
                        c?.Invoke();
                        OnSceneActive();
                    }
                        break;
                    case SceneLoadStatus.SceneActive:
                    {
                        var loaded = _onSceneLoaded;
                        var active = _onSceneActive;
                        _onSceneLoaded = null;
                        _onSceneActive = null;
                        loaded?.Invoke();
                        var success = SetActiveScene(SceneAssetPath);
                        active?.Invoke(success);
                    }
                        break;
                    default:
                        _onSceneLoaded = null;
                        _onSceneActive = null;
                        NLogger.ErrorChannel(LOG_CHANNEL, "LoadAndActive but current status:{0} not support", Status);
                        break;
                }
            }

            public void Unload(bool syncUnload, Action onSceneUnloadFinish)
            {
                _onSceneLoaded = null;
                _onSceneActive = null;
                _syncUnload = syncUnload;
                TargetStatus = SceneLoadStatus.None;
                _allowSceneActivation = false;
                switch (Status)
                {
                    case SceneLoadStatus.None:
                    case SceneLoadStatus.BundlePreparing:
                        _syncUnload = false;
                        onSceneUnloadFinish?.Invoke();
                        break;
                    case SceneLoadStatus.BundlePrepared:
                        _syncUnload = false;
                        onSceneUnloadFinish?.Invoke();
                        DoBundleUnloading();
                        break;
                    case SceneLoadStatus.SceneLoading:
                        if (_sceneAsyncLoadOp != null)
                        {
                            _sceneAsyncLoadOp.allowSceneActivation = true;
                        }
                        break;
                    case SceneLoadStatus.SceneLoaded:
                    case SceneLoadStatus.SceneActive:
                        _onSceneUnloadFinished = onSceneUnloadFinish;
                        DoSceneUnloading();
                        break;
                    default:
                        NLogger.ErrorChannel(LOG_CHANNEL, "Unload but current status:{0} not support", Status);
                        break;
                }
            }
        }
    }
}