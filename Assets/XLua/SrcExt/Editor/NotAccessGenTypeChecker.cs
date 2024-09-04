#if UNITY_EDITOR && !XLUA_GENERAL
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using DragonReborn;
using DragonReborn.CSharpReflectionTool;
using UnityEditor;
using UnityEditor.Compilation;
using UnityEngine;
using UnityEngine.UIElements;

// ReSharper disable once CheckNamespace
namespace XLua
{
    public class NotAccessGenTypeChecker : ScriptableSingleton<NotAccessGenTypeChecker> , ObjectTranslator.INotAccessGenTypeChecker
    {
        // ReSharper disable InconsistentNaming
        private const string KEY_SHOW_POP_RECEIVE = "NotAccessGenTypeChecker_showPopReceive";
        private const string KEY_CLEAR_ON_PLAY = "NotAccessGenTypeChecker_clearOnPlay";
        
        private const string MENU_KEY = "DragonReborn/XLua/未绑定类型记录窗口";
        private const string MENU_KEY_ON = "DragonReborn/XLua/未绑定类型记录窗口-自动开启";
        // ReSharper restore InconsistentNaming
            
        private static bool _showPopReceive;
        private static bool _clearOnPlay;
            
        private bool _isGuiShow;
        private readonly List<Type> _record = new List<Type>();
        private bool _recordDirty;

        private static readonly HashSet<string> EditorAssemblies = new HashSet<string>();
        private static readonly HashSet<string> EditorPrecompiledAssembliesPath = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private static readonly HashSet<string> FullNameBlackList = new HashSet<string>()
        {
	        "IngameDebugConsole.InGameConsoleInterface",
	        "System.Reflection.RuntimeMethodInfo",
	        "System.RuntimeType",
	        "UnityEngine.GUI",
	        "UnityEngine.GUI+ClipScope",
	        "UnityEngine.GUI+GroupScope",
	        "UnityEngine.GUI+Scope",
	        "UnityEngine.GUI+ScrollViewScope",
	        "UnityEngine.GUI+ToolbarButtonSize",
	        "UnityEngine.GUILayout",
	        "UnityEngine.GUILayout+AreaScope",
	        "UnityEngine.GUILayout+HorizontalScope",
	        "UnityEngine.GUILayout+ScrollViewScope",
	        "UnityEngine.GUILayout+VerticalScope",
	        "UnityEngine.GUILayoutOption",
	        "UnityEngine.GUISkin",
	        "UnityEngine.GUIStyle",
        };

        [InitializeOnLoadMethod]
        private static void OnProjectLoad()
        {
            _showPopReceive = EditorPrefs.GetBool(KEY_SHOW_POP_RECEIVE, false);
            _clearOnPlay = EditorPrefs.GetBool(KEY_CLEAR_ON_PLAY, true);
            EditorAssemblies.Clear();
            EditorAssemblies.UnionWith(CompilationPipeline.GetAssemblies().Where(a=>a.flags == AssemblyFlags.EditorAssembly).Select(a=>a.name));
            EditorPrecompiledAssembliesPath.Clear();
            EditorPrecompiledAssembliesPath.UnionWith(CompilationPipeline.GetPrecompiledAssemblyPaths(CompilationPipeline.PrecompiledAssemblySources
                .UnityEditor).Select(FixPath));
        }

        private static string FixPath(string path)
        {
            var target = System.IO.Path.DirectorySeparatorChar == '/' ? '\\' : '/';
            return path.Replace(target, System.IO.Path.DirectorySeparatorChar);
        }

        [ObjectTranslator.NotAccessGenTypeCheckerCall]
        // ReSharper disable once UnusedMember.Local
        private static void OnGameStart()
        {
            if (_clearOnPlay)
            {
                instance.ClearRecord();
            }
            ObjectTranslator.RegisterTypeChecker(instance);
        }

        [MenuItem(MENU_KEY, false, 32)]
        private static void ShowWindow()
        {
            EditorWindow.GetWindow<NotAccessGenTypeCheckerGUI>(true, "未生成LUA绑定代码的类型").ShowUtility();
        }

        [MenuItem(MENU_KEY, true)]
        private static bool CheckSwitchAutoOpen()
        {
            Menu.SetChecked(MENU_KEY_ON, _showPopReceive);
            return true;
        }

        [MenuItem(MENU_KEY_ON, false, 33)]
        private static void SwitchAutoOpen()
        {
            _showPopReceive = !_showPopReceive;
            EditorPrefs.SetBool(KEY_SHOW_POP_RECEIVE, _showPopReceive);
        }

        public void AddRecord(Type type)
        {
            if (!Application.isPlaying) return;
            if (!FilterForType(type)) return;
            NLogger.WarnChannel("XLuaBindTypeCheck", "Type:{0},{1} 未绑定", type.TypeNameToHandWriteFormat(), type.FullName);
            _record.Add(type);
            _recordDirty = true;
            if (_showPopReceive && !_isGuiShow)
            {
                ShowWindow();
            }
        }

        private void ClearRecord()
        {
            var oldCount = _record.Count;
            _record.Clear();
            if (oldCount != 0)
            {
                _recordDirty = true;
            }
        }
            
        private class NotAccessGenTypeCheckerGUI : EditorWindow
        {
            private ListView _listView;
                
            private void Awake()
            {
                instance._isGuiShow = true;
            }

            private void OnEnable()
            {
                var guiPart = new IMGUIContainer(() =>
                {
                    EditorGUILayout.BeginHorizontal();
                    var b = EditorGUILayout.ToggleLeft("自动打开", _showPopReceive, GUILayout.ExpandWidth(false));
                    if (_showPopReceive != b)
                    {
                        _showPopReceive = b;
                        EditorPrefs.SetBool(KEY_SHOW_POP_RECEIVE, _showPopReceive);
                    }
                    b = EditorGUILayout.ToggleLeft("Play时清理", _clearOnPlay, GUILayout.ExpandWidth(false));
                    if (_clearOnPlay != b)
                    {
                        _clearOnPlay = b;
                        EditorPrefs.SetBool(KEY_CLEAR_ON_PLAY, _clearOnPlay);
                    }
                    if (GUILayout.Button("清空", GUILayout.ExpandWidth(false)))
                    {
                        instance.ClearRecord();
                    }
                    if (GUILayout.Button("生成绑定代码", GUILayout.ExpandWidth(false)))
                    {
                        OutPutToClipboard();
                        ShowNotification(new GUIContent("已经复制到剪贴板"), 2f);
                    }
                    EditorGUILayout.EndHorizontal();
                    GUILayout.FlexibleSpace();
                });
                guiPart.style.height = 16f;
                guiPart.contextType = ContextType.Editor;
                rootVisualElement.Add(guiPart);
                _listView = new ListView(instance._record, 20, () => new Label(), (element, i) =>
                {
                    ((Label)element).text = instance._record[i].FullName;
                })
                {
                    style =
                    {
                        position = Position.Relative,
                        flexGrow = 1f
                    },
                    showAddRemoveFooter = false,
                    showFoldoutHeader = false,
                    showBoundCollectionSize = true,
                    selectionType = SelectionType.None
                };
                rootVisualElement.Add(_listView);
            }

            private void OnDisable()
            {
                _listView = null;
            }

            private void OnDestroy()
            {
                instance._isGuiShow = false;
            }

            private void Update()
            {
                if (!instance._recordDirty) return;
                instance._recordDirty = false;
                _listView.RefreshItems();
                _listView.ScrollToItem(instance._record.Count - 1);
            }
                
            private static void OutPutToClipboard()
            {
                if (instance._record.Count <= 0) return;
                var builder = new StringBuilder();
                var t = new List<Type>(instance._record);
                t.Sort((a,b)=>string.Compare(a.FullName, b.FullName, StringComparison.Ordinal));
                builder.AppendLine("// BEGIN OF GENERATED BIND CODE");
                foreach (var type in t)
                {
                    Debug.Log("go:fullname:" + type.FullName);
                    if (type.IsNotPublic)
                    {
                        builder.AppendFormat("\t\t//look here,not public! typeof({0}),\n", type.TypeNameToHandWriteFormat());
                    }
                    else
                    {
                        builder.AppendFormat("\t\ttypeof({0}),\n", type.TypeNameToHandWriteFormat());
                    }
                }
                builder.AppendLine("// END OF GENERATED BIND CODE");
                GUIUtility.systemCopyBuffer = builder.ToString();
            }
        }

        private static bool FilterForType(Type type)
        {
            switch (type)
            {
                case null:
                case not null when type.IsPrimitive:
                case not null when !type.IsNestedPublic && !type.IsPublic:
                case not null when type.IsGenericType && type.IsGenericTypeDefinition: 
                case not null when Type.GetTypeCode(type) == TypeCode.String:
                case not null when FullNameBlackList.Contains(type.FullName):
                case not null when EditorPrecompiledAssembliesPath.Contains(type.Assembly.Location): 
                case not null when EditorAssemblies.Contains(type.Assembly.GetName().Name):
                case not null when type.GetCustomAttribute<ObsoleteAttribute>() != null:
                    return false;
            }
            return true;
        }
    }
}
#endif