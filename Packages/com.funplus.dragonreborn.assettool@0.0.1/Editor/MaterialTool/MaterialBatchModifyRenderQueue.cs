using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public class MaterialBatchModifyRenderQueue : OdinEditorWindow
	{
		[MenuItem("DragonReborn/资源工具箱/材质工具/手动调整材质RenderQueue小助手")]
		public static void ShowBatchModifyRenderQueue ()
		{
			var window = GetWindow<MaterialBatchModifyRenderQueue>();
			window.titleContent = new GUIContent("批量调整材质RenderQueue助手");
			window.Show();
		}

		[Title("目标RenderQueue")]
		public int NewRenderQueue = 3050;

		private bool _canModify = false;
		private List<string> _selectedGuids = new();

		[OnInspectorGUI]
		private void OnInspectorGUI()
		{
			if (_selectedGuids.Count > 0)
			{
				var msg = new StringBuilder();
				msg.Clear();
				msg.AppendLine($"RenderQueue调整预览：");
				foreach (var guid in _selectedGuids)
				{
					var assetPath = AssetDatabase.GUIDToAssetPath(guid);
					var filename = Path.GetFileNameWithoutExtension(assetPath);
					var material = AssetDatabase.LoadMainAssetAtPath(assetPath) as Material;
					if (material == null)
					{
						continue;
					}

					var rq = material.renderQueue;
					if (rq == NewRenderQueue)
					{
						continue;
					}

					msg.AppendLine($"{filename}: from {rq} to {NewRenderQueue}");
				}
				UnityEditor.EditorGUILayout.HelpBox(msg.ToString(), UnityEditor.MessageType.Info);
			}
		}

		[EnableIf("_canModify")]
		[Button("批量修改", ButtonSizes.Gigantic)]
		public void PerformModify()
		{
			AssetDatabase.StartAssetEditing();
			var list = _selectedGuids.ToArray();
			foreach (var guid in list)
			{
				var assetPath = AssetDatabase.GUIDToAssetPath(guid);
				var material = AssetDatabase.LoadMainAssetAtPath(assetPath) as Material;
				if (material == null)
				{
					continue;
				}

				material.renderQueue = NewRenderQueue;
			}
			AssetDatabase.StopAssetEditing();
			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
		}

		void OnSelectionChange()
		{
			_selectedGuids.Clear();
			_canModify = Selection.count > 0;
			if (!_canModify)
			{
				return;
			}

			for (int i = 0; i < Selection.count; i++)
			{
				var guid = Selection.assetGUIDs[i];
				_selectedGuids.Add(guid);
			}
		}
	}
}
