using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class AssetBatchRenameWindow : OdinEditorWindow
	{
		private enum ExtensionType
		{
			Texture,
			Material,
			AnimationClip,
			AnimationController,
			Fbx,
			Other,
		}

		[MenuItem("DragonReborn/资源工具箱/资源规范/资源批量改名助手")]
		public static void Open()
		{
			var window = GetWindow<AssetBatchRenameWindow>();
			window.titleContent = new GUIContent("资源批量改名助手");
			window.Show();
		}

		public string Prefix;
		[Title("形如typeXXX，如果已经有了，会自动忽略")]
		public string Prefix_2;
		public string MiddeName;

		private bool _canRename = false;
		private List<string> _selectedGuids = new();
		private HashSet<ExtensionType> _allExtentions = new();
		private int _counter;

		private const string READ_ME = @"选中要改名的资源（可以多选），然后点【批量改名】按钮";

		[OnInspectorGUI]
		private void OnInspectorGUI()
		{
			UnityEditor.EditorGUILayout.HelpBox(READ_ME, UnityEditor.MessageType.Info);

			if (_selectedGuids.Count > 0)
			{
				var msg = new StringBuilder();
				if (!IsExtensionsUnique(ref _allExtentions))
				{
					msg.AppendLine("请选择同一种类型的资源：");
					foreach (var ext in _allExtentions)
					{
						msg.AppendLine(ext.ToString());
					}
					UnityEditor.EditorGUILayout.HelpBox(msg.ToString(), UnityEditor.MessageType.Error);
					return;
				}

				_counter = 0;
				msg.Clear();
				msg.AppendLine($"当前选中了{Selection.count}个资源");
				foreach (var guid in _selectedGuids)
				{
					var assetPath = AssetDatabase.GUIDToAssetPath(guid);
					var filename = Path.GetFileNameWithoutExtension(assetPath);
					var suggestName = string.Empty;
					var extension = Path.GetExtension(assetPath);
					if (!string.IsNullOrEmpty(MiddeName) && !MiddeName.Equals(filename, System.StringComparison.OrdinalIgnoreCase))
					{
						suggestName = GetSuggestFilename(Prefix, Prefix_2, MiddeName, extension, _selectedGuids.Count > 1 ? _counter++ : -1);
					}
					else 
					{
						suggestName = GetSuggestFilename(Prefix, Prefix_2, filename, extension);
					}
					
					msg.AppendLine($"{filename} ==> {suggestName}");
				}
				UnityEditor.EditorGUILayout.HelpBox(msg.ToString(), UnityEditor.MessageType.Info);
			}
		}

		void OnSelectionChange()
		{
			Prefix = string.Empty;
			MiddeName = string.Empty;
			_selectedGuids.Clear();
			_canRename = Selection.count > 0;
			if (!_canRename)
			{
				return;
			}

			for (int i = 0; i < Selection.count; i++)
			{
				var guid = Selection.assetGUIDs[i];
				_selectedGuids.Add(guid);
			}

			_canRename = IsExtensionsUnique(ref _allExtentions);
			if (_canRename)
			{
				var extensionType = _allExtentions.First<ExtensionType>();
				Prefix = GetSuggestPrefix(extensionType);
			}
		}

		private bool IsExtensionsUnique(ref HashSet<ExtensionType> extensions)
		{
			if (_selectedGuids.Count == 0)
			{
				return true;
			}

			extensions.Clear();
			foreach (var guid in _selectedGuids)
			{
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				var extension = Path.GetExtension(assetPath);
				var extensionType = GetExtensionType(extension);
				extensions.Add(extensionType);
			}

			return extensions.Count <= 1;
		}

		private ExtensionType GetExtensionType(string extension)
		{
			if (extension.Equals(".mat", System.StringComparison.OrdinalIgnoreCase))
			{
				return ExtensionType.Material;
			}

			if (extension.Equals(".anim", System.StringComparison.OrdinalIgnoreCase))
			{
				return ExtensionType.AnimationClip;
			}

			if (extension.Equals(".controller", System.StringComparison.OrdinalIgnoreCase)
				|| extension.Equals(".overrideController", System.StringComparison.OrdinalIgnoreCase)
				)
			{
				return ExtensionType.AnimationController;
			}

			if (extension.Equals(".fbx", System.StringComparison.OrdinalIgnoreCase))
			{
				return ExtensionType.Fbx;
			}

			if (extension.Equals(".png", System.StringComparison.OrdinalIgnoreCase)
				|| extension.Equals(".tga", System.StringComparison.OrdinalIgnoreCase)
				)
			{
				return ExtensionType.Texture;
			}

			return ExtensionType.Other;
		}

		private string GetSuggestFilename(string prefix, string prefix_2, string originName, string extension, int number = -1)
		{
			var prefix_ = prefix + "_";
			if (originName.Contains(prefix_))
			{
				originName = originName.Replace(prefix_, "");
			}
			
			if (number >= 0)
			{
				if (originName.StartsWith("type") || string.IsNullOrEmpty(prefix_2))
				{
					return $"{prefix}_{originName}_{number}{extension}";
				}
				else
				{
					return $"{prefix}_{prefix_2}_{originName}_{number}{extension}";
				}
			}

			if (originName.StartsWith("type") || string.IsNullOrEmpty(prefix_2))
			{
				return $"{prefix}_{originName}{extension}";
			}
			else
			{
				return $"{prefix}_{prefix_2}_{originName}{extension}";
			}
		}

		private string GetSuggestPrefix(ExtensionType extensionType)
		{
			switch (extensionType)
			{
				case ExtensionType.Texture:
					return "tex";

				case ExtensionType.Material:
					return "mat";

				case ExtensionType.AnimationClip:
					return "anim";

				case ExtensionType.AnimationController:
					return "ctl";

				case ExtensionType.Fbx:
					return "fbx";
			}

			return string.Empty;
		}

		[EnableIf("_canRename")]
		[Button("批量改名", ButtonSizes.Gigantic)]
		public void PerformRename()
		{
			AssetDatabase.StartAssetEditing();
			_counter = 0;
			var list = _selectedGuids.ToArray();
			foreach (var guid in list)
			{
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				var filename = Path.GetFileNameWithoutExtension(assetPath);
				var extension = Path.GetExtension(assetPath);
				string suggestName;
				if (!string.IsNullOrEmpty(MiddeName) && !MiddeName.Equals(filename, System.StringComparison.OrdinalIgnoreCase))
				{
					suggestName = GetSuggestFilename(Prefix, Prefix_2, MiddeName, extension, _selectedGuids.Count > 1 ? _counter++ : -1 );
				}
				else
				{
					suggestName = GetSuggestFilename(Prefix, Prefix_2, filename, extension);
				}

				AssetDatabase.RenameAsset(assetPath, suggestName);
			}
			AssetDatabase.StopAssetEditing();

			AssetDatabase.Refresh();
		}
	}
}
