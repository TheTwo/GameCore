using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace DragonReborn.AssetTool.Editor
{
	public class MaterialBatchSetZTestTool : EditorWindow
	{
		private static readonly int ZTest = Shader.PropertyToID("_ZTest");

		private Shader _shader;
		private CompareFunction _compare;

		[MenuItem("DragonReborn/资源工具箱/材质工具/批量设置与指定Shader相关材质的ZTest")]
		private static void BatchSetZTest()
		{
			GetWindow<MaterialBatchSetZTestTool>("批量设置与指定Shader相关材质的ZTest");
		}

		private void OnGUI()
		{
			_shader = (Shader)EditorGUILayout.ObjectField("Shader", _shader, typeof(Shader), false);
			_compare = (CompareFunction)EditorGUILayout.EnumPopup("ZTest", _compare);

			if (GUILayout.Button("设置"))
			{
				var guids = AssetDatabase.FindAssets("t:Material");
				foreach (var guid in guids)
				{
					var path = AssetDatabase.GUIDToAssetPath(guid);
					var material = AssetDatabase.LoadAssetAtPath<Material>(path);
					if (material)
					{
						if (material.shader == _shader)
						{
							material.SetFloat(ZTest, (float)_compare);
						}
					}
				}
				
				AssetDatabase.Refresh();
			}
		}
	}
}
