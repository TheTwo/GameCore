using System.Diagnostics;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace DragonReborn
{
	public class VersionGenerator
    {
        [MenuItem("DragonReborn/资源工具箱/出包工具/GenerateStreamingAssetVersionList")]
        public static void GenerateStreamingAssetVersionList_Entrypt()
        {
			var isEncrypt = IOUtils.HasEncryptTag();
			var w = EditorWindow.GetWindow<SelectGenerateVersionTargetWindow>(true);
			w.IsEncrypt = isEncrypt;
			w.Show();
        }

        private static int ExecProcessCmd(string fileName, string arguments, string workDir, int timeout = 1800000)
        {
	        var task = System.Threading.Tasks.Task.Run(() =>
	        {
		        using var process = new Process();
		        var ps = process.StartInfo;
		        ps.FileName = fileName;
		        ps.Arguments = arguments;
		        ps.WorkingDirectory = workDir;
		        ps.UseShellExecute = false;
		        ps.CreateNoWindow = true;
		        ps.RedirectStandardOutput = true;
		        ps.RedirectStandardError = true;

		        process.OutputDataReceived += (sender, args) =>
		        {
			        if (!string.IsNullOrEmpty(args.Data))
			        {
				        UnityEngine.Debug.Log(args.Data);
			        }
		        };
		        process.ErrorDataReceived += (sender, args) =>
		        {
			        if (!string.IsNullOrEmpty(args.Data))
			        {
				        UnityEngine.Debug.LogError(args.Data);
			        }
		        };

		        process.Start();
		        process.BeginOutputReadLine();
		        process.BeginErrorReadLine();
		        process.WaitForExit(timeout);
		        return process.ExitCode;
	        });
	        task.Wait();
	        return task.Result;
        }

        public static void GenerateStreamingAssetVersionList(bool useEngrypt, string bundleName2Md5OverrideHash, string assetLimitCfgPath)
		{
			if (!string.IsNullOrWhiteSpace(bundleName2Md5OverrideHash))
			{
				bundleName2Md5OverrideHash = Path.GetFullPath(bundleName2Md5OverrideHash);
			}
#if UNITY_EDITOR_OSX
			var shellScriptPath = Path.GetFullPath("../../tools/pack_tool/bin/checkAndSign_osx.sh");
			if (ExecProcessCmd("bash", $"'{shellScriptPath}'",  Path.GetFullPath("../../tools/pack_tool/bin/")) != 0)
			{
				throw new System.ArgumentException("call checkAndSign_osx.sh error");
			}
			var toolPath = Path.GetFullPath("../../tools/pack_tool/bin/CsFilePackTool");
			if (ExecProcessCmd(toolPath, $"--versionList {Application.streamingAssetsPath} {Application.streamingAssetsPath} {useEngrypt} {bundleName2Md5OverrideHash} {assetLimitCfgPath}", Path.GetFullPath("../../")) != 0)
			{
				throw new System.ArgumentException("call CsFilePackTool error");
			}
#elif UNITY_EDITOR_WIN
			if (ExecProcessCmd(Path.GetFullPath("..\\..\\tools\\pack_tool\\bin\\CsFilePackTool.exe"), $"--versionList \"{Path.GetFullPath(Application.streamingAssetsPath)}\" \"{Path.GetFullPath(Application.streamingAssetsPath)}\" {useEngrypt} {bundleName2Md5OverrideHash} {assetLimitCfgPath}",  Path.GetFullPath("..\\..\\")) != 0)
			{
				throw new System.ArgumentException("call CsFilePackTool error");
			}
#else
			throw new System.NotImplementedException("only support UNITY_EDITOR_OSX or UNITY_EDITOR_WIN");
#endif
		}

		public static void GenerateStreamingAssetGameAssetsBundlesBeforeLoading(bool useEngrypt, BuildTarget target)
		{
			var bundleStripFolder = "";
			switch (target)
			{
				case BuildTarget.Android:
					bundleStripFolder = "GameAssets/AssetBundle/Android";
					break;
				case BuildTarget.iOS:
					bundleStripFolder = "GameAssets/AssetBundle/IOS";
					break;
				case BuildTarget.StandaloneOSX:
					bundleStripFolder = "GameAssets/AssetBundle/OSX";
					break;
				case BuildTarget.StandaloneWindows:
				case BuildTarget.StandaloneWindows64:
					bundleStripFolder = "GameAssets/AssetBundle/Windows";
					break;
			}
			var ruleFile = Path.GetFullPath("../../tools/pack_tool/bundle_deploy_rule_config/assets_before_loading.json");
#if UNITY_EDITOR_OSX
			var shellScriptPath = Path.GetFullPath("../../tools/pack_tool/bin/checkAndSign_osx.sh");
			using (var p = new Process())
			{
				var startInfo = p.StartInfo;
				startInfo.FileName = "bash";
				startInfo.Arguments = $"'{shellScriptPath}'";
				startInfo.WorkingDirectory = Path.GetFullPath("../../tools/pack_tool/bin/");
				startInfo.RedirectStandardError = true;
				startInfo.RedirectStandardOutput = true;
				startInfo.UseShellExecute = false;
				startInfo.CreateNoWindow = true;
				p.Start();
				UnityEngine.Debug.Log(p.StandardOutput.ReadToEnd());
				p.WaitForExit();
				if (p.ExitCode != 0)
				{
					UnityEngine.Debug.LogError(p.StandardError.ReadToEnd());
					throw new System.ArgumentException("call checkAndSign_osx.sh error");
				}
			}
			var toolPath = Path.GetFullPath("../../tools/pack_tool/bin/CsFilePackTool");
			using (var p = new Process())
			{
				var startInfo = p.StartInfo;
				startInfo.FileName = toolPath;
				startInfo.Arguments = $"--assetBeforeLoadingGenerate {useEngrypt} {Application.streamingAssetsPath} {bundleStripFolder} {ruleFile}";
				startInfo.WorkingDirectory = Path.GetFullPath("../../");
				startInfo.RedirectStandardError = true;
				startInfo.RedirectStandardOutput = true;
				startInfo.UseShellExecute = false;
				startInfo.CreateNoWindow = true;
				p.Start();
				UnityEngine.Debug.Log(p.StandardOutput.ReadToEnd());
				p.WaitForExit();
				if (p.ExitCode != 0)
				{
					UnityEngine.Debug.LogError(p.StandardError.ReadToEnd());
					throw new System.ArgumentException("call CsFilePackTool error");
				}
			}

#elif UNITY_EDITOR_WIN
			using var p = new Process();
			var startInfo = p.StartInfo;
			startInfo.FileName = Path.GetFullPath("..\\..\\tools\\pack_tool\\bin\\CsFilePackTool.exe");
			startInfo.Arguments =
				$"--assetBeforeLoadingGenerate {useEngrypt} {Application.streamingAssetsPath} {bundleStripFolder} {ruleFile}";
			startInfo.WorkingDirectory = Path.GetFullPath("..\\..\\");
			startInfo.RedirectStandardError = true;
			startInfo.RedirectStandardOutput = true;
			startInfo.UseShellExecute = false;
			startInfo.CreateNoWindow = true;
			p.Start();
			UnityEngine.Debug.Log(p.StandardOutput.ReadToEnd());
			p.WaitForExit();
			if (p.ExitCode == 0) return;
			UnityEngine.Debug.LogError(p.StandardError.ReadToEnd());
			throw new System.ArgumentException("call CsFilePackTool error");
#else
			throw new System.NotImplementedException("only support UNITY_EDITOR_OSX or UNITY_EDITOR_WIN");
#endif
		}

		public static void GenerateStreamingAssetGameAssetsBundlesLoadOrder(bool useEngrypt, BuildTarget target)
		{
			var bundleStripFolder = "";
			switch (target)
			{
				case BuildTarget.Android:
					bundleStripFolder = "GameAssets/AssetBundle/Android";
					break;
				case BuildTarget.iOS:
					bundleStripFolder = "GameAssets/AssetBundle/IOS";
					break;
				case BuildTarget.StandaloneOSX:
					bundleStripFolder = "GameAssets/AssetBundle/OSX";
					break;
				case BuildTarget.StandaloneWindows:
				case BuildTarget.StandaloneWindows64:
					bundleStripFolder = "GameAssets/AssetBundle/Windows";
					break;
			}
			var ruleFile = Path.GetFullPath("../../tools/pack_tool/bundle_deploy_rule_config/assets_load_order.json");
#if UNITY_EDITOR_OSX
			var shellScriptPath = Path.GetFullPath("../../tools/pack_tool/bin/checkAndSign_osx.sh");
			using (var p = new Process())
			{
				var startInfo = p.StartInfo;
				startInfo.FileName = "bash";
				startInfo.Arguments = $"'{shellScriptPath}'";
				startInfo.WorkingDirectory = Path.GetFullPath("../../tools/pack_tool/bin/");
				startInfo.RedirectStandardError = true;
				startInfo.RedirectStandardOutput = true;
				startInfo.UseShellExecute = false;
				startInfo.CreateNoWindow = true;
				p.Start();
				UnityEngine.Debug.Log(p.StandardOutput.ReadToEnd());
				p.WaitForExit();
				if (p.ExitCode != 0)
				{
					UnityEngine.Debug.LogError(p.StandardError.ReadToEnd());
					throw new System.ArgumentException("call checkAndSign_osx.sh error");
				}
			}
			var toolPath = Path.GetFullPath("../../tools/pack_tool/bin/CsFilePackTool");
			using (var p = new Process())
			{
				var startInfo = p.StartInfo;
				startInfo.FileName = toolPath;
				startInfo.Arguments = $"--assetLimitGenerate {useEngrypt} {Application.streamingAssetsPath} {bundleStripFolder} {ruleFile}";
				startInfo.WorkingDirectory = Path.GetFullPath("../../");
				startInfo.RedirectStandardError = true;
				startInfo.RedirectStandardOutput = true;
				startInfo.UseShellExecute = false;
				startInfo.CreateNoWindow = true;
				p.Start();
				UnityEngine.Debug.Log(p.StandardOutput.ReadToEnd());
				p.WaitForExit();
				if (p.ExitCode != 0)
				{
					UnityEngine.Debug.LogError(p.StandardError.ReadToEnd());
					throw new System.ArgumentException("call CsFilePackTool error");
				}
			}

#elif UNITY_EDITOR_WIN
			using var p = new Process();
			var startInfo = p.StartInfo;
			startInfo.FileName = Path.GetFullPath("..\\..\\tools\\pack_tool\\bin\\CsFilePackTool.exe");
			startInfo.Arguments =
				$"--assetLimitGenerate {useEngrypt} {Application.streamingAssetsPath} {bundleStripFolder} {ruleFile}";
			startInfo.WorkingDirectory = Path.GetFullPath("..\\..\\");
			startInfo.RedirectStandardError = true;
			startInfo.RedirectStandardOutput = true;
			startInfo.UseShellExecute = false;
			startInfo.CreateNoWindow = true;
			p.Start();
			UnityEngine.Debug.Log(p.StandardOutput.ReadToEnd());
			p.WaitForExit();
			if (p.ExitCode == 0) return;
			UnityEngine.Debug.LogError(p.StandardError.ReadToEnd());
			throw new System.ArgumentException("call CsFilePackTool error");
#else
			throw new System.NotImplementedException("only support UNITY_EDITOR_OSX or UNITY_EDITOR_WIN");
#endif
		}

		private const string MENU_KEY = "DragonReborn/资源工具箱/出包工具/加密状态";
		[MenuItem(MENU_KEY, false, 100)]
		private static void ToggleEncryptMode()
		{

		}

		[MenuItem(MENU_KEY, true, 100)]
		private static bool CheckEncryptMode()
		{
			var isEncrypt = IOUtils.HasEncryptTag();
			Menu.SetChecked(MENU_KEY, isEncrypt);
			return true;
		}

		[MenuItem("DragonReborn/资源工具箱/出包工具/开启加密", false, 101)]
		private static void GenEncryptTag()
		{
			GenUseEncryptTag(true);
		}

		[MenuItem("DragonReborn/资源工具箱/出包工具/关闭加密", false, 102)]
		private static void DelEncryptTag()
		{
			GenUseEncryptTag(false);
		}

		public static void GenUseEncryptTag(bool useEncrypt)
		{
			var filePath = IOUtils.GetGameAssetPathInPackage(IOUtils.ENCRYPT_TAG);
			if (File.Exists(filePath))
			{
				File.Delete(filePath);
			}

			if (useEncrypt)
			{
				File.WriteAllText(filePath, "!");
			}
			AssetDatabase.Refresh();
		}

		[MenuItem("DragonReborn/资源工具箱/安全工具/解码XOR文件", false, 2000)]
		private static void DecodeXORFile()
		{
			var selectedAssetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
			var filename = Path.GetFileNameWithoutExtension(selectedAssetPath);
			var newPath = selectedAssetPath.Replace(filename, filename + "_12345");
			if (File.Exists(newPath)) File.Delete(newPath);
			var bytes = File.ReadAllBytes(selectedAssetPath);
			SafetyUtils.CodeByteBuffer(bytes);
			File.WriteAllBytes(newPath, bytes);
			AssetDatabase.Refresh();
		}

		[MenuItem("DragonReborn/资源工具箱/安全工具/解码加密的AssetBundle", false, 2000)]
		private static void DecodeAssetBundle()
		{
			var selectedAssetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
			var filename = Path.GetFileNameWithoutExtension(selectedAssetPath);
			var newPath = selectedAssetPath.Replace(filename, filename + "_12345");
			if (File.Exists(newPath)) File.Delete(newPath);
			SafetyUtils.DecryptHeadOffset(filename, selectedAssetPath, newPath);
			AssetDatabase.Refresh();
		}

		[MenuItem("DragonReborn/资源工具箱/安全工具/计算选中文件的crc", false, 2000)]
		private static void CompulteFileCrc()
		{
			string selectedAssetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
			var bytes = File.ReadAllBytes(selectedAssetPath);
			var crc = Crc32Algorithm.Compute(bytes);
			UnityEngine.Debug.LogError($"{selectedAssetPath} crc: {crc}");
		}

		[MenuItem("DragonReborn/资源工具箱/安全工具/计算选中文件的md5", false, 2000)]
		private static void CompulteFileMd5()
		{
			string selectedAssetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
			var md5 = Md5Utils.GetFileMd5(selectedAssetPath);
			UnityEngine.Debug.LogError($"{selectedAssetPath} md5: {md5}");
		}
    }
}

