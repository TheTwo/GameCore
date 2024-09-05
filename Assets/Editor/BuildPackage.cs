using UnityEngine;
using System.Collections;
using UnityEditor;
using System.Collections.Generic;

public class BuildPackage : MonoBehaviour
{
    [MenuItem("Tools/BuildiOS")]
    public static void BuildiOS ()
    {
        ConfigArg();
        Debug.Log (Application.dataPath + "/build");
		BuildPipeline.BuildPlayer(GetBuildScenes(), Application.dataPath + "/../../Snake-Xcode", BuildTarget.iOS, BuildOptions.None); 
    }

    [MenuItem("Tools/BuildAndroid")]
    public static void BuildAndroid ()
    {      
        ConfigArg();
        PlayerSettings.Android.keyaliasPass = "%TGB6yhn";
        PlayerSettings.Android.keystorePass = "%TGB6yhn";
        BuildPipeline.BuildPlayer(GetBuildScenes(), Application.dataPath + "/../build/snake.apk", BuildTarget.Android, BuildOptions.None); 
    }

    static string[] GetBuildScenes()
    { 
        List<string> names = new List<string>(); 

        foreach (EditorBuildSettingsScene e in EditorBuildSettings.scenes)
        { 
            if (e == null) 
                continue; 

            if (e.enabled)
            {
                Debug.Log("======= EditorBuildSettingsScene =========" + e.path);
                names.Add(e.path); 
            }
        } 
        return names.ToArray(); 
    }

    private static void ConfigArg()
    {
        //      buildSettingPath = BUILD_SETTING_PATH;
        foreach (string arg in System.Environment.GetCommandLineArgs())
        {
            if (arg.Contains("bundleVersion"))
            {
                PlayerSettings.bundleVersion = arg.Substring(arg.IndexOf("=") + 1);

                Debug.Log("========set version ========= " + arg.Substring(arg.IndexOf("=") + 1));
            }
            else if(arg.Contains("versionCode"))
            {
                PlayerSettings.Android.bundleVersionCode = int.Parse(arg.Substring(arg.IndexOf("=") + 1));
                Debug.Log("========set bundleVersionCode ========= " + arg.Substring(arg.IndexOf("=") + 1));
            }
        }

        PlayerPrefs.DeleteAll();
    }
}
