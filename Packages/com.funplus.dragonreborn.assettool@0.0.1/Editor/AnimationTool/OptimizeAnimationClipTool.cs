//****************************************************************************
//
//  File:      OptimizeAnimationClipTool.cs
//
//  Copyright (c) SuiJiaBin
//
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
//****************************************************************************
using System;
using System.Collections.Generic;
using UnityEngine;
using System.Reflection;
using UnityEditor;
using System.IO;

namespace DragonReborn.AssetTool.Editor
{
    class AnimationOpt
    {
        static Dictionary<uint,string> _FLOAT_FORMAT;
        static MethodInfo getAnimationClipStats;
        static FieldInfo sizeInfo;
        static object[] _param = new object[1];

        static AnimationOpt ()
        {
            _FLOAT_FORMAT = new Dictionary<uint, string> ();
            for (uint i = 1; i < 6; i++) {
                _FLOAT_FORMAT.Add (i, "f" + i.ToString ());
            }
            
            Assembly asm = Assembly.GetAssembly (typeof(UnityEditor.Editor));
            getAnimationClipStats = typeof(AnimationUtility).GetMethod ("GetAnimationClipStats", BindingFlags.Static | BindingFlags.NonPublic);
            Type aniclipstats = asm.GetType ("UnityEditor.AnimationClipStats");
            sizeInfo = aniclipstats.GetField ("size", BindingFlags.Public | BindingFlags.Instance);
        }

        AnimationClip _clip;
        string _path;
        uint _Precision;

        public string path { get{ return _path;} }

        public long originFileSize { get; private set; }

        public long originMemorySize { get; private set; }

        public int originInspectorSize { get; private set; }

        public long optFileSize { get; private set; }

        public long optMemorySize { get; private set; }

        public int optInspectorSize { get; private set; }

        public AnimationOpt(string path, AnimationClip clip, uint precision = 3)
        {
            _path = path;
            _clip = clip;
            _Precision = precision;
            _GetOriginSize ();
        }

        void _GetOriginSize ()
        {
            originFileSize = _GetFileZie ();
            originMemorySize = _GetMemSize ();
            originInspectorSize = _GetInspectorSize ();
        }

        void _GetOptSize ()
        {
            optFileSize = _GetFileZie ();
            optMemorySize = _GetMemSize ();
            optInspectorSize = _GetInspectorSize ();
        }

        long _GetFileZie ()
        {
            FileInfo fi = new FileInfo (_path);
            return fi.Length;
        }

        long _GetMemSize ()
        {
            return UnityEngine.Profiling.Profiler.GetRuntimeMemorySizeLong (_clip);
        }

        int _GetInspectorSize ()
        {
            _param [0] = _clip;
            var stats = getAnimationClipStats.Invoke (null, _param);
            return (int)sizeInfo.GetValue (stats);
        }

        void _OptmizeAnimationScaleCurve ()
        {
            if (_clip != null)
            {
                //去除scale曲线
                foreach (EditorCurveBinding theCurveBinding in AnimationUtility.GetCurveBindings(_clip))
                {
                    string name = theCurveBinding.propertyName.ToLower();
                    if (name.Contains("scale"))
                    {
                        AnimationCurve curve = AnimationUtility.GetEditorCurve(_clip, theCurveBinding);
                        if (curve == null)
                            continue;
                        if (curve.keys == null || curve.keys.Length == 0)
                        {
                            AnimationUtility.SetEditorCurve(_clip, theCurveBinding, null);
                            Debug.LogFormat("关闭{0}的scale curve", _clip.name);
                        }
                        else
                        {
                            bool useness = true;
                            float oriValue = 1;
                            for (int i = 0; i < curve.keys.Length; i++)
                            {
                                if (Mathf.Abs(curve.keys[i].value - oriValue) > 0.0001f)
                                {
                                    useness = false;
                                    break;
                                }
                            }
                            if (useness)
                            {
                                AnimationUtility.SetEditorCurve(_clip, theCurveBinding, null);
                                Debug.LogFormat("关闭{0}的scale curve", _clip.name);
                            }
                        }
                    }
                }
            }
        }

        void _OptmizeAnimationFloat_X (uint x)
        {
            if (_clip != null && x > 0) {
                //浮点数精度压缩到fx
                //AnimationClipCurveData[] curves = null;
				//curves = AnimationUtility.GetAllCurves (_clip);
				var curveBindings = AnimationUtility.GetCurveBindings(_clip);
				Keyframe key;
                Keyframe[] keyFrames;
                //string floatFormat;
                if (_FLOAT_FORMAT.TryGetValue (x, out string floatFormat)) {
                    //if (curves != null && curves.Length > 0) {
					if (curveBindings != null && curveBindings.Length > 0) {
                        for (int ii = 0; ii < curveBindings.Length; ++ii) {
							//AnimationClipCurveData curveDate = curves [ii];
							var curveBinding = curveBindings[ii];
							var curve = AnimationUtility.GetEditorCurve(_clip, curveBinding);
                            //if (curveDate.curve == null || curveDate.curve.keys == null) {
							if (curve == null || curve.keys == null) { 
                                //Debug.LogWarning(string.Format("AnimationClipCurveData {0} don't have curve; Animation name {1} ", curveDate, animationPath));
                                continue;
                            }
							//keyFrames = curveDate.curve.keys;
							keyFrames = curve.keys;
							for (int i = 0; i < keyFrames.Length; i++) {
                                key = keyFrames [i];
                                key.value = float.Parse (key.value.ToString (floatFormat));
                                key.inTangent = float.Parse (key.inTangent.ToString (floatFormat));
                                key.outTangent = float.Parse (key.outTangent.ToString (floatFormat));
                                keyFrames [i] = key;
                            }
							//curveDate.curve.keys = keyFrames;
							curve.keys = keyFrames;
							//_clip.SetCurve (curveDate.path, curveDate.type, curveDate.propertyName, curveDate.curve);
							_clip.SetCurve(curveBinding.path, curveBinding.type, curveBinding.propertyName, curve);
                        }
                    }
                } else {
                    Debug.LogErrorFormat ("目前不支持{0}位浮点", x);
                }
            }
        }

        private void _Optimize (bool scaleOpt, uint precision)
        {
            if (scaleOpt) {
                _OptmizeAnimationScaleCurve ();
            }
            _OptmizeAnimationFloat_X (precision);
            //_GetOptSize ();
        }

        public void Optimize()
        {
            _Optimize(true, _Precision);
        }

        public void LogOrigin ()
        {
            _logSize (originFileSize, originMemorySize, originInspectorSize);
        }

        public void LogOpt ()
        {
            _logSize (optFileSize, optMemorySize, optInspectorSize);
        }

        public void LogDelta ()
        {

        }

        void _logSize (long fileSize, long memSize, int inspectorSize)
        {
            Debug.LogFormat ("{0} \nSize=[ {1} ]", _path, string.Format ("FSize={0} ; Mem->{1} ; inspector->{2}",
                EditorUtility.FormatBytes (fileSize), EditorUtility.FormatBytes (memSize), EditorUtility.FormatBytes (inspectorSize)));
        }
    }

    public class OptimizeAnimationClipTool
    {
        private const string optConfigPath = "Packages/com.funplus.dragonreborn.assettool@0.0.1/Editor/AnimationTool/AnimOptConfig.json";

        static List<AnimationOpt> _AnimOptList = new List<AnimationOpt> ();
        static List<string> _Errors = new List<string>();
        static int _Index = 0;

        private class AnimOptConfig
        {
            public uint precision;
            public List<string> optDir;
        }

        private static List<AnimOptConfig> animOptConfigs;
        
        private static bool InitAnimOptConfigs()
        {
            if (!File.Exists(optConfigPath))
            {
                return false;
            }
            var json = File.ReadAllText(optConfigPath);
            animOptConfigs = DataUtils.FromJson<List<AnimOptConfig>>(json);
            return true;
        }

        private static void ScanAnimationClip()
        {
            AnimationOpt _AnimOpt = _AnimOptList[_Index];
            bool isCancel = EditorUtility.DisplayCancelableProgressBar("优化AnimationClip", _AnimOpt.path, (float)_Index / (float)_AnimOptList.Count);
            _AnimOpt.Optimize();
            _Index++;
            if (isCancel || _Index >= _AnimOptList.Count)
            {
                EditorUtility.ClearProgressBar();
                Debug.Log(string.Format("--优化完成--    错误数量: {0}    总数量: {1}/{2}    错误信息↓:\n{3}\n----------输出完毕----------", _Errors.Count, _Index, _AnimOptList.Count, string.Join(string.Empty, _Errors.ToArray())));
                Resources.UnloadUnusedAssets();
                GC.Collect();
                AssetDatabase.SaveAssets();
                EditorApplication.update = null;
                _AnimOptList.Clear();
                _cachedOpts.Clear ();
                _Index = 0;
            }
        }

        private static Dictionary<string, AnimationOpt> _cachedOpts = new Dictionary<string, AnimationOpt>();

        static AnimationOpt _GetNewAOpt(string path, uint precision)
        {
            AnimationOpt opt = null;
            if (!_cachedOpts.ContainsKey(path)) {
                AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip> (path);
                if (clip != null)
                {
                    opt = new AnimationOpt(path, clip, precision);
                    _cachedOpts [path] = opt;
                }
            }
            return opt;
        }
        
        static List<AnimationOpt> FindAllAnims()
        {
            string projectPath = Application.dataPath;
            List<string> listClipPaths = new List<string>();
            List<string> allClipPaths = new List<string>();
            List<AnimationOpt> assets = new List<AnimationOpt>();
            
            foreach (var config in animOptConfigs)
            {
                if (config.optDir == null || config.optDir.Count == 0)
                {
                    continue;
                }
                
                listClipPaths.Clear();
                
                string[] _guids = null;
                _guids = AssetDatabase.FindAssets("t:" + "AnimationClip", config.optDir.ToArray());
                foreach (string guid in _guids)
                {
                    string source = AssetDatabase.GUIDToAssetPath(guid);
                    string extension = Path.GetExtension(source).ToLower();
                    if (extension == ".fbx" || extension == ".playable")
                    {
                        continue;
                    }

                    if (!allClipPaths.Contains(source))
                    {
                        allClipPaths.Add(source);
                        listClipPaths.Add(source);
                    }
                }
                
                for (int i = 0; i < listClipPaths.Count; i++)
                {
                    AnimationOpt animopt = _GetNewAOpt(listClipPaths[i], config.precision);
                    if (animopt != null)
                    {
                        assets.Add(animopt);
                    }
                }
            }
            
            return assets;
        }

        private static AnimOptConfig GetOptConfigByPath(string path)
        {
            if (animOptConfigs == null)
            {
                InitAnimOptConfigs();
            }

            foreach (var config in animOptConfigs)
            {
                foreach (var dir in config.optDir)
                {
                    if (path.StartsWith(dir))
                    {
                        return config;
                    }
                }
            }

            return null;
        }
        
        public static void OptimizeAnimationClip(string path, AnimationClip clip)
        {
            AnimOptConfig optConfig = GetOptConfigByPath(path);
            if (optConfig == null)
            {
                return;
            }

            AnimationOpt opt = new AnimationOpt(path, clip, optConfig.precision);
            opt.Optimize();
        }

        [MenuItem("DragonReborn/资源工具箱/动画工具/批量压缩动画文件精度")]
        public static void OptimizeAll()
        {
            if (!InitAnimOptConfigs())
            {
                Debug.LogError("InitAnimOptConfigs failed!");
                return;
            }

            _AnimOptList = FindAllAnims();

            if (_AnimOptList.Count > 0)
            {
	            _Index = 0;
                _Errors.Clear();
                EditorApplication.update = ScanAnimationClip;
            }
        }
    }
}
