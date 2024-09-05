//// C# example:
//using UnityEngine;
//using UnityEditor;
//using UnityEditor.Callbacks;
//using System;
//
//using UnityEditor.iOS.Xcode;
//using System.IO;
//
//public class Postprocessor
//{
//    [PostProcessBuildAttribute(1)]
//    public static void OnPostprocessBuild(BuildTarget target, string pathToBuiltProject)
//    {
//        if (target == BuildTarget.iOS) 
//        {
//            _AddDeviceCapabilities(pathToBuiltProject);
//            _AddFrameWork(pathToBuiltProject);
//			_AddFiles (pathToBuiltProject);
//        }
//    }
//
//    static void _AddDeviceCapabilities(string pathToBuiltProject)
//    {
//        string infoPlistPath = Path.Combine (pathToBuiltProject, "./Info.plist");
//        PlistDocument plist = new PlistDocument();
//        plist.ReadFromString (File.ReadAllText(infoPlistPath));
//
//        PlistElementDict rootDict = plist.root;
//        PlistElementArray deviceCapabilityArray = rootDict.CreateArray("UIRequiredDeviceCapabilities");
//        deviceCapabilityArray.AddString("armv7");
//        deviceCapabilityArray.AddString("gamekit"); 
//
//        rootDict.SetBoolean("UIRequiresFullScreen", true);
//
//		PlistElementArray schemes = rootDict.CreateArray ("LSApplicationQueriesSchemes");
//		schemes.AddString ("weixin");
//		schemes.AddString ("wechat");
//
//
//        PlistElementArray urlTypes = rootDict.CreateArray("CFBundleURLTypes");
//
//        // add weixin url scheme
//        PlistElementDict wxUrl = urlTypes.AddDict();
//        wxUrl.SetString("CFBundleTypeRole", "Editor");
//        wxUrl.SetString("CFBundleURLName", "weixin");
//        PlistElementArray wxUrlScheme = wxUrl.CreateArray("CFBundleURLSchemes");
//        wxUrlScheme.AddString("wxec0aca87957f6311");      
//
//        File.WriteAllText(infoPlistPath,plist.WriteToString());
//    }
//
//    static void _AddFrameWork(string pathToBuiltProject)
//    {
//        string projPath = PBXProject.GetPBXProjectPath (pathToBuiltProject);
//        PBXProject proj = new PBXProject ();
//
//        proj.ReadFromString (File.ReadAllText (projPath));
//        string target = proj.TargetGuidByName ("Unity-iPhone");
//
//		proj.AddFrameworkToProject (target, "libicucore.tbd", false);
//		proj.AddFrameworkToProject (target, "libz.tbd", false);
//		proj.AddFrameworkToProject (target, "libstdc++.tbd", false);
//		proj.AddFrameworkToProject (target, "JavaScriptCore.framework", false);
//		proj.AddFrameworkToProject (target, "libsqlite3.tbd", false);
//
//		File.WriteAllText (projPath, proj.WriteToString ());
//    }
//
//	static void _AddFiles(string pathToBuiltProject)
//	{
//		
//	}
//}