using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
internal static class JumpFolder
{
    [MenuItem("DragonReborn/常用路径/PersistentDataPath", false, 1)]
    private static void OpenPersistentDataPath()
    {
        OpenFolder(Application.persistentDataPath);
    }
    
    [MenuItem("DragonReborn/常用路径/StreamingAssetsPathh", false, 2)]
    private static void OpenStreamingAssetsPath()
    {
        OpenFolder(Application.streamingAssetsPath);
    }
    
    [MenuItem("DragonReborn/常用路径/TemporaryCachePath", false, 3)]
    private static void OpenTemporaryCachePath()
    {
        OpenFolder(Application.temporaryCachePath);
    }
    
    [MenuItem("DragonReborn/常用路径/ConsoleLogFolder", false, 4)]
    private static void OpenConsoleLogFolder()
    {
        var p = Application.consoleLogPath;
        if (string.IsNullOrWhiteSpace(p)) return;
        var folder = Path.GetDirectoryName(p);
        if (string.IsNullOrWhiteSpace(folder)) return;
        OpenFolder(folder);
    }

    private static void OpenFolder(string path)
    {
        Application.OpenURL(path);
    }
}
