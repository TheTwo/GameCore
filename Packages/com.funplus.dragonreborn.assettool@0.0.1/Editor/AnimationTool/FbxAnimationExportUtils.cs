using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using Newtonsoft.Json;
using UnityEditor.PackageManager;
using System.Diagnostics;
using Debug = UnityEngine.Debug;

namespace DragonReborn.AssetTool.Editor
{
	public class FbxAnimationExportUtils
	{
		private const string backupPath = "Assets/__EditorUI/ExportFBX/";
		private const string exportInfoPath = "Assets/__EditorUI/ExportFBX/Info/";
		private const string exportConfigPath = "Packages/com.funplus.dragonreborn.assettool@0.0.1/Editor/AnimationTool/FbxExportConfig.json";

		private static bool isExportWroking = false;

		public static bool IsSkipFbxImportProcess(string assetPath)
		{
			if (isExportWroking || assetPath.StartsWith(backupPath))
			{
				return true;
			}
			return false;
		}

		private class FbxExportConfig
		{
			public bool needBakFbx;
			public List<string> dir;
			public List<string> skipDir;
		}

		private static FbxExportConfig fbxExportConfig;

		private static bool InitFbxExportConfig()
		{
			if (!File.Exists(exportConfigPath))
			{
				return false;
			}

			var json = File.ReadAllText(exportConfigPath);
			fbxExportConfig = DataUtils.FromJson<FbxExportConfig>(json);
			return true;
		}

		private class AnimReplaceInfo
		{
			public string m_oldValue;
			public string m_newValue;
			public AnimReplaceInfo(string oldValue, string newValue)
			{
				m_oldValue = oldValue;
				m_newValue = newValue;
			}
		}

		[MenuItem("DragonReborn/资源工具箱/动画工具/打开配置目录")]
		private static void OpenConfigDir()
		{
			EditorUtility.RevealInFinder(exportConfigPath);
		}

		private static bool IsFbxAnim(string assetPath)
		{
			string fileName = Path.GetFileNameWithoutExtension(assetPath);
			if (Path.GetExtension(assetPath).ToLower() == ".fbx"
				&& fileName.IndexOf("@") >= 0 && fileName.StartsWith("fbx_"))//只处理分离模型fbx的动画
			{
				return true;
			}
			return false;
		}

		private static string TryGetExportAnimPath(string fbxPath, string animName)
		{
			string newName = Path.GetFileNameWithoutExtension(fbxPath);
			if (newName.StartsWith("fbx_"))
			{
				newName = newName.Replace("fbx_", "ani_");
			}
			if (newName.IndexOf("@") > 0)
			{
				newName = newName.Substring(0, newName.IndexOf("@"));
			}
			newName += "_" + animName;
			string newPath = Path.GetDirectoryName(fbxPath) + "/" + newName + ".anim";
			newPath = newPath.Replace("\\", "/");

			// 有重名的做替换处理
			// if (File.Exists(newPath))
			// {
			// 	AssetDatabase.DeleteAsset(newPath);
			// 	NLogger.Error("Anim Already exist: " + newName + " Delete old Path: " + newPath);
			// }
			
			//int maxTry = 3;
			//int i = 1;
			//for (; i <= maxTry; i++)
			//{
			//	UnityEngine.Object animObj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(newPath);
			//	if (animObj == null)
			//	{
			//		break;
			//	}

			//	newPath = Path.GetDirectoryName(fbxPath) + "/" + newName + "_" + i + ".anim";
			//	NLogger.Error("Anim Already exist: " + newName + " Use new Path: " + newPath);
			//}

			//if (i > maxTry)
			//{
			//	throw new Exception("Anim Already exist " + newPath);
			//}

			return newPath;
		}

#if !UNITY_EDITOR_OSX
		[MenuItem("DragonReborn/资源工具箱/动画工具/批量导出FBX动画文件并修复依赖")]
#endif
		public static void BatchExportFBXAnimation()
		{
			if (!InitFbxExportConfig())
			{
				NLogger.Error("InitFbxExportConfig failed!");
				return;
			}

			isExportWroking = true;

			NLogger.Error("start find all fbx!");

			Dictionary<string, List<string>> fbxDic = new Dictionary<string, List<string>>();
			Dictionary<string, List<AnimReplaceInfo>> exportDic = new Dictionary<string, List<AnimReplaceInfo>>();
			Dictionary<string, string> exportInfoDic = new Dictionary<string, string>();
			List<string> fbxNoRef = new List<string>();

			//查找所有fbx动画
			string[] _guids = AssetDatabase.FindAssets("t:" + "AnimationClip", fbxExportConfig.dir.ToArray());
			foreach (string guid in _guids)
			{
				string assetPath = AssetDatabase.GUIDToAssetPath(guid);
				if (IsFbxAnim(assetPath) && !IsExportIgnorePath(assetPath) && !fbxDic.ContainsKey(assetPath))
				{
					fbxDic.Add(assetPath, new List<string>());
				}
			}

			NLogger.Error("start find ref!");

			//查找依赖fbx动画的文件 
			int step = 0;
			int totalCount = fbxDic.Count;
			foreach (var (assetPath, refList) in fbxDic)
			{
				if ((step % 50 == 0) && EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", string.Format("Wait For Find Fbx Reference..."), (float)step / totalCount))
				{
					EditorUtility.ClearProgressBar();
					return;
				}
				if (step % 500 == 0)//需要gc避免mdfind的句柄溢出
				{
					GC.Collect();
				}
				string guid = AssetDatabase.AssetPathToGUID(assetPath);
				FindValueReferences(guid, refList);
				step++;
			}

			EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", "Wait For Find Fbx Reference...", 1f);

			Thread.Sleep(5000);

			//同位置导出动画
			int noRefCount = 0;
			step = 0;
			foreach (var (assetPath, refList) in fbxDic)
			{
				if (refList.Count == 0)
				{
					noRefCount++;
					NLogger.Error("fbx anim not find reference:" + assetPath);
					fbxNoRef.Add(assetPath);
				}

				if ((step % 50 == 0) && EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", string.Format("Wait For Export Anim..."), (float)step / totalCount))
				{
					EditorUtility.ClearProgressBar();
					return;
				}

				UnityEngine.Object[] assets = AssetDatabase.LoadAllAssetsAtPath(assetPath);
				foreach (var item in assets)
				{
					if (item is AnimationClip && !item.name.Contains("__preview__"))
					{
						string guid;
						long fileID;
						string oldValue;
						string newValue;
						AssetDatabase.TryGetGUIDAndLocalFileIdentifier(item, out guid, out fileID);
						oldValue = string.Format("fileID: {0}, guid: {1}, type: 3", fileID, guid);
						AnimationClip sourseClip = (AnimationClip)item;

						string newPath = TryGetExportAnimPath(assetPath, item.name);

						AnimationClip newClip = new AnimationClip();
						EditorUtility.CopySerialized(sourseClip, newClip);
						AssetDatabase.CreateAsset(newClip, newPath);

						UnityEngine.Object animObj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(newPath);
						AssetDatabase.TryGetGUIDAndLocalFileIdentifier(animObj, out guid, out fileID);
						newValue = string.Format("fileID: {0}, guid: {1}, type: 2", fileID, guid);

						if (exportDic.ContainsKey(assetPath))
						{
							exportDic[assetPath].Add(new AnimReplaceInfo(oldValue, newValue));
						}
						else
						{
							exportDic.Add(assetPath, new List<AnimReplaceInfo>());
							exportDic[assetPath].Add(new AnimReplaceInfo(oldValue, newValue));
						}

						if (!exportInfoDic.ContainsKey(oldValue))
						{
							exportInfoDic.Add(oldValue, newPath);
						}
					}
				}
				step++;
			}

			EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", "Wait For Export Anim...", 1f);

			Resources.UnloadUnusedAssets();
			GC.Collect();
			AssetDatabase.SaveAssets();

			EditorUtility.ClearProgressBar();

			NLogger.Error("start modify reference!");
			//修改依赖
			foreach (var (assetPath, refList) in fbxDic)
			{
				foreach (var path in refList)
				{
					string objTxt = File.ReadAllText(path);
					bool hasChange = false;
					foreach (var info in exportDic[assetPath])
					{
						if (Regex.IsMatch(objTxt, info.m_oldValue))
						{
							objTxt = objTxt.Replace(info.m_oldValue, info.m_newValue);
							hasChange = true;
						}
					}
					File.WriteAllText(path, objTxt);
					if (!hasChange)
					{
						NLogger.Error("ref res not modify may error. " + path);
					}
				}
			}

			SaveExportInfo(exportInfoDic, fbxDic, fbxNoRef);

			if (fbxExportConfig.needBakFbx)
			{
				NLogger.Error("start bak fbx!");
				//备份fbx
				foreach (var (assetPath, refList) in fbxDic)
				{
					string newPath = assetPath.Replace("Assets/__Art/StaticResources", backupPath);
					string dirPath = newPath.Substring(0, newPath.LastIndexOf("/"));
					if (!Directory.Exists(dirPath))
					{
						Directory.CreateDirectory(dirPath);
					}

					if (File.Exists(newPath))
					{
						NLogger.Error("Delete old bak fbx: " + newPath);
						File.Delete(newPath);
					}

					File.Move(assetPath, newPath);
					string metaPath = assetPath.Replace(".FBX", ".FBX.meta");
					string metaNewPath = newPath.Replace(".FBX", ".FBX.meta");
					File.Move(metaPath, metaNewPath);
				}
			}
			else
			{
				NLogger.Error("start delete fbx!");
				foreach (var pair in fbxDic)
				{
					File.Delete(pair.Key);
				}
			}

			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();

			isExportWroking = false;

			NLogger.Error("Finish " + fbxDic.Count + " no ref fbx count:" + noRefCount);
		}

#if UNITY_EDITOR_OSX
		[MenuItem("DragonReborn/资源工具箱/动画工具/批量导出FBX动画文件并修复依赖(OSX)")]
#endif
		public static void BatchExportFBXAnimation_OSX()
        {
            if (!InitFbxExportConfig())
            {
                NLogger.Error("InitFbxExportConfig failed!");
                return;
            }

            isExportWroking = true;
            
            NLogger.Error("start find all fbx!");

            Dictionary<string, List<string>> fbxDic = new Dictionary<string, List<string>>();
            Dictionary<string, List<AnimReplaceInfo>> exportDic = new Dictionary<string, List<AnimReplaceInfo>>();
            Dictionary<string, string> exportInfoDic = new Dictionary<string, string>();
            List<string> fbxNoRef = new List<string>();
            
            //查找所有fbx动画
            string[] _guids = AssetDatabase.FindAssets("t:" + "AnimationClip", fbxExportConfig.dir.ToArray());
            foreach (string guid in _guids)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(guid);
                if (IsFbxAnim(assetPath) && !IsExportIgnorePath(assetPath) && !fbxDic.ContainsKey(assetPath))
                {
                    fbxDic.Add(assetPath, new List<string>());
                }
            }
            
            NLogger.Error("start find ref!");
            
            //查找依赖fbx动画的文件 
            int step = 0;
            int totalCount = fbxDic.Count;
            foreach (var pair in fbxDic)
            {
                if ((step % 50 == 0) && EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", string.Format("Wait For Find Fbx Reference..."), (float)step / totalCount))
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }
                if (step % 600 == 0)//需要gc避免mdfind的句柄溢出
                {
                    GC.Collect();
                }
                string guid = AssetDatabase.AssetPathToGUID (pair.Key);
                FindValueReferences_OSX(guid, pair.Value);
                step++;
            }
            
            EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", "Wait For Find Fbx Reference...", 1f);
            
            Thread.Sleep(5000);
            
            //同位置导出动画
            int noRefCount = 0;
            step = 0;
            foreach (var pair in fbxDic)
            {
                if (pair.Value.Count == 0)
                {
                    noRefCount++;
                    NLogger.Error("fbx anim not find reference:" + pair.Key);
                    //continue;
                    fbxNoRef.Add(pair.Key);
                }
                
                if ((step % 50 == 0) && EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", string.Format("Wait For Export Anim..."), (float)step / totalCount))
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }
                
                UnityEngine.Object[] assets = AssetDatabase.LoadAllAssetsAtPath(pair.Key);
                foreach (var item in assets)
                {
                    if (item is AnimationClip && !item.name.Contains("__preview__"))
                    {
                        string guid;
                        long fileID;
                        string oldValue;
                        string newValue;
                        AssetDatabase.TryGetGUIDAndLocalFileIdentifier(item, out guid, out fileID);
                        oldValue = string.Format("fileID: {0}, guid: {1}, type: 3", fileID, guid);
                        AnimationClip sourseClip = (AnimationClip)item;

                        string newPath = TryGetExportAnimPath(pair.Key, item.name);
                        
                        AnimationClip newClip = new AnimationClip();
                        EditorUtility.CopySerialized(sourseClip, newClip);
                        AssetDatabase.CreateAsset(newClip, newPath);

                        UnityEngine.Object animObj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(newPath);
                        AssetDatabase.TryGetGUIDAndLocalFileIdentifier(animObj, out guid, out fileID);
                        newValue = string.Format("fileID: {0}, guid: {1}, type: 2", fileID, guid);
                        
                        if (exportDic.ContainsKey(pair.Key))
                        {
                            exportDic[pair.Key].Add(new AnimReplaceInfo(oldValue, newValue));
                        }
                        else
                        {
                            exportDic.Add(pair.Key, new List<AnimReplaceInfo>());
                            exportDic[pair.Key].Add(new AnimReplaceInfo(oldValue, newValue));
                        }
                        
                        if (!exportInfoDic.ContainsKey(oldValue))
                        {
                            exportInfoDic.Add(oldValue, newPath);
                        }
                    }
                }
                step++;
            }
            
            EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", "Wait For Export Anim...", 1f);
            
            Resources.UnloadUnusedAssets();
            GC.Collect();
            AssetDatabase.SaveAssets();
            
            EditorUtility.ClearProgressBar();
            
            NLogger.Error("start modify reference!");
            //修改依赖
            foreach (var pair in fbxDic)
            {
                foreach (var path in pair.Value)
                {
                    string objTxt = File.ReadAllText(path);
                    bool hasChange = false;
                    foreach (var info in exportDic[pair.Key])
                    {
                        if (Regex.IsMatch(objTxt, info.m_oldValue))
                        {
                            objTxt = objTxt.Replace(info.m_oldValue, info.m_newValue);
                            hasChange = true;
                        }
                    }
                    File.WriteAllText(path, objTxt);
                    if (!hasChange)
                    {
                        NLogger.Error("ref res not modify may error. " + path);
                    }
                }
            }

            SaveExportInfo(exportInfoDic, fbxDic, fbxNoRef);

            if (fbxExportConfig.needBakFbx)
            {
                NLogger.Error("start bak fbx!");
                //备份fbx
                foreach (var pair in fbxDic)
                {
                    string newPath = pair.Key.Replace("Assets/", backupPath);
                    string dirPath = newPath.Substring(0, newPath.LastIndexOf("/"));
                    if (!Directory.Exists(dirPath))
                    {
                        Directory.CreateDirectory(dirPath);
                    }
                    
                    if (File.Exists(newPath))
                    {
                        NLogger.Error("Delete old bak fbx: " + newPath);
                        File.Delete(newPath);
                    }
                    
                    File.Move(pair.Key, newPath);
                    string metaPath = pair.Key.Replace(".FBX", ".FBX.meta");
                    string metaNewPath = newPath.Replace(".FBX", ".FBX.meta");
                    File.Move(metaPath, metaNewPath);
                }
            }
            else
            {
                NLogger.Error("start delete fbx!");
                foreach (var pair in fbxDic)
                {
                    File.Delete(pair.Key);
                }
            }
            
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            
            isExportWroking = false;
            
            NLogger.Error("Finish " + fbxDic.Count + " no ref fbx count:" + noRefCount);
		}

		private static bool IsExportIgnorePath(string path)
        {
            foreach (var skipPath in fbxExportConfig.skipDir)
            {
                if (path.Contains(skipPath))
                {
                    return true;
                }
            }
            return false;
        }

        private class ResModifyInfo
        {
            public List<string> controllers;
            public List<string> playables;
            public List<string> others;
        }
        
        private class FbxExportInfo
        {
            public List<string> fbx;
            public List<string> noRefFbx;
        }

        private static void SaveExportInfo(Dictionary<string, string> infoDic, Dictionary<string, List<string>> fbxDic, List<string> fbxNoRef)
        {
            if (!Directory.Exists(exportInfoPath))
            {
                Directory.CreateDirectory(exportInfoPath);
            }

            string date = DateTime.Now.ToShortDateString().Replace("/", "_");
            string infoPath = exportInfoPath + "ExportInfo_" + date + ".json";
            string alltext = JsonConvert.SerializeObject(infoDic, Formatting.Indented);
            File.WriteAllText(infoPath, alltext);

            FbxExportInfo fbxExportInfo = new FbxExportInfo();
            fbxExportInfo.fbx = fbxDic.Keys.ToList();
            fbxExportInfo.fbx.Sort();
            fbxExportInfo.noRefFbx = fbxNoRef;
            fbxExportInfo.noRefFbx.Sort();
            string fbxModifyInfoPath = exportInfoPath + "FBXModify_" + date + ".json";
            alltext = JsonConvert.SerializeObject(fbxExportInfo, Formatting.Indented);
            File.WriteAllText(fbxModifyInfoPath, alltext);

            ResModifyInfo resModify = new ResModifyInfo();
            resModify.controllers = new List<string>(); 
            resModify.playables = new List<string>(); 
            resModify.others = new List<string>();
            
            foreach (var (assetPath, refList) in fbxDic)
            {
                foreach (var path in refList)
                {
                    string extension = Path.GetExtension(path).ToLower();
                    if (extension == ".overridecontroller" || extension == ".controller")
                    {
						if (!resModify.controllers.Contains(path))
						{
							resModify.controllers.Add(path);
						}
                    }
                    else if(extension == ".playable")
                    {
						if (!resModify.playables.Contains(path))
						{
							resModify.playables.Add(path);
						}
                    }
                    else
                    {
						if (!resModify.others.Contains(path))
						{
							resModify.others.Add(path);
						}
                    }
                }
            }
            resModify.controllers.Sort();
            resModify.playables.Sort();
            resModify.others.Sort();
            string resModifyInfoPath = exportInfoPath + "ResModify_" + date + ".json";
            alltext = JsonConvert.SerializeObject(resModify, Formatting.Indented);
            File.WriteAllText(resModifyInfoPath, alltext);
        }

#if UNITY_EDITOR_OSX
		[MenuItem("DragonReborn/资源工具箱/动画工具/修复已导出动画资源依赖(OSX)")]
#endif
		public static void ModifyExportedAnimReference()
        {
            string exportInfoFile = EditorUtility.OpenFilePanel("Select Export Info", exportInfoPath, "json");
            if (string.IsNullOrEmpty(exportInfoFile))
            {
				NLogger.Error("需要选择一个已有的exportinfo");
                return;
            }
            
            var json = File.ReadAllText(exportInfoFile);
            Dictionary<string, string>  exportInfoDic = DataUtils.FromJson<Dictionary<string, string>>(json);
            Dictionary<string, List<string>> fbxRefDic = new Dictionary<string, List<string>>();
            
            int step = 0;
            int totalCount = exportInfoDic.Count;
            foreach (var pair in exportInfoDic)
            {
                if ((step % 50 == 0) && EditorUtility.DisplayCancelableProgressBar("ModifyExportedAnimRef", string.Format("Wait For Find Value Reference..."), (float)step / totalCount))
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }
                if (step % 300 == 0)//需要gc避免mdfind的句柄溢出
                {
                    GC.Collect();
                }
                fbxRefDic.Add(pair.Key, new List<string>());
                FindValueReferences_OSX(pair.Key, fbxRefDic[pair.Key]);
                step++;
            }

            EditorUtility.DisplayCancelableProgressBar("ExportFbxAnim", "Wait For Find Fbx Reference...", 1f);
            
            Thread.Sleep(5000);
            
            EditorUtility.ClearProgressBar();
            
            string guid;
            long fileID;
            foreach (var pair in fbxRefDic)
            {
                foreach (var path in pair.Value)
                {
                    string animPath = exportInfoDic[pair.Key];
                    UnityEngine.Object animObj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(animPath);
                    if (animObj == null)
                    {
						NLogger.Error("export anim not exist :" + animPath);
                        continue;;
                    }
                    AssetDatabase.TryGetGUIDAndLocalFileIdentifier(animObj, out guid, out fileID);
                    string newValue = string.Format("fileID: {0}, guid: {1}, type: 2", fileID, guid);
                    string oldValue = pair.Key;
                    string objTxt = File.ReadAllText(path);
                    if (Regex.IsMatch(objTxt, oldValue))
                    {
                        objTxt = objTxt.Replace(oldValue, newValue);
                    }
                    File.WriteAllText(path, objTxt);
					NLogger.Error("modify ref :" + path);
                }
            }
            
            Resources.UnloadUnusedAssets();
            GC.Collect();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            
            NLogger.Error("Finish");
		}

		private static void FindValueReferences(string value, List<string> references)
		{
			var checkRootFolder = Path.Combine(Application.dataPath, "__Art");
			FindInDirectory(value, checkRootFolder, references);
		}

		private static void FindInDirectory(string value, string dirPath, List<string> references)
		{
			var appDataPath = Application.dataPath;
			foreach (var filePath in Directory.GetFiles(dirPath))
			{
				if (!filePath.EndsWith(".controller", StringComparison.OrdinalIgnoreCase))
				{
					continue;
				}

				if (IsValueInFile(value, filePath))
				{
					var relativePath = "Assets" + filePath.Replace(appDataPath, "");
					references.Add(relativePath);
					return;
				}
			}

			foreach (var info in Directory.GetDirectories(dirPath))
			{
				FindInDirectory(value, info, references);
			}
		}

		private static bool IsValueInFile(string value, string path)
		{
			var contents = File.ReadAllText(path);
			return Regex.IsMatch(contents, value);
		}

		private static void FindValueReferences_OSX(string value, List<string> references)
        {
            string appDataPath = Application.dataPath;
            
            var psi = new System.Diagnostics.ProcessStartInfo();
            psi.WindowStyle = System.Diagnostics.ProcessWindowStyle.Maximized;
            psi.FileName = "/usr/bin/mdfind";
            psi.Arguments = "-onlyin " + Application.dataPath + " " + string.Format("\"{0}\"", value);
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;

            System.Diagnostics.Process process = new System.Diagnostics.Process();
            process.StartInfo = psi;
		
            process.OutputDataReceived += (sender, e) => {
                if (string.IsNullOrEmpty(e.Data))
                {
                    return;
                }
                
                string relativePath = "Assets" + e.Data.Replace(appDataPath, "");
				if (relativePath.EndsWith(".meta"))
				{
					return;
				}

                references.Add(relativePath);
            };
            
            process.Start();
            process.BeginOutputReadLine();
            process.WaitForExit(2000);
        }

#if UNITY_EDITOR_OSX
		[MenuItem("Assets/Find References Fast(OSX)", false, 2000)]
#endif
        private static void FindProjectReferencesOSX()
        {
            EventWaitHandle myEventWaitHandle = new EventWaitHandle(false, EventResetMode.ManualReset);
        
            string appDataPath = Application.dataPath;
            string output = "";
            string selectedAssetPath = AssetDatabase.GetAssetPath (Selection.activeObject);
            List<string> references = new List<string>();
		
            string guid = AssetDatabase.AssetPathToGUID (selectedAssetPath);
		
            var psi = new System.Diagnostics.ProcessStartInfo();
            psi.WindowStyle = System.Diagnostics.ProcessWindowStyle.Maximized;
            psi.FileName = "/usr/bin/mdfind";
            psi.Arguments = "-onlyin " + Application.dataPath + " " + guid;
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
		
            System.Diagnostics.Process process = new System.Diagnostics.Process();
            process.StartInfo = psi;
		
            process.OutputDataReceived += (sender, e) => {
                if (string.IsNullOrEmpty(e.Data))
                {
                    myEventWaitHandle.Set();
                    return;
                }

                string relativePath = "Assets" + e.Data.Replace(appDataPath, "");
			
                // skip the meta file of whatever we have selected
                if(relativePath == selectedAssetPath + ".meta")
                    return;
			
                references.Add(relativePath);
            };
            process.ErrorDataReceived += (sender, e) => {
                if(string.IsNullOrEmpty(e.Data))
                    return;
			
                output += "Error: " + e.Data + "\n";
            };
            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
		
            process.WaitForExit(2000);

            myEventWaitHandle.WaitOne();
		
            foreach(var file in references){
                output += file + "\n";
                NLogger.Error(file, AssetDatabase.LoadMainAssetAtPath(file));
            }
		
            NLogger.Error(references.Count + " references found for object " + Selection.activeObject.name + "\n\n" + output);
        }

		[MenuItem("Assets/快捷工具/导出选择的FBX动画文件并优化(不修复依赖)")]
		private static void ExportSelectFbxAnimInAssetsMenu()
		{
			ExportSelectFBXAnim();
		}

        [MenuItem("DragonReborn/资源工具箱/动画工具/导出选择的FBX动画文件并优化(不修复依赖)")]
        private static void ExportSelectFBXAnim()
        {
            isExportWroking = true;
            
            List<string> fbxList = new List<string>();
            string[] guids = null;
            List<string> path = new List<string>();
            UnityEngine.Object[] objs = Selection.GetFiltered(typeof(object), SelectionMode.Assets);
            if (objs.Length > 0)
            {
                for (int i = 0; i < objs.Length; i++)
                {
                    if (objs[i].GetType() == typeof(AnimationClip))
                    {
                        string p = AssetDatabase.GetAssetPath(objs[i]);
                        if (IsFbxAnim(p) && !fbxList.Contains(p))
                        {
                            fbxList.Add(p);
                        }
                    }
                    else
                        path.Add(AssetDatabase.GetAssetPath(objs[i]));
                }

                if (path.Count > 0)
                    guids = AssetDatabase.FindAssets(string.Format("t:{0}", typeof(AnimationClip).ToString().Replace("UnityEngine.", "")), path.ToArray());
                else
                    guids = new string[] { };
            }
            
            for(int i = 0; i < guids.Length; i++)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(guids[i]);
                if (IsFbxAnim(assetPath) && !fbxList.Contains(assetPath))
                {
                    fbxList.Add(assetPath);
                }
            }
            
            foreach (var assetPath in fbxList)
            {
                UnityEngine.Object[] assets = AssetDatabase.LoadAllAssetsAtPath(assetPath);
                foreach (var item in assets)
                {
                    if (item is AnimationClip && !item.name.Contains("__preview__"))
                    {
                        // string guid;
                        // long fileID;
                        AnimationClip sourseClip = (AnimationClip)item;
                        string newPath = TryGetExportAnimPath(assetPath, item.name);
                        
                        AnimationClip existingClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(newPath);
                        
                        if (existingClip != null)
                        {
	                        // 如果已存在，使用CopySerialized替换现有clip的内容
	                        var clipName = Path.GetFileNameWithoutExtension(newPath);
	                        sourseClip.name = clipName;
	                        EditorUtility.CopySerialized(sourseClip, existingClip);
	                        Debug.Log("AnimationClip已存在，已覆盖: " + newPath);
                        }
                        else
                        {
	                        // 如果不存在，创建新的资源
	                        AnimationClip newClip = new AnimationClip();
	                        EditorUtility.CopySerialized(sourseClip, newClip);
	                        AssetDatabase.CreateAsset(newClip, newPath);
	                        Debug.Log("创建了新的AnimationClip: " + newPath);
                        }

                        AssetDatabase.SaveAssets();
                        AssetDatabase.Refresh();

						// 按照配置压缩动画
						// 确保传入正确的AnimationClip实例给压缩工具
                        if (existingClip != null)
                        {
	                        OptimizeAnimationClipTool.OptimizeAnimationClip(newPath, existingClip);
                        }
                        else
                        {
	                        AnimationClip newClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(newPath);
	                        OptimizeAnimationClipTool.OptimizeAnimationClip(newPath, newClip);
                        }
                    }
                }
            }
            //Resources.UnloadUnusedAssets();
            //GC.Collect();
            AssetDatabase.SaveAssets();
            Selection.activeObject = null;
            // 移动到下面目录
            foreach (var assetPath in fbxList)
            {
                string newPath = assetPath.Replace("Assets/", backupPath);
                string dirPath = newPath.Substring(0, newPath.LastIndexOf("/"));
                if (!Directory.Exists(dirPath))
                {
                    Directory.CreateDirectory(dirPath);
                }
                
                if (File.Exists(newPath))
                {
	                AssetDatabase.DeleteAsset(newPath);
                    NLogger.Error("Delete old bak fbx: " + newPath);
                    // File.Delete(newPath);
                }
                
                // 移动资产
                AssetDatabase.MoveAsset(assetPath, newPath);
                
                // File.Move(assetPath, newPath);
                // string metaPath = assetPath.Replace(".FBX", ".FBX.meta");
                // string metaNewPath = newPath.Replace(".FBX", ".FBX.meta");
                // File.Move(metaPath, metaNewPath);
                
                NLogger.Log("Bak Fbx: " + newPath);
            }
            
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            
            isExportWroking = false;
        }

        //[MenuItem("DragonReborn/资源工具箱/资源规范/日常检查/输出选中目录")]
        private static void SelectExportFolder()
        {
            List<string> folderList = new List<string>();
            UnityEngine.Object[] objs = Selection.GetFiltered(typeof(object), SelectionMode.Assets);
            if (objs.Length > 0)
            {
                for (int i = 0; i < objs.Length; i++)
                {
                    folderList.Add(AssetDatabase.GetAssetPath(objs[i]));
                }
            }
            folderList.Sort();
            string alltext = JsonConvert.SerializeObject(folderList, Formatting.Indented);
            File.WriteAllText(exportInfoPath + "folderList.json", alltext);
        }
    }
}
