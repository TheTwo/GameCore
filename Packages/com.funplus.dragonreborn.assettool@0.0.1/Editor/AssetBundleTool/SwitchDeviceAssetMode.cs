using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using ICSharpCode.SharpZipLib.Core;
using ICSharpCode.SharpZipLib.Zip;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
public class SwitchDeviceAssetMode : EditorWindow
{

	// ReSharper disable InconsistentNaming
	private const bool DISALLOW_CHANG_TOGGLE = true;
	
	private const string SWITCH_BUNDLE_MODE_LAST_PATH_KEY = "SWITCH_BUNDLE_MODE_LAST_PATH_KEY";
	private const string SWITCH_BUNDLE_MODE_CLEAR_PATH_TOGGLE_KEY = "SWITCH_BUNDLE_MODE_CLEAR_PATH_TOGGLE_KEY";

	private const string USE_BUNDLE_ANDROID = "USE_BUNDLE_ANDROID";
    private const string USE_BUNDLE_IOS = "USE_BUNDLE_IOS";
    private const string USE_BUNDLE_STANDALONE = "USE_BUNDLE_STANDALONE";
    // ReSharper restore InconsistentNaming
    
    private bool _clearPersistentBuildPath;
    private Vector2 _scrollPos;

    public static void ExitDeviceAssetMode()
    {
	    RestoreStreamingAssetsBuild();
	    ChangeDeviceAssetModeFlag(false);
	    var activeBuildTarget = EditorUserBuildSettings.activeBuildTarget;
        var buildGroup = BuildPipeline.GetBuildTargetGroup(activeBuildTarget);
        var defs = PlayerSettings.GetScriptingDefineSymbolsForGroup(buildGroup);
        defs = ProcessScriptingDefineSymbols(defs, USE_BUNDLE_IOS, false);
        defs = ProcessScriptingDefineSymbols(defs, USE_BUNDLE_ANDROID, false);
        defs = ProcessScriptingDefineSymbols(defs, USE_BUNDLE_STANDALONE, false);
        PlayerSettings.SetScriptingDefineSymbolsForGroup(buildGroup, defs);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    public static void SetDeviceAssetMode(BuildTarget bundleTarget)
    {
	    if (bundleTarget == BuildTarget.NoTarget) return;
	    ChangeDeviceAssetModeFlag(true);
        var activeBuildTarget = EditorUserBuildSettings.activeBuildTarget;
        var buildGroup = BuildPipeline.GetBuildTargetGroup(activeBuildTarget);
        var defs = PlayerSettings.GetScriptingDefineSymbolsForGroup(buildGroup);
        defs = ProcessScriptingDefineSymbols(defs, USE_BUNDLE_IOS, bundleTarget == BuildTarget.iOS);
        defs = ProcessScriptingDefineSymbols(defs, USE_BUNDLE_ANDROID, bundleTarget == BuildTarget.Android);
        defs = ProcessScriptingDefineSymbols(defs, USE_BUNDLE_STANDALONE, bundleTarget 
	        is BuildTarget.StandaloneWindows 
	        or BuildTarget.StandaloneWindows64 
	        or BuildTarget.StandaloneOSX 
	        or BuildTarget.StandaloneLinux64);
        PlayerSettings.SetScriptingDefineSymbolsForGroup(buildGroup, defs);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    public static void ClearPersistentBuild()
    {
        var path = Path.Combine(Application.persistentDataPath, "GameAssets");
        if (Directory.Exists(path))
        {
            Directory.Delete(path, true);
        }
    }

    public static bool ChangeDeviceAssetModeFlag(bool isDeviceAssetMode)
    {
	    if (GetDeviceAssetModeFlag() == isDeviceAssetMode) return false;
	    EditorPrefs.SetBool(AssetModeSwitch.AssetModeSwitchEditorKey, isDeviceAssetMode);
	    return true;
    }
    
    public static bool GetDeviceAssetModeFlag()
    {
	    return EditorPrefs.GetBool(AssetModeSwitch.AssetModeSwitchEditorKey, false);
    }

    [MenuItem("DragonReborn/资源工具箱/通用/切换模拟真机资源模式", false, 0)]
    public static void Exec()
    {
        GetWindow<SwitchDeviceAssetMode>(true, "切换模拟真机资源模式").ShowUtility();
    }

    private void Awake()
    {
        _clearPersistentBuildPath = EditorPrefs.GetBool(SWITCH_BUNDLE_MODE_CLEAR_PATH_TOGGLE_KEY, true);
    }

    private void OnGUI()
    {
	    var checkEditorStatus = EditorApplication.isPlaying || EditorApplication.isCompiling ||
	                            EditorApplication.isPaused || EditorApplication.isPlayingOrWillChangePlaymode;
	    if (checkEditorStatus)
	    {
		    EditorGUILayout.HelpBox("当前状态下不可操作", MessageType.Warning);
	    }
	    EditorGUI.BeginDisabledGroup(checkEditorStatus);
        GUILayout.BeginVertical();
        {
	        var activeBuildTarget = EditorUserBuildSettings.activeBuildTarget;
	        var buildGroup = BuildPipeline.GetBuildTargetGroup(activeBuildTarget);
	        var defines = PlayerSettings.GetScriptingDefineSymbolsForGroup(buildGroup).AsSpan();
	        EditorGUI.BeginDisabledGroup(DISALLOW_CHANG_TOGGLE);
	        if (DrawToggle("编译开关-安卓", BuildTarget.Android ,defines, USE_BUNDLE_ANDROID))
	        {
		        Close();
				GUIUtility.ExitGUI();
	        }
	        if (DrawToggle("编译开关-IOS", BuildTarget.iOS, defines, USE_BUNDLE_IOS))
	        {
		        Close();
				GUIUtility.ExitGUI();
	        }
#if UNITY_EDITOR_WIN
#if UNITY_EDITOR_64
	        if (DrawToggle("编译开关-Standalone", BuildTarget.StandaloneWindows64, defines, USE_BUNDLE_STANDALONE))
#else
	            if (DrawToggle("编译开关-Standalone", BuildTarget.StandaloneWindows, defines, USE_BUNDLE_STANDALONE))
#endif
#elif UNITY_EDITOR_OSX
				if (DrawToggle("编译开关-Standalone", BuildTarget.StandaloneWindows, defines, USE_BUNDLE_STANDALONE))
#else
	            if (false)
#endif
	        {
		        Close();
				GUIUtility.ExitGUI();
	        }
	        EditorGUI.EndDisabledGroup();
	        GUILayout.Space(6f);
	        var choose = EditorGUILayout.Toggle("清理Persistent/GameAssets目录", _clearPersistentBuildPath);
            if (choose != _clearPersistentBuildPath)
            {
                _clearPersistentBuildPath = choose;
                EditorPrefs.SetBool(SWITCH_BUNDLE_MODE_CLEAR_PATH_TOGGLE_KEY, choose);
            }
            var sp = defines[..];
            if (!sp.IsEmpty)
            {
	            GUILayout.Space(6f);
	            GUILayout.Label("Defines:");
	            _scrollPos = GUILayout.BeginScrollView(_scrollPos);
	            var height = GUILayout.Height(EditorGUIUtility.singleLineHeight);
	            while (!sp.IsEmpty)
	            {
		            var index = sp.IndexOf(';');
		            if (index < 0)
		            {
			            EditorGUILayout.SelectableLabel(sp.ToString(), height);
			            break;
		            }
		            EditorGUILayout.SelectableLabel(sp[..index].ToString(), height);
		            sp = sp[(index+1)..];
	            }
	            GUILayout.EndScrollView();
            }
            GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal();
            {
                GUILayout.FlexibleSpace();
                if (GUILayout.Button("提取APK或者IPA"))
                {
                    ChooseFile();
                    Close();
					GUIUtility.ExitGUI();
                }
                EditorGUI.BeginDisabledGroup(!GetDeviceAssetModeFlag());
                if (GUILayout.Button("退出模拟真机资源模式"))
                {
	                if (_clearPersistentBuildPath) ClearPersistentBuild();
	                ExitDeviceAssetMode();
                    Close();
					GUIUtility.ExitGUI();
                }
                EditorGUI.EndDisabledGroup();
            }
            GUILayout.EndHorizontal();
        }
        GUILayout.EndHorizontal();
        EditorGUI.EndDisabledGroup();
    }

    private void ChooseFile()
    {
        var filePath = EditorUtility.OpenFilePanelWithFilters("选择apk 或者 ipa",
            EditorPrefs.GetString(SWITCH_BUNDLE_MODE_LAST_PATH_KEY, Application.dataPath), new []{"bundle source", "apk,ipa"});
        if (!File.Exists(filePath))
        {
            return;
        }
        if (_clearPersistentBuildPath) ClearPersistentBuild();
        var folder = Path.GetDirectoryName(filePath);
        EditorPrefs.SetString(SWITCH_BUNDLE_MODE_LAST_PATH_KEY, folder);
        var ext = Path.GetExtension(filePath);
        bool success;
        BuildTarget bundleTarget;
        switch (ext)
        {
            case ".apk":
                success = UnzipBuild("assets/", filePath, Application.streamingAssetsPath);
                bundleTarget = BuildTarget.Android;
                break;
            case ".ipa":
                success = UnzipBuild("Payload/as.app/Data/Raw/", filePath, Application.streamingAssetsPath);
                bundleTarget = BuildTarget.iOS;
                break;
            default:
	            success = false;
	            bundleTarget = BuildTarget.NoTarget;
	            break;
        }
        EditorUtility.ClearProgressBar();
        if (!success)
        {
            EditorUtility.DisplayDialog("错误", "选择的文件解压缩失败 StreamingAssets 下的资源可能有问题", "OK");
        }
        SetDeviceAssetMode(bundleTarget);
    }

    private bool UnzipBuild(string baseFolder, string filePath, string writePath)
    {
	    BackUpMoveStreamingAssetsBuild();
        var transBuffer = new byte[1048576];//1m
        var buildFolder = baseFolder;
        var binFolder = string.Concat(baseFolder, "bin/");
        var subStringStartIndex = baseFolder.Length;
        using var zipFile = new ZipFile(filePath);
        EditorUtility.ClearProgressBar();
        var p = new ProcessParameter
        {
	        TotalCount = zipFile.Count,
	        CurrentV = 0
        };
        var processCount = 0;
        ProgressHandler progressHandler = ProgressHandlerImpl;
        var updateInterval = TimeSpan.FromMilliseconds(10);
        var processStop = false;
        foreach (ZipEntry entry in zipFile)
        {
	        p.CurrentV = processCount++;
	        if (EditorUtility.DisplayCancelableProgressBar($"解压[{p.CurrentV}/{p.TotalCount}]", $"处理:{entry.Name}", p.CurrentV * 1f / p.TotalCount))
	        {
		        return false;
	        }

	        if (entry.IsDirectory)
	        {
		        if (!entry.Name.StartsWith(buildFolder)) continue;
		        if (entry.Name.StartsWith(binFolder)) continue;
		        var dirName = Path.Combine(writePath, entry.Name[subStringStartIndex..]);
		        if (!Directory.Exists(dirName))
		        {
			        Directory.CreateDirectory(dirName);
		        }
	        }
	        else if (entry.Name.StartsWith(buildFolder))
	        {
		        if (entry.Name.StartsWith(binFolder)) continue;
		        var fileName = entry.Name[subStringStartIndex..];
		        var dir = Path.GetDirectoryName(fileName);
		        var dirWritePath = string.IsNullOrEmpty(dir) ? writePath : Path.Combine(writePath, dir);
		        if (!Directory.Exists(dirWritePath))
		        {
			        Directory.CreateDirectory(dirWritePath);
		        }
                        
		        var writeFilePath = Path.Combine(writePath, fileName);
		        using var outFile = File.Create(writeFilePath);
		        var zip = zipFile.GetInputStream(entry);
		        StreamUtils.Copy(zip, outFile, transBuffer, progressHandler, updateInterval, null, entry.Name);
		        if (processStop) return false;
	        }
        }

        return true;

        void ProgressHandlerImpl(object sender, ProgressEventArgs e)
        {
	        var rate = (p.CurrentV + e.Processed * 1f / (e.Processed + e.Target)) / p.TotalCount;
	        if (EditorUtility.DisplayCancelableProgressBar($"解压[{p.CurrentV}/{p.TotalCount}]", $"处理:{e.Name}", rate))
	        {
		        processStop = true;
	        }
        }
    }

    private class ProcessParameter
    {
	    public long TotalCount;
	    public long CurrentV;
    }

    private static string ProcessScriptingDefineSymbols(string input, string symbols, bool add)
    {
        var changed = false;
        var tempList = new List<string>(input.Split(';'));
        if (add)
        {
            if (!tempList.Contains(symbols))
            {
                tempList.Add(symbols);
                changed = true;
            }
        }
        else
        {
            changed = tempList.Remove(symbols);
        }

        if (!changed) return input;
        var sb = new StringBuilder();
        foreach (var s in tempList)
        {
	        if (sb.Length > 0) sb.Append(';');
	        sb.Append(s);
        }
        return sb.ToString();
    }

    private static bool ScriptingDefineSymbolsContains(ReadOnlySpan<char> input, ReadOnlySpan<char> symbol)
    {
	    var sp = input;
	    var index = sp.IndexOf(';');
	    while (index >= 0)
	    {
		    if (index > 0)
		    {
			    if (symbol.Equals(sp[..index], StringComparison.Ordinal))
			    {
				    return true;
			    }
		    }
		    sp = sp[(index + 1)..];
		    index = sp.IndexOf(';');
	    }
	    return sp.Length >= 0 && symbol.Equals(sp, StringComparison.Ordinal);
    }

    private static bool DrawToggle(string content, BuildTarget buildTarget ,ReadOnlySpan<char> defines, ReadOnlySpan<char> symbol)
    {
	    var isMatch = ScriptingDefineSymbolsContains(defines, symbol);
	    var toggle = EditorGUILayout.Toggle(content, isMatch);
	    if (toggle == isMatch) return false;
	    if (toggle)
	    {
		    SetDeviceAssetMode(buildTarget);
	    }
	    else
	    {
		    ExitDeviceAssetMode();
	    }
	    return true;
    }

    private static void BackUpMoveStreamingAssetsBuild()
    {
	    if (GetDeviceAssetModeFlag()) return;
	    var targetFolder = Path.Combine(Application.dataPath, "../Library/StreamingAssetsBackup");
	    if (Directory.Exists(targetFolder)) Directory.Delete(targetFolder, true);
	    var editorStreamingAssetsFolder = Application.streamingAssetsPath;
	    if (!Directory.Exists(editorStreamingAssetsFolder)) return;
	    CopyFolder(editorStreamingAssetsFolder, targetFolder);
	    CleanUpEditorStreamingAssetsFolder(true);
    }

    private static void CleanUpEditorStreamingAssetsFolder(bool ignoreSpecficFolders)
    {
	    var editorStreamingAssetsFolder = new DirectoryInfo(Application.streamingAssetsPath);
	    if (!editorStreamingAssetsFolder.Exists) return;
	    ReflectionCallCleanUp();
	    AssetDatabase.ReleaseCachedFileHandles();
	    //file locked by google firebase sdk
	    const string googleFirebaseJson = "google-services-desktop.json";
	    const string googleFirebaseJsonMeta = "google-services-desktop.json.meta";
	    var gameAssetsFolder = new DirectoryInfo(Path.Combine(editorStreamingAssetsFolder.FullName, "GameAssets"));
	    var audioFolder = new DirectoryInfo(Path.Combine(gameAssetsFolder.FullName, "Audio"));
		var languageFolder = new DirectoryInfo(Path.Combine(gameAssetsFolder.FullName, "Languages"));
		if (ignoreSpecficFolders && audioFolder.Exists && languageFolder.Exists)
	    {
		    var files = gameAssetsFolder.GetFiles();
		    foreach (var file in files)
		    {
			    if (string.Compare("Audio.meta", file.Name, StringComparison.OrdinalIgnoreCase) == 0) continue;
				if (string.Compare("Languages.meta", file.Name, StringComparison.OrdinalIgnoreCase) == 0) continue;
				file.Delete();
		    }
		    var subFolders = gameAssetsFolder.GetDirectories();
		    foreach (var directoryInfo in subFolders)
		    {
			    if (string.Compare(directoryInfo.Name, "Audio", StringComparison.Ordinal) == 0) continue;
				if (string.Compare(directoryInfo.Name, "Languages", StringComparison.Ordinal) == 0) continue;
				directoryInfo.Delete(true);
		    }
		    var gameAssetsFolderMeta = gameAssetsFolder.Name + ".meta";
		    foreach (var fileInfo in editorStreamingAssetsFolder.GetFiles())
		    {
			    if (string.Compare(fileInfo.Name, googleFirebaseJson, StringComparison.OrdinalIgnoreCase) == 0) continue;
			    if (string.Compare(fileInfo.Name, googleFirebaseJsonMeta, StringComparison.OrdinalIgnoreCase) == 0) continue;
			    if (string.Compare(fileInfo.Name, gameAssetsFolderMeta, StringComparison.OrdinalIgnoreCase) == 0) continue;
			    fileInfo.Delete();
		    }
		    foreach (var subFolder in editorStreamingAssetsFolder.GetDirectories())
		    {
			    if (string.Compare(subFolder.Name, gameAssetsFolder.Name, StringComparison.OrdinalIgnoreCase) == 0) continue;
			    subFolder.Delete(true);
		    }
	    }
	    else
	    {
		    foreach (var fileInfo in editorStreamingAssetsFolder.GetFiles())
		    {
			    if (string.Compare(fileInfo.Name, googleFirebaseJson, StringComparison.OrdinalIgnoreCase) == 0) continue;
			    if (string.Compare(fileInfo.Name, googleFirebaseJsonMeta, StringComparison.OrdinalIgnoreCase) == 0) continue;
			    fileInfo.Delete();
		    }
		    foreach (var subFolder in editorStreamingAssetsFolder.GetDirectories())
		    {
			    subFolder.Delete(true);
		    }
	    }
    }

    private static void ReflectionCallCleanUp()
    {
	    var needCallMethods = TypeCache.GetTypesWithAttribute<MarkDomainReloadingAttribute>();
	    foreach (var type in needCallMethods)
	    {
		    foreach (MarkDomainReloadingAttribute attribute in type.GetCustomAttributes(typeof(MarkDomainReloadingAttribute), false))
		    {
			    if (string.IsNullOrWhiteSpace(attribute.CleanUpMethodName)) continue;
			    var method = type.GetMethod(attribute.CleanUpMethodName,
				    BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
			    if (null == method) continue;
			    method.Invoke(null, Array.Empty<object>());
		    }
	    }
	    GC.Collect();
	    GC.WaitForPendingFinalizers();
    }

    private static void RestoreStreamingAssetsBuild()
    {
	    if (!GetDeviceAssetModeFlag()) return;
	    CleanUpEditorStreamingAssetsFolder(false);
	    var targetFolder = Path.Combine(Application.dataPath, "../Library/StreamingAssetsBackup");
	    if (!Directory.Exists(targetFolder)) return;
	    CopyFolder(targetFolder, Application.streamingAssetsPath);
	    Directory.Delete(targetFolder, true);
    }
    
    private static void CopyFolder(string src, string target)
    {
	    if (!Directory.Exists(target)) Directory.CreateDirectory(target);
	    foreach (var file in Directory.GetFiles(src))
	    {
		    var targetPath = Path.Combine(target, Path.GetFileName(file));
		    File.Copy(file, targetPath, true);
	    }
	    foreach (var subDir in Directory.GetDirectories(src))
	    {
		    var targetPath = Path.Combine(target, Path.GetFileName(subDir));
		    CopyFolder(subDir, targetPath);
	    }
    }
}
