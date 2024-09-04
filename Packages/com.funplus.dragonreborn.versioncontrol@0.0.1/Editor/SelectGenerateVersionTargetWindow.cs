using System;
using System.IO;
using DragonReborn.AssetTool.Editor;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public class SelectGenerateVersionTargetWindow : EditorWindow
	{
		[NonSerialized]
		public bool IsEncrypt;
		private BuildTarget _buildTarget;

		private void OnEnable()
		{
			_buildTarget = EditorUserBuildSettings.activeBuildTarget;
		}

		private void OnGUI()
		{
			_buildTarget = (BuildTarget)EditorGUILayout.EnumPopup(new GUIContent("选择目标平台"), _buildTarget, e =>
			{
				switch ((BuildTarget)e)
				{
					case BuildTarget.Android:
					case BuildTarget.iOS:
					case BuildTarget.StandaloneOSX:
					case BuildTarget.StandaloneWindows64:
						return true;
				}
				return false;
			}, false);
			EditorGUI.BeginDisabledGroup(_buildTarget != BuildTarget.Android 
			                             && _buildTarget != BuildTarget.iOS
			                             && _buildTarget != BuildTarget.StandaloneOSX
			                             && _buildTarget != BuildTarget.StandaloneWindows64);
			if (GUILayout.Button("生成VersionList"))
			{
				var bundleFolder = AssetBundleGenerator.GetBundleRelativeFolder(_buildTarget);
				var bundleName2Md5OverrideHash = Path.Combine(Application.streamingAssetsPath, bundleFolder, AssetBundleGenerator.BUNDLE_NAME2MD5_OVERRIDE_HASH_FILE);
				var assetLimitCfg = EditorUtility.OpenFilePanel("选择包体限制配置文件",
					Path.GetFullPath("../../tools/pack_tool/bundle_deploy_rule_config"), "json");
				VersionGenerator.GenerateStreamingAssetVersionList(IsEncrypt, bundleName2Md5OverrideHash, assetLimitCfg);
				Close();
			}
			EditorGUI.EndDisabledGroup();
		}
	}
}
