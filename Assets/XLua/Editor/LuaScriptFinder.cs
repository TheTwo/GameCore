using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using DragonReborn.CSharpReflectionTool;
using DragonReborn.UI;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEditor.SceneManagement;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public sealed class LuaScriptFinder : EditorWindow
	{

		private class LuaTreeViewItem : TreeViewItem
		{
			public string Path;
			public bool IsScene;
			public bool IsPrefab;
		}

		private class LuaNodeTreeViewItem : TreeViewItem
		{
			public LuaRefRecord Record;
		}
		
		private class LuaTreeView : TreeView
		{
			private LuaTreeViewItem _root;
			//图标宽度
			// ReSharper disable InconsistentNaming
			private const float kIconWidth = 18f;
			//列表高度
			private const float kRowHeights = 20f;
			// ReSharper restore InconsistentNaming

			public LuaTreeView(TreeViewState state, MultiColumnHeader multiColumnHeader) : base(state, multiColumnHeader)
			{
				rowHeight = kRowHeights;
				columnIndexForTreeFoldouts = 0;
				showAlternatingRowBackgrounds = true;
				showBorder = false;
				customFoldoutYOffset = (kRowHeights - EditorGUIUtility.singleLineHeight) * 0.5f; // center foldout in the row since we also center content. See RowGUI
				extraSpaceBeforeIconAndLabel = kIconWidth;
			}

			public bool IsRootNull()
			{
				return null == _root;
			}

			public void SetRoot(LuaTreeViewItem root)
			{
				_root = root;
			}

			protected override TreeViewItem BuildRoot()
			{
				return _root;
			}

			protected override void ContextClickedItem(int id)
			{
				SetExpanded(id, !IsExpanded(id));
			}
			
			protected override void SingleClickedItem(int id)
			{
				OnSelectItem(id, true, false);
			}

			protected override void DoubleClickedItem(int id)
			{
				OnSelectItem(id, true, true);
			}

			private void OnSelectItem(int id, bool ping, bool open)
			{
				var node = FindItem(id, rootItem);
				switch (node)
				{
					case LuaTreeViewItem item:
					{
						var assetObject = AssetDatabase.LoadAssetAtPath(item.Path, typeof(UnityEngine.Object));
						if (ping)
						{
							EditorUtility.FocusProjectWindow();
							EditorGUIUtility.PingObject(assetObject);
						}
						if (open)
						{
							if (item.IsPrefab)
							{
								PrefabStageUtility.OpenPrefab(item.Path);
							}
							else if(item.IsScene)
							{
								EditorSceneManager.OpenScene(item.Path);
							}
						}
						break;
					}
					case LuaNodeTreeViewItem nodeItem:
					{
						var record = nodeItem.Record;
						var assetObject = AssetDatabase.LoadAssetAtPath(record.Parent.Path, typeof(UnityEngine.Object));
						if (ping)
						{
							EditorUtility.FocusProjectWindow();
							EditorGUIUtility.PingObject(assetObject);
						}
						if (open)
						{
							if (!record.Parent.IsScene)
							{
								PrefabStageUtility.OpenPrefab(record.Parent.Path);
							}
							else
							{
								EditorSceneManager.OpenScene(record.Parent.Path);
							}
						}

						break;
					}
				}
			}

			protected override void RowGUI(RowGUIArgs args)
			{
				var item = args.item;
				for(int i = 0; i < args.GetNumVisibleColumns(); ++i)
				{
					CellGUI(args.GetCellRect(i), item, args.GetColumn(i), ref args);
				}
			}
			
			private void CellGUI(Rect cellRect, TreeViewItem item, int column, ref RowGUIArgs args)
			{
				CenterRectUsingSingleLineHeight(ref cellRect);
				switch (column)
				{
					case 0:
					{
						var iconRect = cellRect;
						iconRect.x += GetContentIndent(item);
						iconRect.width = kIconWidth;
						args.rowRect = cellRect;
						base.RowGUI(args);
					}
						break;
					case 1:
					{
						switch (item)
						{
							case LuaTreeViewItem luaTreeViewItem:
								GUI.Label(cellRect, luaTreeViewItem.Path);
								break;
							case LuaNodeTreeViewItem nodeTreeViewItem:
								GUI.Label(cellRect, nodeTreeViewItem.Record.lines);
								break;
						}
					}
						break;
				}
			}

			public static MultiColumnHeaderState CreateDefaultMultiColumnHeaderState()
			{
				var columns = new[]
				{
					//图标+名称
					new MultiColumnHeaderState.Column
					{
						headerContent = new GUIContent("Name"),
						headerTextAlignment = TextAlignment.Center,
						sortedAscending = false,
						width = 200,
						minWidth = 60,
						autoResize = false,
						allowToggleVisibility = false,
						canSort = false
					},
					//路径
					new MultiColumnHeaderState.Column
					{
						headerContent = new GUIContent("Path"),
						headerTextAlignment = TextAlignment.Center,
						sortedAscending = false,
						width = 360,
						minWidth = 60,
						autoResize = false,
						allowToggleVisibility = false,
						canSort = false
					},
				};
				return new MultiColumnHeaderState(columns);
			}
		}

		private sealed class LuaRefRecord
		{
			// ReSharper disable InconsistentNaming
			public string scriptName = string.Empty;
			public string scriptNameLower = string.Empty;
			public string lines = string.Empty;
			public LuaRef Parent;
			// ReSharper restore InconsistentNaming
		}
		
		private sealed class LuaRef
		{
			public string Path;
			public bool IsScene;
			public readonly List<LuaRefRecord> Records = new();
		}
		
		private static bool _initializedData;
		private static readonly Dictionary<string, List<LuaRef>> LuaScriptNameLowerInPath = new();
		private static readonly Dictionary<string, LuaRef> LuaAssetNameLowerInPath = new();

		private static InitDataTask _initDataTask;
		
		private readonly List<LuaRef> _tableData = new();

		private string _target = string.Empty;
		private string _targetLower = string.Empty;
		private string _lastTarget = string.Empty;
		private bool _matchName = false;
		private bool _initializedGUIStyle;
		private GUIStyle _toolbarGUIStyle;
		
		private LuaTreeView _assetTreeView;
		
		[SerializeField]
		private TreeViewState treeViewState;

		// ReSharper disable InconsistentNaming
		private static readonly Type LuaBehaviourType = typeof(LuaBehaviour);
		private static readonly Type ILuaComponentType = typeof(ILuaComponent);
		// ReSharper restore InconsistentNaming

		private GUIState _currentOnGuiState;
		
		private enum GUIState
		{
			NotInit,
			UpdateRefCaching,
			Normal,
		}

		private static string[] GetMatchProperties(Type type)
		{
			switch (type)
			{
				case not null when LuaBehaviourType.IsAssignableFrom(type):
                    return new[] {"scriptName", "schemaName"};
				default:
					throw new NotImplementedException($"Not support type {type}");
			}
		}

		private class InitDataTask
		{
			public List<string> NeedCheckPaths;
			public List<Tuple<Regex, string[]>> CheckRegex;
			public ConcurrentDictionary<string, ConcurrentDictionary<string, List<int>>> FindResult;

			private WorkState _state;
			private readonly CancellationTokenSource _cancellation = new();
			private CancellationToken _cancellationToken;
			private string _currentFileName;
			private long _currentCount;
			private long _totalCount;
			private string _progressTitle;
			private float _baseProgress;
			private Thread _worker;
			
			private enum WorkState
            {
                NotStart,
                Running,
                Finished,
                Aborted,
                Idle,
            }

			public void Start()
			{
				_cancellationToken = _cancellation.Token;
				_totalCount = NeedCheckPaths.Count;
				_baseProgress = 0f;
				_currentCount = 0;
				EditorUtility.ClearProgressBar();
				_state = WorkState.Running;
				Interlocked.Exchange(ref _progressTitle, "检查文件");
				EditorApplication.update += DoProgressBar;
				_worker = new Thread(ThreadTask);
				_worker.Start();
			}

			private void DoProgressBar()
			{
				if (EditorUtility.DisplayCancelableProgressBar(_progressTitle, _currentFileName,
					    (_totalCount > 0 ? (Interlocked.Read(ref _currentCount) * 1f / _totalCount) : 0) * 0.5f + _baseProgress))
				{
					Abort();
				}
			}

			public GUIState OnGui()
			{
				if (Event.current.type == EventType.Repaint)
				{
					switch (_state)
					{
						case WorkState.Idle:
						case WorkState.NotStart:
						case WorkState.Running:
							break;
						case WorkState.Finished:
							EditorApplication.update -= DoProgressBar;
							EditorUtility.ClearProgressBar();
							_initializedData = true;
							_state = WorkState.Idle;
							return GUIState.Normal;
						case WorkState.Aborted:
							EditorApplication.update -= DoProgressBar;
							EditorUtility.ClearProgressBar();
							_initializedData = false;
							return GUIState.NotInit;
					}
				}
				return GUIState.UpdateRefCaching;
			}

			public void Abort()
			{
				_cancellation.Cancel();
				_worker?.Join();
				_worker = null;
				_state = WorkState.Aborted;
				EditorApplication.update -= DoProgressBar;
				EditorUtility.ClearProgressBar();
			}

			private void ThreadTask()
			{
				Parallel.ForEach(NeedCheckPaths, new ParallelOptions()
				{
					CancellationToken = _cancellationToken,
				} , DoSearch);
				_baseProgress = 0.5f;
				PostEndThreadTask();
				_state = _cancellationToken.IsCancellationRequested ? WorkState.Aborted : WorkState.Finished;
			}

			private void PostEndThreadTask()
			{
				Interlocked.Exchange(ref _progressTitle, "整理引用");
				LuaScriptNameLowerInPath.Clear();
				LuaAssetNameLowerInPath.Clear();
				_totalCount = FindResult.Count;
				_currentCount = 0;
				foreach (var (scriptName, refMap) in FindResult)
				{
					if (_cancellationToken.IsCancellationRequested) return;
					Interlocked.Exchange(ref _currentFileName, scriptName);
					var lowerName = scriptName.ToLower();
					if (!LuaScriptNameLowerInPath.TryGetValue(lowerName, out var l))
					{
						l = new List<LuaRef>();
						LuaScriptNameLowerInPath.Add(lowerName, l);
					}
					foreach (var (assetPath, lines) in refMap)
					{
						if (_cancellationToken.IsCancellationRequested) return;
						var assetPathLowerName = assetPath.ToLower();
						if (!LuaAssetNameLowerInPath.TryGetValue(assetPathLowerName, out var luaRef))
						{
							luaRef = new LuaRef()
							{
								IsScene = assetPath.EndsWith(".unity"),
								Path = assetPath,
							};
							LuaAssetNameLowerInPath.Add(assetPathLowerName, luaRef);
						}
						luaRef.Records.Add(new LuaRefRecord()
						{
                            scriptName = scriptName,
                            scriptNameLower = lowerName,
                            lines = string.Join(',', lines),
                            Parent = luaRef,
                        });
						l.Add(luaRef);
					}
					Interlocked.Increment(ref _currentCount);
				}
			}

			private void DoSearch(string assetPath)
			{
				Interlocked.Exchange(ref _currentFileName, assetPath);
				var assetFullPath = Path.GetFullPath(assetPath);
				var content = File.ReadAllLines(assetFullPath);
				foreach (var tuple in CheckRegex)
				{
					if (_cancellationToken.IsCancellationRequested) return;
					MatchRegexAndSearch(content, tuple.Item1, tuple.Item2, FindResult, assetPath);
				}
				Interlocked.Increment(ref _currentCount);
			}

			private void MatchRegexAndSearch(IReadOnlyList<string> allContext, Regex regex, IReadOnlyList<string> matchPropertiesName, ConcurrentDictionary<string, ConcurrentDictionary<string, List<int>>> toAddDic, string assetPath)
			{
				if (_cancellationToken.IsCancellationRequested) return;
				if (matchPropertiesName.Count <= 0) return;
				for (var index = 0; index < allContext.Count;)
				{
					if (_cancellationToken.IsCancellationRequested) return;
					var line = allContext[index];
					if (!line.StartsWith("MonoBehaviour:"))
					{
						++index;
						continue;
					}
					var blockStart = index + 1;
					var blockEnd = blockStart;
					var matchScript = false;
					var matchLinePos = blockStart;
					var preFix = string.Empty;
					for (; blockEnd < allContext.Count;)
					{
						if (_cancellationToken.IsCancellationRequested) return;
						line = allContext[blockEnd];
						if (!matchScript)
						{
							var match = regex.Match(line);
							if (match.Success)
							{
								matchScript = true;
								preFix = match.Groups[1].Value;
								matchLinePos = blockEnd;
							}
						}
						if (string.IsNullOrWhiteSpace(line)) break;
						if (!char.IsWhiteSpace(line[0])) break;
						++blockEnd;
					}
					index = blockEnd;
					if (!matchScript)
					{
						continue;
					}
					var pLength = preFix.Length;
					foreach (var propertyName in matchPropertiesName)
					{
						if (_cancellationToken.IsCancellationRequested) return;
						if (SearchProperty(allContext, matchLinePos, blockStart, blockEnd, propertyName, pLength, 1,
							    out var findScriptName, out var atLineDown))
						{
							toAddDic.GetOrAdd(findScriptName, _ => new ConcurrentDictionary<string, List<int>>())
								.AddOrUpdate(assetPath, _ => new List<int> { atLineDown }, (_, list) =>
								{
									list.Add(atLineDown);
									return list;
								});
						}
						if (SearchProperty(allContext, matchLinePos, blockStart, blockEnd, propertyName, pLength, -1,
							    out findScriptName, out var atLineUp))
						{
							toAddDic.GetOrAdd(findScriptName, _ => new ConcurrentDictionary<string, List<int>>())
								.AddOrUpdate(assetPath, _ => new List<int> { atLineUp }, (_, list) =>
								{
									list.Add(atLineUp);
									return list;
								});
						}
					}
				}
				
				static bool SearchProperty(IReadOnlyList<string> allContext, int startIndex, int min, int max, ReadOnlySpan<char> propertyName, int preFixLength, int step, out string scriptName, out int findLine)
				{
					scriptName = default;
					var idx = startIndex + step;
					var limitLength = preFixLength + propertyName.Length + 2;
					while (idx >= min && idx < max)
					{
						var line = allContext[idx].AsSpan();
						if (line.Length > limitLength)
						{
							var sub = line[preFixLength..];
							if (sub.StartsWith(propertyName))
							{
								sub = sub[(propertyName.Length + 2)..];
								if (!sub.IsEmpty && !sub.IsWhiteSpace())
								{
									scriptName = sub.ToString();
									findLine = idx;
									return true;
								}
							}
						}
						idx += step;
					}
					findLine = default;
					return false;
				}
			}
		}

		private static void InitData()
		{
			EditorUtility.ClearProgressBar();
			_initDataTask?.Abort();
			_initDataTask = null;
			var targetGuids = new HashSet<string>();
			var checkTypes = new HashSet<Type>
			{
				LuaBehaviourType,
				typeof(ILuaComponent)
			};
			checkTypes.UnionWith(TypeCache.GetTypesDerivedFrom(LuaBehaviourType));
			checkTypes.UnionWith(TypeCache.GetTypesDerivedFrom(ILuaComponentType));
			var queryResult = CsTypeInUnityIdentifierGetter.QueryInCurrentBuildRuntime(checkTypes);
			if (queryResult.Count <= 0) return;
			var checkRegex = new List<Tuple<Regex, string[]>>();
			foreach (var item in queryResult)
            {
                if (!item.IsFound) continue;
                targetGuids.Add(item.Guid.ToString());
                checkRegex.Add(Tuple.Create(new Regex(@"^(\s+)m_Script: {fileID: " + $"{item.FileId}, guid: {item.Guid.ToString()}, type: 3" + "}", RegexOptions.Compiled), GetMatchProperties(item.Type)));
            }
			var allGuids = AssetDatabase.FindAssets("t:prefab t:scene", new[] { "Assets" });
			var checkedPaths = new HashSet<string>();
			var needCheckPaths = (from guid in allGuids select AssetDatabase.GUIDToAssetPath(guid) into path where checkedPaths.Add(path) let dependencies = AssetDatabase.GetDependencies(path, false).Select(AssetDatabase.AssetPathToGUID).ToList() where targetGuids.Overlaps(dependencies) select path).ToList();
			if (needCheckPaths.Count <= 0) return;
			EditorUtility.DisplayProgressBar("InitData", "初始化需要收集的资源路径列表", 0.01f);
			_initDataTask = new InitDataTask();
			var findResult = new ConcurrentDictionary<string, ConcurrentDictionary<string, List<int>>>();
			_initDataTask.NeedCheckPaths = needCheckPaths;
			_initDataTask.CheckRegex = checkRegex;
			_initDataTask.FindResult = findResult;
			_initDataTask.Start();
		}

		[MenuItem("DragonReborn/资源工具箱/脚本工具/Lua脚本引用查找")]
		private static void OpenWindow()
		{
			var window = GetWindow<LuaScriptFinder>();
			window.minSize = new Vector2(560, 400);
			window.wantsMouseMove = false;
			window.wantsMouseEnterLeaveWindow = false;
			window.titleContent = new GUIContent("LuaScriptFinder");
			window.Show();
			window.Focus();
		}

		private void FindReferences()
		{
			if (string.IsNullOrWhiteSpace(_targetLower)) return;
			_tableData.Clear();
			_tableData.AddRange(_matchName
				? LuaScriptNameLowerInPath.Where(kv => string.CompareOrdinal(_targetLower, kv.Key) == 0)
					.SelectMany(kv => kv.Value)
				: LuaScriptNameLowerInPath.Where(kv => kv.Key.Contains(_targetLower)).SelectMany(kv => kv.Value));
		}
		
		private void InitGUIStyleIfNeeded()
		{
			if (_initializedGUIStyle) return;
			_toolbarGUIStyle = new GUIStyle("Toolbar");
			_initializedGUIStyle = true;
		}

		private void OnEnable()
		{
			_currentOnGuiState = _initializedData ? GUIState.Normal : GUIState.NotInit;
		}

		private void OnGUI()
		{
			switch (_currentOnGuiState)
			{
				case GUIState.NotInit:
					OnGuiNotInit();
					break;
				case GUIState.UpdateRefCaching:
					OnGuiUpdateRefCaching();
					break;
				case GUIState.Normal:
					OnGUINormal();
					break;
			}
		}

		private void OnGuiNotInit()
		{
			if (GUILayout.Button("初始化引用缓存"))
			{
				_initializedData = false;
				_currentOnGuiState = GUIState.UpdateRefCaching;
				InitData();
			}
		}
		
		private void OnGuiUpdateRefCaching()
        {
	        if (null != _initDataTask)
	        {
		        _currentOnGuiState = _initDataTask.OnGui();
		        if (_currentOnGuiState != GUIState.UpdateRefCaching)
		        {
			        _initDataTask = null;
		        }
	        }
	        else
	        {
		        if (Event.current.type == EventType.Repaint)
		        {
			        _currentOnGuiState = GUIState.NotInit;
		        }
	        }
        }

		private void OnGUINormal()
		{
			EditorGUI.BeginDisabledGroup(_currentOnGuiState != GUIState.Normal);
			EditorGUILayout.BeginHorizontal();
			_target = EditorGUILayout.TextField(_target);
			var lastMatch = _matchName;
			_matchName = GUILayout.Toggle(_matchName, "匹配名称", GUILayout.ExpandWidth(false));
			if (_matchName != lastMatch)
			{
				FindReferences();
				if (_assetTreeView != null)
				{
					_assetTreeView.CollapseAll();
					_assetTreeView.SetRoot(null);
				}
			}
			if (!_target.Equals(_lastTarget))
			{
				_lastTarget = _target;
				_targetLower = _lastTarget.ToLower();
				FindReferences();
				if (_assetTreeView != null)
				{
					_assetTreeView.CollapseAll();
					_assetTreeView.SetRoot(null);
				}
			}
			if (GUILayout.Button("ExpandedAll", GUILayout.ExpandWidth(false)))
			{
				_assetTreeView?.ExpandAll();
			}
			if (GUILayout.Button("CollapseAll", GUILayout.ExpandWidth(false)))
			{
				_assetTreeView?.CollapseAll();
			}
			if (GUILayout.Button("Refresh Data", GUILayout.ExpandWidth(false)))
			{
				_lastTarget = string.Empty;
				_initializedData = false;
				_currentOnGuiState = GUIState.UpdateRefCaching;
				InitData();
			}
			EditorGUILayout.EndHorizontal();
			if (_lastTarget.IsNullOrEmpty())
			{
				_tableData.Clear();
			}
			
			if (_tableData.Count > 0)
			{
				InitGUIStyleIfNeeded();
				UpdateAssetTree();
				if (_assetTreeView != null)
				{
					_assetTreeView.OnGUI(new Rect(0, _toolbarGUIStyle.fixedHeight, position.width,
						position.height - _toolbarGUIStyle.fixedHeight));
				}
			}
			EditorGUI.EndDisabledGroup();
		}

		private void UpdateAssetTree()
		{
			if(_assetTreeView == null)
			{
				//初始化TreeView
				treeViewState ??= new TreeViewState();
				var headerState = LuaTreeView.CreateDefaultMultiColumnHeaderState();
				var multiColumnHeader = new MultiColumnHeader(headerState);
				_assetTreeView = new LuaTreeView(treeViewState, multiColumnHeader);
			}
			
			if (_assetTreeView.IsRootNull())
				_assetTreeView.SetRoot(GenerateRootTreeViewNode());
			_assetTreeView.Reload();
		}

		private LuaTreeViewItem GenerateRootTreeViewNode()
		{
			var elementCount = 0;
			var root = new LuaTreeViewItem { id = elementCount, depth = -1, displayName = "Root", Path = null};
			const int baseDepth = 0;
			foreach (var record in _tableData)
			{
				var child = new LuaTreeViewItem
				{
					id = ++elementCount,
					depth = baseDepth + 1,
					displayName = Path.GetFileNameWithoutExtension(record.Path),
					Path = record.Path,
					IsScene = record.IsScene,
					IsPrefab = !record.IsScene,
					icon = AssetPreview.GetMiniTypeThumbnail(record.IsScene ? typeof(SceneAsset) : typeof(GameObject)),
				};
				foreach (var refRecord in record.Records.Where(refRecord => refRecord.scriptNameLower.Contains(_targetLower)))
				{
					child.AddChild(new LuaNodeTreeViewItem
					{
						Record = refRecord,
						depth = baseDepth + 2,
						displayName = refRecord.scriptName,
						id = ++elementCount,
						icon = AssetPreview.GetMiniTypeThumbnail(typeof(MonoScript))
					});
				}
				root.AddChild(child);
			}
			return root;
		}
	}
}
