using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using DragonReborn.AssetTool;
using UnityEngine;
using UnityEngine.Pool;

[assembly: UnityEngine.Scripting.AlwaysLinkAssembly]
[assembly: UnityEngine.Scripting.Preserve]

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    internal class UILifeCircleEventReceiver : IUILifeCircleEventReceiver
    {
        [Serializable]
        private class UIRecord
        {
            public int RuntimeId;
            public string UiMediatorName;
            public string UiPrefabAssetName;
            public long TimeMs;
            public long FrameCount;
            public List<AssetCacheInfo> AssetCacheInfos = new ();
            public List<SpriteRefInfo> SpriteRefInfos = new();
            public List<BundleCacheInfo> BundleCacheInfos = new();

            public UIRecord(int runtimeId, string uiMediatorName, string uiPrefabAssetName)
            {
                RuntimeId = runtimeId;
                UiMediatorName = uiMediatorName;
                UiPrefabAssetName = uiPrefabAssetName;
                TimeMs = Mathf.FloorToInt(Time.realtimeSinceStartup * 1000);
                FrameCount = Time.frameCount;
            }

            public void Clear()
            {
                AssetCacheInfos.Clear();
                SpriteRefInfos.Clear();
                BundleCacheInfos.Clear();
            }

            private static readonly Comparison<AssetCacheInfoDiff> CompareAssetCacheInfoDiffFunc = (a, b) => string.CompareOrdinal(a.Key, b.Key);
            private static readonly Comparison<SpriteRefInfoDiff> CompareSpriteRefInfoDiffFunc = (a, b) => string.CompareOrdinal(a.Key, b.Key);
            private static readonly Comparison<BundleCacheInfoDiff> CompareBundleCacheInfoDiffFunc = (a, b) => string.CompareOrdinal(a.Key, b.Key);

            public void GetDiff(UIRecordDiff writeTo, UIRecord toStatusRecord)
            {
                writeTo.RuntimeId = RuntimeId;
                writeTo.UiMediatorName = UiMediatorName;
                writeTo.UiPrefabAssetName = UiPrefabAssetName;
                writeTo.TimeMs = TimeMs;
                writeTo.ToTimeMs = toStatusRecord.TimeMs;
                writeTo.FrameCount = FrameCount;
                writeTo.ToFrameCount = toStatusRecord.FrameCount;
                writeTo.AssetCacheInfos.Clear();
                writeTo.SpriteRefInfos.Clear();
                writeTo.BundleCacheInfos.Clear();
                using (DictionaryPool<string, AssetCacheInfo>.Get(out var dicInfo))
                {
                    foreach (var assetCacheInfo in AssetCacheInfos)
                    {
                        dicInfo[assetCacheInfo.AssetName] = assetCacheInfo;
                    }
                    foreach (var assetCacheInfo in toStatusRecord.AssetCacheInfos)
                    {
                        dicInfo.TryGetValue(assetCacheInfo.AssetName, out var oldData);
                        var diff = assetCacheInfo - oldData;
                        if (!diff.RefCount.Changed || diff.RefCount.Value <= 0) continue;
                        writeTo.AssetCacheInfos.Add(diff);
                    }
                    writeTo.AssetCacheInfos.Sort(CompareAssetCacheInfoDiffFunc);
                }
                using (DictionaryPool<string, SpriteRefInfo>.Get(out var dicInfo))
                {
                    foreach (var spriteRefInfo in SpriteRefInfos)
                    {
                        dicInfo[spriteRefInfo.SpriteName] = spriteRefInfo;
                    }
                    foreach (var spriteRefInfo in toStatusRecord.SpriteRefInfos)
                    {
                        dicInfo.TryGetValue(spriteRefInfo.SpriteName, out var oldData);
                        var diff = spriteRefInfo - oldData;
                        if (!diff.Count.Changed || diff.Count.Value <= 0) continue;
                        writeTo.SpriteRefInfos.Add(diff);
                    }
                    writeTo.SpriteRefInfos.Sort(CompareSpriteRefInfoDiffFunc);
                }
                using (DictionaryPool<string, BundleCacheInfo>.Get(out var dicInfo))
                {
                    foreach (var bundleCacheInfo in BundleCacheInfos)
                    {
                        dicInfo[bundleCacheInfo.BundleName] = bundleCacheInfo;
                    }
                    foreach (var bundleCacheInfo in toStatusRecord.BundleCacheInfos)
                    {
                        dicInfo.TryGetValue(bundleCacheInfo.BundleName, out var oldData);
                        var diff = bundleCacheInfo - oldData;
                        if (!diff.AnyDiff()) continue;
                        writeTo.BundleCacheInfos.Add(diff);
                    }
                    writeTo.BundleCacheInfos.Sort(CompareBundleCacheInfoDiffFunc);
                }
            }
        }
        
        [Serializable]
        private class UIRecordDiff
        {
            // ReSharper disable NotAccessedField.Local
            public int RuntimeId;
            public string UiMediatorName;
            public string UiPrefabAssetName;
            public long TimeMs;
            public long ToTimeMs;
            public long FrameCount;
            public long ToFrameCount;
            public List<AssetCacheInfoDiff> AssetCacheInfos = new();
            public List<SpriteRefInfoDiff> SpriteRefInfos = new();
            public List<BundleCacheInfoDiff> BundleCacheInfos = new();
            // ReSharper restore NotAccessedField.Local

            public void Clear()
            {
                AssetCacheInfos.Clear();
                SpriteRefInfos.Clear();
                BundleCacheInfos.Clear();
            }

            public bool NoChange()
            {
                return AssetCacheInfos.Count <= 0 && SpriteRefInfos.Count <= 0 && BundleCacheInfos.Count <= 0;
            }
        } 

        private readonly Dictionary<int, UIRecord> _records = new();
        private readonly Queue<(int, int, long, int)> _delayClosedUIQueue = new();
        private volatile UIRecord _tempCacheA = new(0, string.Empty, string.Empty);
        private volatile UIRecord _tempCacheB = new(0, string.Empty, string.Empty);
        private volatile UIRecord _threadProcessRecord;
        private readonly object _tempCacheLocker = new();
        private readonly AutoResetEvent _autoResetEvent = new(false);
        private readonly string _logFileFolder;
        private long _threadRunningFlag = -1;
        private bool _isRecording;
        private StreamWriter _changeLogStream;
        private Thread _writeThread;
        private Task _lastWriteTask;
#if ENABLE_UI_LIFE_CIRCLE_ASSET_REF_PROFILER_DETAIL
        private Task _lastDetailWriteTask;
#endif

        private UILifeCircleEventReceiver()
        {
            var sessionGuid = Guid.NewGuid().ToString("N");
#if UNITY_EDITOR
            _logFileFolder = Path.Combine(Path.GetFullPath("."), "Logs/uiResourceProfiler", sessionGuid);
#else
            _logFileFolder = Path.Combine(Application.persistentDataPath, "Logs/uiResourceProfiler", sessionGuid);
#endif
        }

        ~UILifeCircleEventReceiver()
        {
            _autoResetEvent.Dispose();
            _changeLogStream?.Dispose();
        }

        public void StartRecord()
        {
            if (Interlocked.Exchange(ref _threadRunningFlag, 1) == 1) return;
            UILifeCircleEventReceiverUnityLife.Create(StopRecord, DelayProcessUiClosed);
            _isRecording = true;
            _autoResetEvent.Reset();
            if (!Directory.Exists(_logFileFolder)) Directory.CreateDirectory(_logFileFolder);
            _changeLogStream = new StreamWriter(new FileStream(Path.Combine(_logFileFolder, $"record_{DateTime.Now:yyyy_MM_dd_HH-mm-ss}.log"), FileMode.Create, FileAccess.Write, FileShare.Read), Encoding.UTF8);
            _writeThread = new Thread(ThreadWork);
            _writeThread.Start();
        }

        public void StopRecord()
        {
            if (Interlocked.CompareExchange(ref _threadRunningFlag, 0,1) == 0) return;
            while (_delayClosedUIQueue.TryDequeue(out var infoPair))
            {
                DoAfterUIClosed(in infoPair);
            }
            _isRecording = false;
            lock (_tempCacheLocker)
            {
                Interlocked.Exchange(ref _threadProcessRecord, null);
            }
            _autoResetEvent.Set();
            _writeThread?.Join();
            _writeThread = null;
            _changeLogStream?.Dispose();
            _changeLogStream = null;
        }

        public void BeforeUIPrefabCreate(int runTimeId, string uiMediatorName, string uiPrefabAssetName)
        {
            if (!_isRecording) return;
            var record = new UIRecord(runTimeId, uiMediatorName, uiPrefabAssetName);
            AssetManager.Instance.DumpCurrentAssetCacheInfo(record.AssetCacheInfos, record.BundleCacheInfos);
            SpriteManager.Instance.DumpSpriteRefCountInfo(record.SpriteRefInfos);
            _records[runTimeId] = record;
        }

        public void AfterUIClosed(int runTimeId)
        {
            if (!_isRecording) return;
            var currentFrameCount = Time.frameCount;
            var currentTime = (long)Time.realtimeSinceStartupAsDouble * 1000;
            _delayClosedUIQueue.Enqueue((runTimeId, currentFrameCount, currentTime, currentFrameCount + 2));
        }

        private void DoAfterUIClosed(in (int, int, long, int) dataPair)
        {
            if (!_isRecording) return;
            var (runTimeId, frameCount, timeMs, _) = dataPair;
            if (!_records.Remove(runTimeId, out var record)) return;
            _tempCacheA.Clear();
            _tempCacheA.TimeMs = timeMs;
            _tempCacheA.FrameCount = frameCount;
            AssetManager.Instance.DumpCurrentAssetCacheInfo(_tempCacheA.AssetCacheInfos, _tempCacheA.BundleCacheInfos);
            SpriteManager.Instance.DumpSpriteRefCountInfo(_tempCacheA.SpriteRefInfos);
            lock (_tempCacheLocker)
            {
                (_tempCacheA, _tempCacheB) = (_tempCacheB, _tempCacheA);
                _threadProcessRecord = record;
                _autoResetEvent.Set();
            }
        }

        private void DelayProcessUiClosed()
        {
            var processCount = _delayClosedUIQueue.Count;
            var currentFrameCount = Time.frameCount;
            while (processCount-- > 0)
            {
                if (!_delayClosedUIQueue.TryDequeue(out var delayFramePair)) break;
                if (delayFramePair.Item4 <= currentFrameCount)
                {
                    DoAfterUIClosed(in delayFramePair);
                }
                else
                {
                    _delayClosedUIQueue.Enqueue(delayFramePair);
                }
            }
            
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterAssembliesLoaded)]
        private static void StaticRegister()
        {
#if UNITY_EDITOR
            if (Application.isBatchMode) return;
#endif
            FrameworkInterfaceManager.RegisterFrameInterface(new UILifeCircleEventReceiverDescriptor());
        }
        
        private class UILifeCircleEventReceiverDescriptor : FrameInterfaceDescriptor<IUILifeCircleEventReceiver>
        {
            protected override IUILifeCircleEventReceiver Create()
            {
                return new UILifeCircleEventReceiver();
            }
        }
        
        private readonly UIRecordDiff _writeDiff = new();
        
#if ENABLE_UI_LIFE_CIRCLE_ASSET_REF_PROFILER_DETAIL
        [Serializable]
        private struct UIRecordUIPair
        {
            public int RuntimeId;
            public string UiMediatorName;
            public string UiPrefabAssetName;
            public long TimeMs;
            public long ToTimeMs;
            public long FrameCount;
            public long ToFrameCount;
            public List<AssetCacheInfo> OriginAssetCacheInfos;
            public List<AssetCacheInfo> ToAssetCacheInfos;
            public List<SpriteRefInfo> OriginSpriteRefInfos;
            public List<SpriteRefInfo> ToSpriteRefInfos;
            public List<BundleCacheInfo> OriginBundleCacheInfos;
            public List<BundleCacheInfo> ToBundleCacheInfos;
            
            public UIRecordUIPair(UIRecord beforeOpen, UIRecord afterClosed) : this()
            {
                RuntimeId = beforeOpen.RuntimeId;
                UiMediatorName = beforeOpen.UiMediatorName;
                UiPrefabAssetName = beforeOpen.UiPrefabAssetName;
                TimeMs = beforeOpen.TimeMs;
                ToTimeMs = afterClosed.TimeMs;
                FrameCount = beforeOpen.FrameCount;
                ToFrameCount = afterClosed.FrameCount;
                OriginAssetCacheInfos = new List<AssetCacheInfo>(beforeOpen.AssetCacheInfos);
                ToAssetCacheInfos = new List<AssetCacheInfo>(afterClosed.AssetCacheInfos);
                OriginSpriteRefInfos = new List<SpriteRefInfo>(beforeOpen.SpriteRefInfos);
                ToSpriteRefInfos = new List<SpriteRefInfo>(afterClosed.SpriteRefInfos);
                OriginBundleCacheInfos = new List<BundleCacheInfo>(beforeOpen.BundleCacheInfos);
                ToBundleCacheInfos = new List<BundleCacheInfo>(afterClosed.BundleCacheInfos);
                var info = OriginAssetCacheInfos;
                var info1 = ToAssetCacheInfos;
                var info2 = OriginSpriteRefInfos;
                var info3 = ToSpriteRefInfos;
                var info4 = OriginBundleCacheInfos;
                var info5 = ToBundleCacheInfos;
                Parallel.Invoke(
                    ()=>info.Sort((a, b) => string.CompareOrdinal(a.AssetName, b.AssetName)),
                    ()=>info1.Sort((a, b) => string.CompareOrdinal(a.AssetName, b.AssetName)),
                    ()=>info2.Sort((a, b) => string.CompareOrdinal(a.SpriteName, b.SpriteName)),
                    ()=>info3.Sort((a, b) => string.CompareOrdinal(a.SpriteName, b.SpriteName)),
                    ()=>info4.Sort((a, b) => string.CompareOrdinal(a.BundleName, b.BundleName)),
                    ()=>info5.Sort((a, b) => string.CompareOrdinal(a.BundleName, b.BundleName)));
            }
        }
#endif

        private void ThreadWork()
        {
            while (Interlocked.Read(ref _threadRunningFlag) == 1)
            {
                _autoResetEvent.WaitOne();
                _lastWriteTask?.Wait();
                _changeLogStream?.Flush();
                _lastWriteTask?.Dispose();
                _lastWriteTask = null;
                lock (_tempCacheLocker)
                {
                    var startRecord = Interlocked.Exchange(ref _threadProcessRecord, null);
                    if (startRecord == null) continue;
#if ENABLE_UI_LIFE_CIRCLE_ASSET_REF_PROFILER_DETAIL
                    _lastDetailWriteTask?.Wait();
                    _lastDetailWriteTask?.Dispose();
                    _lastDetailWriteTask = null;
                    var detailFilePath = Path.Combine(_logFileFolder, $"detail_{DateTime.Now:yyyy_MM_dd_HH-mm-ss}_{startRecord.RuntimeId}_{startRecord.UiMediatorName}.log");
                    var detailContent = JsonUtility.ToJson(new UIRecordUIPair(startRecord, _tempCacheB), true);
                    _lastDetailWriteTask = File.WriteAllTextAsync(detailFilePath, detailContent, Encoding.UTF8);
#endif
                    startRecord.GetDiff(_writeDiff, _tempCacheB);
                }
                if (_writeDiff.NoChange())
                {
                    _lastWriteTask = _changeLogStream?.WriteLineAsync($"UI:[{_writeDiff.RuntimeId}]{_writeDiff.UiMediatorName}:{_writeDiff.UiPrefabAssetName} [{_writeDiff.FrameCount}]{_writeDiff.TimeMs}-[{_writeDiff.ToFrameCount}]{_writeDiff.ToTimeMs} No Change");
                    continue;
                }
                var json = JsonUtility.ToJson(_writeDiff, true);
                _writeDiff.Clear();
                _lastWriteTask = _changeLogStream?.WriteLineAsync(json);
            }
            _lastWriteTask?.Wait();
            _changeLogStream?.Flush();
            _lastWriteTask?.Dispose();
            _lastWriteTask = null;
#if ENABLE_UI_LIFE_CIRCLE_ASSET_REF_PROFILER_DETAIL
            _lastDetailWriteTask?.Wait();
            _lastDetailWriteTask?.Dispose();
            _lastDetailWriteTask = null;
#endif
        }
        
        private class UILifeCircleEventReceiverUnityLife : MonoBehaviour
        {
            private Action _onQuit;
            private Action _lateUpdateAction;
            private bool _willQuit;
            
            public static void Create(Action onQuit, Action lateUpdateAction){
                var go = new GameObject(nameof(UILifeCircleEventReceiverUnityLife));
                var com = go.AddComponent<UILifeCircleEventReceiverUnityLife>();
                com._onQuit = onQuit;
                com._lateUpdateAction = lateUpdateAction;
                DontDestroyOnLoad(go);
                go.layer = LayerMask.NameToLayer("Ignore Raycast");
#if UNITY_EDITOR
                go.hideFlags = HideFlags.NotEditable;
#endif
            }
            
            private void LateUpdate()
            {
                _lateUpdateAction?.Invoke();
            }
            
            
            private void OnDestroy()
            {
                if (!_willQuit) return;
                _willQuit = true;
                _onQuit?.Invoke();
                _onQuit = null;
            }
            
            private void OnApplicationQuit()
            {
                _willQuit = true;
            }
        }
    }
}