using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using DragonReborn;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace PackFileExplorer
{
	public class PackFileExplorerWindow : EditorWindow
	{
		private string _filePath;
		private IFileSystemStreamCreateHelper _streamCreateHelper;
		private IFileSystemStream _currentFileSystemStream;
		private IFileSystem _currentFileSystem;
		private PackFileTreeView _treeView;
		private TreeViewState _treeViewState;
		private SearchField _searchField;
		
		[MenuItem("DragonReborn/资源工具箱/通用/.pack文件浏览器")]
		private static void ShowWindow()
		{
			var window = GetWindow<PackFileExplorerWindow>();
			window.titleContent = new GUIContent("pack文件浏览器");
			window.Show();
		}

		private void Awake()
		{
			_streamCreateHelper = new FileSystemStreamCreateHelper();
			_treeViewState = new TreeViewState();
			_treeView = new PackFileTreeView(_treeViewState);
			_searchField = new SearchField();
			_searchField.downOrUpArrowKeyPressed += _treeView.SetFocusAndEnsureSelectedItem;
			_treeView.SetDataSource(null, null);
			_treeView.Reload();
		}

		private void OnDestroy()
		{
			UnLoad();
		}

		private void Load()
		{
			UnLoad();
			_currentFileSystem?.Shutdown();
			_currentFileSystemStream?.Close();
			_currentFileSystemStream = _streamCreateHelper.CreateFileSystemStream(_filePath, FileSystemAccess.Read, false);
			_currentFileSystem = FileSystem.Load(_filePath, FileSystemAccess.Read, _currentFileSystemStream);
			var infos = _currentFileSystem.GetAllFileInfos();
			_treeView.SetDataSource(infos, DumpContent);
			_treeView.Reload();
			_treeView.multiColumnHeader.sortedColumnIndex = _treeView.SorIndex;
		}

		private void UnLoad()
		{
			_treeView.searchString = string.Empty;
			_currentFileSystem?.Shutdown();
			_currentFileSystem = null;
			_currentFileSystemStream?.Close();
			_currentFileSystemStream = null;
			_treeView?.SetDataSource(null, null);
			_treeView?.Reload();
		}

		private void OnGUI()
		{
			GUILayout.BeginHorizontal();
			GUILayout.Label("File:", GUILayout.ExpandWidth(false));
			EditorGUILayout.SelectableLabel(_filePath, GUILayout.ExpandWidth(true));
			if (GUILayout.Button("Open", GUILayout.ExpandWidth(false)))
			{
				var filePath =
					EditorUtility.OpenFilePanelWithFilters("选择 pack 文件", Application.dataPath, new[] { "packFile", "pack" });
				if (File.Exists(filePath))
				{
					_filePath = filePath;
					UnLoad();
					Load();
				}
			}
			GUILayout.EndHorizontal();
			if (null != _currentFileSystem)
			{
				GUILayout.BeginHorizontal();
				GUILayout.FlexibleSpace();
				if (GUILayout.Button("DumpToFolder", GUILayout.ExpandWidth(false)))
				{
					DumpPack();
				}
				GUILayout.EndHorizontal();
			}
			if (null != _treeView)
			{
				_treeView.searchString = _searchField.OnGUI(_treeView.searchString);
			}
			_treeView?.OnGUI(GUILayoutUtility.GetRect(40, float.MaxValue,40, float.MaxValue));
		}

		private readonly byte[] _cache = new byte[4096];

		private void DumpContent(object obj)
		{
			if (null == _currentFileSystem) return;
			if (obj is not FileEntryInfo fileEntryInfo) return;
			if (!_currentFileSystem.HasFile(fileEntryInfo.Name)) return;
			var savePath = EditorUtility.SaveFilePanel("DumpTo", Path.GetFullPath("."), fileEntryInfo.Name, "dump");
			if (string.IsNullOrWhiteSpace(savePath)) return;
			using var outFile = new FileStream(savePath, FileMode.Create, FileAccess.Write);
			DumpContentToStream(fileEntryInfo, outFile);
		}

		private unsafe void DumpContentToStream(FileEntryInfo fileEntryInfo, Stream stream)
		{
			var leftCount = fileEntryInfo.Length;
			fixed (void* pointer = &_cache[0])
			{
				var offset = 0;
				var ptr = new IntPtr(pointer);
				while (leftCount > 0)
				{
					var length = Math.Min(leftCount, _cache.Length);
					_currentFileSystem.ReadFile(fileEntryInfo.Name, ptr, offset, length);
					stream.Write(_cache, 0, length);
					offset += length;
					leftCount -= length;
				}
			}
		}

		private void DumpPack()
		{
			if (null == _currentFileSystem) return;
			var fileInfos = _currentFileSystem.GetAllFileInfos();
			if (fileInfos.Length <= 0) return;
			var folder = EditorUtility.SaveFolderPanel("DumpToFolder", Path.GetFullPath("."),
				Path.GetFileNameWithoutExtension(_filePath));
			if (string.IsNullOrWhiteSpace(folder)) return;
			if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
			foreach (var fileEntryInfo in fileInfos)
			{
				using var writeTo =
					new FileStream(Path.Combine(folder, fileEntryInfo.Name + ".dump"), FileMode.Create);
				DumpContentToStream(fileEntryInfo, writeTo);
			}
		}

		private class PackFileTreeView : TreeView
		{
			[SuppressMessage("ReSharper", "UnusedMember.Local")]
			public enum SortType
			{
				Ascending = -1,
				None = 0,
				Descending = 1,
			}

			private readonly List<TreeViewItem> _rows = new();
			private FileEntryInfo[] _dataSource;
			private GenericMenu.MenuFunction2 _dumpFunc;
			private int _sorIndex;
			private readonly SortType[] _sortStatus = { SortType.Ascending,SortType.None,SortType.None };
			public int SorIndex => _sorIndex;

			public PackFileTreeView(TreeViewState state) : base(state, new MultiColumnHeader(CreateDefaultMultiColumnHeaderState()))
			{
				showBorder = true;
				showAlternatingRowBackgrounds = true;
				multiColumnHeader.sortingChanged += header =>
				{
					SetSortStatus(header.sortedColumnIndex, multiColumnHeader.IsSortedAscending(header.sortedColumnIndex)? SortType.Ascending: SortType.Descending);
				};
			}

			public void SetDataSource(FileEntryInfo[] dataSrc, GenericMenu.MenuFunction2 dumpFunc)
			{
				_dataSource = dataSrc;
				_dumpFunc = dumpFunc;
			}

			public void SetSortStatus(int index, SortType value)
			{
				if (_sortStatus[index] == value && _sorIndex == index) return;
				_sorIndex = index;
				_sortStatus[index] = value;
				Reload();
			}

			protected override TreeViewItem BuildRoot()
			{
				var root  = new TreeViewItem { id = 0, depth = -1, displayName = "Root" };

				return root;
			}

			protected override IList<TreeViewItem> BuildRows(TreeViewItem root)
			{
				_rows.Clear();
				if (_dataSource is not { Length: > 0 })
				{
					return _rows;
				}
				var ret = new PackFileTreeViewItem(0, -1, "Root");
				int id = 1;
				for (int i = 0; i < _dataSource.Length; i++)
				{
					if (hasSearch)
					{
						if (! _dataSource[i].Name.Contains(searchString, StringComparison.OrdinalIgnoreCase)) continue;
					}
					var child = BuildTreeViewNode(ref id, ret, _dataSource[i], _dataSource[i].Name);
					ret.AddChild(child);
					_rows.Add(child);
				}
				SetupDepthsFromParentsAndChildren(ret);
				SortIsNeed();
				return _rows;
			}
			
			protected override void RowGUI(RowGUIArgs args)
			{
				var item = (PackFileTreeViewItem)args.item;
				for(int i = 0; i < args.GetNumVisibleColumns(); ++i)
				{
					CellGUI(args.GetCellRect(i), item, args.GetColumn(i));
				}
			}
			
			private void CellGUI(Rect cellRect,PackFileTreeViewItem item,int column)
			{
				CenterRectUsingSingleLineHeight(ref cellRect);
				switch (column)
				{
					case 0:
					{
						GUI.Label(cellRect, item.FileEntryInfo.Name);
					}
						break;
					case 1:
					{
						GUI.Label(cellRect, item.FileEntryInfo.Offset.ToString());
					}
						break;
					case 2:
					{
						GUI.Label(cellRect, item.FileEntryInfo.Length.ToString());
					}
						break;
				}
			}

			protected override void ContextClickedItem(int id)
			{
				var idx = _rows.FindIndex(cell => cell.id == id);
				if (idx < 0) return;
				var rawItem = _rows[idx];
				if (rawItem is not PackFileTreeViewItem item) return;
				if (null == _dumpFunc) return;
				var menu = new GenericMenu();
				menu.AddItem(new GUIContent("Dump..."), false, _dumpFunc, item.FileEntryInfo);
				menu.ShowAsContext();
			}

			private void SortIsNeed()
			{
				if (_sortStatus[_sorIndex] == 0) return;
				DoSort();
			}

			private void DoSort()
			{
				_rows.Sort((a, b) =>
				{
					var i0 = (PackFileTreeViewItem)a;
					var i1 = (PackFileTreeViewItem)b;
					var ret = 0;
					if (_sortStatus[_sorIndex] < 0)
					{
						ret = i0.CompareTo(i1, _sorIndex);
					}
					if (_sortStatus[_sorIndex] > 0)
					{
						ret = i1.CompareTo(i0, _sorIndex);
					}
					return ret;
				});
			}
			
			private static MultiColumnHeaderState CreateDefaultMultiColumnHeaderState()
			{
				var columns = new[]
				{
					new MultiColumnHeaderState.Column
					{
						headerContent = new GUIContent("FileName"),
						allowToggleVisibility = false,
						sortedAscending = true,
						canSort = true        
					},
					new MultiColumnHeaderState.Column
					{
						headerContent = new GUIContent("Offset"),
						sortedAscending = true,
						canSort = true
					},
					new MultiColumnHeaderState.Column
					{
						headerContent = new GUIContent("Length"),
						headerTextAlignment = TextAlignment.Center,
						canSort = true,          
					},
				};
				var state = new MultiColumnHeaderState(columns);
				return state;
			}

			private static PackFileTreeViewItem BuildTreeViewNode(ref int id, TreeViewItem parent, FileEntryInfo data, string nodeName)
			{
				PackFileTreeViewItem addNode;
				if (null == parent)
				{
					addNode = new PackFileTreeViewItem(id++, -1, nodeName);
				}
				else
				{
					addNode = new PackFileTreeViewItem(id++, nodeName, data);
					parent.AddChild(addNode);
				}
				return addNode;
			}
		}

		private sealed class PackFileTreeViewItem : TreeViewItem
		{
			public readonly FileEntryInfo FileEntryInfo;

			public int CompareTo(PackFileTreeViewItem other, int index)
			{
				return index switch
				{
					0 => string.CompareOrdinal(FileEntryInfo.Name, other.FileEntryInfo.Name),
					1 => FileEntryInfo.Offset.CompareTo(other.FileEntryInfo.Offset),
					2 => FileEntryInfo.Length.CompareTo(other.FileEntryInfo.Length),
					_ => throw new ArgumentOutOfRangeException()
				};
			}

			public PackFileTreeViewItem(int id, string nodeName, FileEntryInfo data) : base(id)
			{
				FileEntryInfo = data;
				displayName = nodeName;
			}

			public PackFileTreeViewItem(int id, int depth, string displayName) : base(id, depth, displayName)
			{
			}
		}
	}
}
