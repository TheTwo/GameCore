using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using UnityEditor;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public class LuaBehaviourFileWatcher : ScriptableSingleton<LuaBehaviourFileWatcher>
    {
        private FileSystemWatcher _watcher;
        private event FileSystemEventHandler OnCreate;
        private event RenamedEventHandler OnRename;
        private event FileSystemEventHandler OnDelete;
        private event FileSystemEventHandler OnChanged;

        private readonly Dictionary<string, string> _luaNameToFullPath = new(StringComparer.Ordinal);

        private int _userCount;

        private void EnsureFileWatcher()
        {
            if (null != _watcher) return;
            var (root, ext) = LuaBehaviourEditorUtils.GetCurrentRootPath();
            var pattern = "*" + ext;
            _watcher = new FileSystemWatcher(root, pattern)
            {
                NotifyFilter = NotifyFilters.CreationTime
                               | NotifyFilters.DirectoryName
                               | NotifyFilters.FileName
                               | NotifyFilters.LastWrite
                               | NotifyFilters.Size
            };

            _watcher.Created += OnCreatedCall;
            _watcher.Changed += OnChangedCall;
            _watcher.Deleted += OnDeletedCall;
            _watcher.Renamed += OnRenamedCall;
            _watcher.IncludeSubdirectories = true;
            BuildFullPathCache(root, pattern);
            _watcher.EnableRaisingEvents = true;
        }

        private static void SendToThreadCall(object obj)
        {
            switch (obj)
            {
                case Tuple<FileSystemEventHandler, object, FileSystemEventArgs> call:
                    call.Item1(call.Item2, call.Item3);
                    break;
                case Tuple<RenamedEventHandler, object, RenamedEventArgs> call:
                    call.Item1(call.Item2, call.Item3);
                    break;
            }
        }

        private void OnCreatedCall(object sender, FileSystemEventArgs e)
        {
            if (_userCount <= 0 || null == OnCreate) return;
            SynchronizationContext.Current.Send(SendToThreadCall, Tuple.Create((OnCreate, sender, e)));
        }
        
        private void OnRenamedCall(object sender, RenamedEventArgs e)
        {
            if (_userCount <= 0 || null == OnRename) return;
            SynchronizationContext.Current.Send(SendToThreadCall, Tuple.Create((OnRename, sender, e)));
        }

        private void OnDeletedCall(object sender, FileSystemEventArgs e)
        {
            if (_userCount <= 0 || null == OnDelete)return;
            SynchronizationContext.Current.Send(SendToThreadCall, Tuple.Create((OnDelete, sender, e)));
        }

        private void OnChangedCall(object sender, FileSystemEventArgs e)
        {
            if (_userCount <= 0 || null == OnChanged) return;
            SynchronizationContext.Current.Send(SendToThreadCall, Tuple.Create((OnChanged, sender, e)));
        }

        public void AddRef()
        {
            ++_userCount;
        }

        public void RemoveRef()
        {
            --_userCount;
        }

        private void OnDestroy()
        {
            _watcher?.Dispose();
            _watcher = null;
            _userCount = 0;
        }

        public bool GetFileFullPath(string luaName, out string fullPath)
        {
            return _luaNameToFullPath.TryGetValue(luaName, out fullPath);
        }

        private void BuildFullPathCache(string rootDir, string pattern)
        {
            _luaNameToFullPath.Clear();
            foreach (var fullPath in Directory.EnumerateFiles(rootDir, pattern, SearchOption.AllDirectories))
            {
                var fileName = Path.GetFileNameWithoutExtension(fullPath);
                _luaNameToFullPath[fileName] = fullPath;
            }
        }

        public IDisposable RegisterEvent(FileSystemEventHandler onCreate, RenamedEventHandler onRename, FileSystemEventHandler onDelete, FileSystemEventHandler onChanged)
        {
            EnsureFileWatcher();
            return new Register(this, onCreate, onRename, onDelete, onChanged);
        }

        private class Register : IDisposable
        {
            private FileSystemEventHandler _onCreate;
            private RenamedEventHandler _onRename;
            private FileSystemEventHandler _onDelete;
            private FileSystemEventHandler _onChanged;
            private LuaBehaviourFileWatcher _watcher;
            private bool _eventRegister;

            public Register(LuaBehaviourFileWatcher watcher, FileSystemEventHandler onCreate, RenamedEventHandler onRename, FileSystemEventHandler onDelete, FileSystemEventHandler onChanged)
            {
                _onCreate = onCreate;
                _onRename = onRename;
                _onDelete = onDelete;
                _onChanged = onChanged;
                watcher.OnCreate += onCreate;
                watcher.OnRename += onRename;
                watcher.OnDelete += onDelete;
                watcher.OnChanged += onChanged;
                _watcher = watcher;
                _watcher.AddRef();
                _eventRegister = true;
            }

            void IDisposable.Dispose()
            {
                if (!_eventRegister) return;
                _eventRegister = false;
                if (!_watcher) return;
                _watcher.RemoveRef();
                _watcher.OnCreate -= _onCreate;
                _watcher.OnRename -= _onRename;
                _watcher.OnDelete -= _onDelete;
                _watcher.OnChanged -= _onChanged;
                _onCreate = null;
                _onRename = null;
                _onDelete = null;
                _onChanged = null;
                _watcher = null;
            }
        }
    }
}