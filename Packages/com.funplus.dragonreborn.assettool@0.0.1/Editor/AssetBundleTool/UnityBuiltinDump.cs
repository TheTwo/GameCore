using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public class UnityBuiltinDumpWindow : EditorWindow
	{
		private bool _isBusy;
		private readonly GUIContent _dragText = new("拖拽Bundle文件到此");
		private readonly GUIContent _dragBinText = new("拖拽Unity序列化二进制文件到此");
		private GUIStyle _dropBoxSelected;
		private readonly List<string> _selectedFiles = new();
		private readonly HashSet<string> _selectedFilesSet = new();
		private Vector2 _scollViewPos;
		private ExHandle _exHandle;
		private bool _bin2TextMode;
		private bool _shaderToolMode;
		private Action<IReadOnlyList<(bool, string)>> _shaderToolCallback;

		[MenuItem("DragonReborn/资源工具箱/出包工具/UnityDump")]
		private static void ShowWindow()
		{
			var window = GetWindow<UnityBuiltinDumpWindow>(true);
			window.titleContent = new GUIContent("dump 文件");
			window.Show();
		}

		private void Awake()
		{
			_dropBoxSelected = new(EditorStyles.helpBox)
			{
				alignment = TextAnchor.MiddleCenter
			};
		}
		
		private void OnDestroy()
		{
			_exHandle?.Dispose();
			_exHandle = null;
		}

		public UnityBuiltinDumpWindow SetShaderProcessMode(Action<IReadOnlyList<(bool, string)>> callback)
		{
			_bin2TextMode = false;
			_selectedFiles.Clear();
			_selectedFilesSet.Clear();
			_shaderToolCallback = callback;
			_shaderToolMode = true;
			return this;
		}

		private void OnGUI()
		{
			EditorGUI.BeginDisabledGroup(_isBusy);
			var rect = GUILayoutUtility.GetRect(_bin2TextMode ? _dragBinText : _dragText, _dropBoxSelected, GUILayout.ExpandHeight(true),
				GUILayout.ExpandWidth(true));
			ExampleDragDropGUI(rect);
			EditorGUI.BeginDisabledGroup(_selectedFiles.Count <= 0);
			DrawFileList();
			EditorGUI.EndDisabledGroup();
			GUILayout.BeginHorizontal();
			GUILayout.FlexibleSpace();
			if (!_shaderToolMode)
			{
				var lastBin2TextMode = _bin2TextMode;
				_bin2TextMode = GUILayout.Toggle(_bin2TextMode, "仅解析bin2txt");
				if (lastBin2TextMode != _bin2TextMode)
				{
					_selectedFiles.Clear();
					_selectedFilesSet.Clear();
				}
			}
			EditorGUI.BeginDisabledGroup(_selectedFiles.Count <= 0);
			if (GUILayout.Button("清空"))
			{
				_selectedFiles.Clear();
				_selectedFilesSet.Clear();
			}
			if (GUILayout.Button("dump"))
			{
				_exHandle?.Dispose();
				_exHandle = DoEx(_shaderToolCallback);
			}
			GUILayout.EndHorizontal();
			EditorGUI.EndDisabledGroup();
			EditorGUI.EndDisabledGroup();
		}
		
		private void ExampleDragDropGUI(Rect dropArea)
		{
			var currentEvent = Event.current;
			var currentEventType = currentEvent.type;
			switch (currentEventType)
			{
				case EventType.DragUpdated:
					if (CheckAndAccept(DragAndDrop.paths, true))
					{
						DragAndDrop.AcceptDrag();
						DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
					}
					else
					{
						DragAndDrop.visualMode = DragAndDropVisualMode.Rejected;
					}
					currentEvent.Use();
					break;
				case EventType.Repaint when DragAndDrop.visualMode is not (DragAndDropVisualMode.None or DragAndDropVisualMode.Rejected):
					EditorGUI.DrawRect(dropArea, Color.grey);
					break;
				case EventType.DragPerform:
					if (CheckAndAccept(DragAndDrop.paths, true))
					{
						DragAndDrop.AcceptDrag();
						DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
					}
					else
					{
						DragAndDrop.visualMode = DragAndDropVisualMode.Rejected;
					}
					currentEvent.Use();
					break;
				case EventType.DragExited:
					DragAndDrop.visualMode = DragAndDropVisualMode.None;
					CheckAndAccept(DragAndDrop.paths, false);
					currentEvent.Use();
					break;
			}
			GUI.Box(dropArea, _bin2TextMode ? _dragBinText : _dragText, _dropBoxSelected);
		}
		
		private bool CheckAndAccept(string[] paths, bool noAdd)
		{
			var accepted = false;
			foreach (var path in paths)
			{
				var ext = Path.GetExtension(path);
				if (!_bin2TextMode)
				{
					if (!ext.Equals(".ab")) continue;
				}
				if (!noAdd)
				{
					if (_selectedFilesSet.Add(path))
					{
						_selectedFiles.Add(path);
					}
				}
				accepted = true;
			}
			return accepted;
		}
		
		private void DrawFileList()
		{
			var delayRemIdx = -1;
			GUILayout.BeginVertical();
			_scollViewPos = GUILayout.BeginScrollView(_scollViewPos, GUILayout.ExpandHeight(false));
			for (var i = 0; i < _selectedFiles.Count; i++)
			{
				GUILayout.BeginHorizontal();
				var file = _selectedFiles[i];
				if (GUILayout.Button("-", GUILayout.ExpandWidth(false)))
				{
					delayRemIdx = i;
				}
				EditorGUI.BeginDisabledGroup(true);
				GUILayout.TextField(file, GUILayout.ExpandWidth(true));
				EditorGUI.EndDisabledGroup();
				GUILayout.EndHorizontal();
			}
			GUILayout.EndScrollView();
			GUILayout.EndVertical();
			if (delayRemIdx < 0 || delayRemIdx >= _selectedFiles.Count) return;
			var f = _selectedFiles[delayRemIdx];
			_selectedFiles.RemoveAt(delayRemIdx);
			_selectedFilesSet.Remove(f);
		}
		
		private ExHandle DoEx(Action<IReadOnlyList<(bool, string)>> callback)
		{
			var ret =  new ExHandle(this, _selectedFiles);
			if (_bin2TextMode)
			{
				ret.StartBin2TxtMode();
			}
			else
			{
				ret.Start(callback);
			}
			return ret;
		}

		public static void DoExForExternal(string file, Action<IDisposable,IReadOnlyList<(bool, string)>> callback)
		{
			var ret =  new ExHandle(null, new []{file});
			ret.Start(action =>
			{
				callback(ret, action);
			});
		}

		private class ExHandle : IDisposable
		{
			private UnityBuiltinDumpWindow _host;
			private CancellationTokenSource _cancellation = new();
			private readonly string[] _srcFiles;

			public ExHandle(UnityBuiltinDumpWindow host, IEnumerable<string> inputFiles)
			{
				_host = host;
				_srcFiles = inputFiles.ToArray();
			}
			
			public async void Start(Action<IReadOnlyList<(bool, string)>> callback)
			{
				do
				{
					var extractResult = await WebExtract(_cancellation.Token, _srcFiles);
					var ret = await Binary2Text(_cancellation.Token, extractResult);
					callback?.Invoke(ret);
				} while (false);
				Dispose();
			}

			public async void StartBin2TxtMode()
			{
				await Task.Run(() =>
				{
					Parallel.ForEach(_srcFiles, file =>
					{
						Binary2Text(file, _cancellation.Token);
					});
				});
				Dispose();
			}

			private static async Task<IReadOnlyList<(bool, string)>> WebExtract(CancellationToken token, IReadOnlyList<string> files)
			{
				return await Task.Run(() =>
				{
					do
					{
						if (token.IsCancellationRequested) break;
						var ret = new (bool, string)[files.Count];
						Parallel.For(0, files.Count, i =>
                        {
	                        
                            var file = files[i];
                            var folderPath = file + "_data";
                            if (Directory.Exists(folderPath))
                            {
	                            Directory.Delete(folderPath, true);
                            }
                            using var p = new Process();
                            var ps = p.StartInfo;
                            ps.FileName = GetWebExtractCmd();
                            ps.ArgumentList.Add(file);
                            ps.UseShellExecute = false;
                            ps.RedirectStandardError = true;
                            ps.RedirectStandardOutput = true;
                            ps.CreateNoWindow = true;
                            ps.UseShellExecute = false;
                            p.Start();
                            var isExit = false;
                            token.Register(work =>
                            {
	                            // ReSharper disable once AccessToModifiedClosure
	                            if (isExit) return;
	                            if (work is Process { HasExited: false } pWork)
	                            {
		                            pWork.Kill();
	                            }
                            }, p);
                            p.WaitForExit();
                            isExit = true;
                            ret[i] = (p.ExitCode == 0, folderPath);
                        });
						return ret;
					} while (false);
					return Array.Empty<(bool, string)>();
				}, token);
			}
			
			private static async Task<IReadOnlyList<(bool, string)>> Binary2Text(CancellationToken token, IReadOnlyList<(bool, string)> filesFolders)
			{
				return await Task.Run(() =>
				{
					do
					{
						if (token.IsCancellationRequested) break;
						var ret = new (bool, string)[filesFolders.Count];
						Parallel.For(0, filesFolders.Count, i =>
                        {
                            var (isSuccess, folder) = filesFolders[i];
                            if (!isSuccess)
                            {
	                            ret[i] = (false, folder);
	                            return;
                            }
                            var files = Directory.GetFiles(folder, "CAB-*", SearchOption.TopDirectoryOnly);
                            if (files.Length <= 0)
                            {
	                            ret[i] = (false, folder);
	                            return;
                            }
                            foreach (var file in files)
                            {
	                            Binary2Text(file, token);
                            }
                            ret[i] = (true, folder);
                        });
						return ret;
					} while (false);
					return Array.Empty<(bool, string)>();
				}, token);
			}

			public static void Binary2Text(string file, CancellationToken token)
			{
				using var p = new Process();
				var ps = p.StartInfo;
				ps.FileName = GetBinary2TextCmd();
				ps.ArgumentList.Add(file);
				ps.ArgumentList.Add("-detailed");
				// ps.ArgumentList.Add("-largebinaryhashonly");
				ps.UseShellExecute = false;
				ps.RedirectStandardError = true;
				ps.RedirectStandardOutput = true;
				ps.CreateNoWindow = true;
				ps.UseShellExecute = false;
				p.Start();
				var isExit = false;
				token.Register(work =>
				{
					// ReSharper disable once AccessToModifiedClosure
					if (isExit) return;
					if (work is Process { HasExited: false } pWork)
					{
						pWork.Kill();
					}
				}, p);
				p.WaitForExit();
				isExit = true;
			}

			private static string GetWebExtractCmd()
			{
#if UNITY_EDITOR_WIN
				return Path.Combine(EditorApplication.applicationContentsPath, "Tools/WebExtract.exe");
#elif UNITY_EDITOR_OSX
				return Path.Combine(EditorApplication.applicationContentsPath, "Tools/WebExtract");
#else
				return string.Empty;
#endif
			}

			private static string GetBinary2TextCmd()
			{
#if UNITY_EDITOR_WIN
				return Path.Combine(EditorApplication.applicationContentsPath, "Tools/binary2text.exe");
#elif UNITY_EDITOR_OSX
				return Path.Combine(EditorApplication.applicationContentsPath, "Tools/binary2text");
#else
				return string.Empty;
#endif
			}

			public void Abort()
			{
				if (null == _cancellation) return;
				var c = _cancellation;
				_cancellation = null;
				c.Cancel();
			}
			
			public void Dispose()
			{
				Abort();
				if (null == _host) return;
				var host = _host;
				_host = null;
				if (host._exHandle != this) return;
				host._exHandle = null;
				host._isBusy = false;
				host._selectedFiles.Clear();
				host._selectedFilesSet.Clear();
			}
		}
	}
}
