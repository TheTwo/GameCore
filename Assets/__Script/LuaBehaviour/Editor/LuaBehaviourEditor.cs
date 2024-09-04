#define USE_SHARED_FILE_WATCHER
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Reflection.Emit;
using System.Threading;
using Newtonsoft.Json;
using UnityEditor;
using UnityEngine;
using XLua;
using Object = UnityEngine.Object;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public delegate bool ShouldLuaBehaviourFieldPresent(LuaSchemaSlot slot, LuaBehaviour target, LuaTable instance,
        LuaSerializedObject so, int level);
    
    [CustomEditor(typeof(LuaBehaviour), true)]
    public class LuaBehaviourEditor : UnityEditor.Editor
    {
        private const string ValueFieldName = "value";
        private static readonly ModuleBuilder EditorModule;
        private static readonly Dictionary<Type, Type> EditorWrapperTypes = new();

        static LuaBehaviourEditor()
        {
            var myDomain = Thread.GetDomain();
            var myAsmName = new AssemblyName {Name = "LuaBehaviourEditor"};
            var myAsmBuilder = myDomain.DefineDynamicAssembly(myAsmName, AssemblyBuilderAccess.RunAndSave);
            EditorModule = myAsmBuilder.DefineDynamicModule("LuaBehaviourEditorModule", "LuaBehaviourEditor.dll");
        }

        private byte[] _script;
        private byte[] _schema;

        private bool _dirty;
#if USE_SHARED_FILE_WATCHER
        private IDisposable _watcherHandle;
#else
        private FileSystemWatcher _watcher;
#endif
        
        protected LuaBehaviour Behaviour { get; private set; }

        private void OnEnable()
        {
            Behaviour = target as LuaBehaviour;
            Undo.undoRedoPerformed = OnUndoRedoPerformed;
            UpdateScriptAndSchema();

            Behaviour!.SlotTreeRoot = ReloadSchemaTree(Behaviour.schemaName, _schema, Behaviour.SlotTreeRoot,
                Behaviour.serializedObject);

            _dirty = false;

            EditorApplication.update += Update;
            
            CreateFileSystemWatcher();
        }

        private void OnDisable()
        {
            Undo.undoRedoPerformed = null;
            DestroyFileSystemWatcher();
            EditorApplication.update -= Update;
        }

        private void OnUndoRedoPerformed()
        {
            UpdateScriptAndSchema();
            Behaviour.SlotTreeRoot = ReloadSchemaTree(Behaviour.schemaName, _schema, Behaviour.SlotTreeRoot,
                Behaviour.serializedObject);
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            
            //绘制需要选择的脚本
            DrawScriptAndSchemaFields();

            //绘制所有需要注入的对象
            var dirty = DrawSchemaSlotTree(Behaviour.SlotTreeRoot, Behaviour, Behaviour.Instance,
                Behaviour.serializedObject, 0, null);

            if (dirty)
            {
                EditorUtility.SetDirty(Behaviour);
            }
        }

        protected void DrawScriptAndSchemaFields()
        {
            // 选择执行脚本文件
            var oldColor = GUI.backgroundColor;
            if (!string.IsNullOrEmpty(Behaviour.scriptName) && _script == null)
            {
                GUI.backgroundColor = Color.red;
            }

            var newScriptName = EditorGUILayout.TextField("Script", Behaviour.scriptName);
            if (Behaviour.scriptName != newScriptName)
            {
                Undo.RecordObject(Behaviour, "Script Change");
                
                Behaviour.scriptName = newScriptName;

                _script = LuaBehaviourEditorUtils.FindTextAsset(Behaviour.scriptName);
            }

            GUI.backgroundColor = oldColor;

            if (!string.IsNullOrEmpty(Behaviour.schemaName) && _schema == null)
            {
                GUI.backgroundColor = Color.red;
            }

            // 选择数据定义文件
            var newSchemaName = EditorGUILayout.TextField("Schema", Behaviour.schemaName);
            if (Behaviour.schemaName != newSchemaName)
            {
                Undo.RecordObject(Behaviour, "Schema Change");
                Behaviour.schemaName = newSchemaName;

                _schema = LuaBehaviourEditorUtils.FindTextAsset(Behaviour.schemaName);
                Behaviour.SlotTreeRoot = ReloadSchemaTree(Behaviour.schemaName, _schema, Behaviour.SlotTreeRoot, Behaviour.serializedObject);
            }

            GUI.backgroundColor = oldColor;
        }

        private void UpdateScriptAndSchema()
        {
            _script = LuaBehaviourEditorUtils.FindTextAsset(Behaviour.scriptName);
            _schema = LuaBehaviourEditorUtils.FindTextAsset(Behaviour.schemaName);
        }

        protected static bool DrawSchemaSlotTree(LuaSchemaSlot treeRoot, LuaBehaviour target,
            LuaTable instance, LuaSerializedObject serializedObject, int level, ShouldLuaBehaviourFieldPresent callback)
        {
            bool dirty = false;
            foreach (var slot in treeRoot.Children)
            {
                if (callback != null && !callback(slot, target, instance, serializedObject, level))
                {
                    continue;
                }
                
                switch (slot.SlotType)
                {
                    case LuaSchemaSlotType.Table:
                    {
                        dirty |= DrawSchemaObjectField(slot, target, instance, serializedObject.children, level, callback);
                        break;
                    }
                    
                    case LuaSchemaSlotType.List:
                    {
                        dirty |= DrawListObjectField(slot, target, instance, serializedObject.objectArray, level);
                        break;
                    }

                    case LuaSchemaSlotType.Object:
                    {
                        dirty |= DrawObjectField(slot, target, instance, serializedObject.objects, level);
                        break;
                    }
            
                    case LuaSchemaSlotType.Value:
                    {
                        dirty |= DrawValueField(slot, target, instance, serializedObject.values, level);
                        break;
                    }

                    case LuaSchemaSlotType.Enum:
                    {
                        dirty |= DrawEnumField(slot, target, instance, serializedObject.values, level);
                        break;
                    }
                }
            }

            return dirty;
        }

        private static bool DrawSchemaObjectField(LuaSchemaSlot slot, LuaBehaviour target, LuaTable instance,
            IEnumerable<LuaSerializedObject> children, int level, ShouldLuaBehaviourFieldPresent callback)
        {
            var dirty = false;
            var o = FindSerializedObject(slot.Name, children);

            LuaTable result = null;
            if (Application.isPlaying)
            {
                instance?.Get(slot.Name, out result);
            }

            EditorGUI.indentLevel += level;
            
            slot.FoldOut = EditorGUILayout.Foldout(slot.FoldOut, slot.MangledName);
            if (slot.FoldOut)
            {
                dirty = DrawSchemaSlotTree(slot, target, result, o, level + 1, callback);
            }

            EditorGUI.indentLevel -= level;
            return dirty;
        }

        private static bool DrawListObjectField(LuaSchemaSlot slot, LuaBehaviour target, LuaTable instance,
            IEnumerable<LuaSerializedProperty<List<Object>>> objects, int level)
        {
            var o = FindSerializedList(slot.Name, objects);
            if (o == null)
            {
                return false;
            }
            
            if (Application.isPlaying)
            {
                instance?.Get(slot.Name, out o.value);
            }
            
            var wrapperType = GetWrapperType(slot.Type);
            var fieldInfo = wrapperType.GetField(ValueFieldName);

            var inst = Activator.CreateInstance(slot.Type);
            var addMethod = slot.Type.GetMethod("Add");
            if (o.value != null)
            {
                foreach (var element in o.value)
                {
                    addMethod?.Invoke(inst, element != null ? new object[] {element} : new object[] {null});
                }
            }
            
            var wrapper = CreateInstance(wrapperType);
            fieldInfo.SetValue(wrapper, inst);

            var so = new SerializedObject(wrapper);
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.PropertyField(so.FindProperty(ValueFieldName), new GUIContent(slot.MangledName));
            var changed = EditorGUI.EndChangeCheck();
            if (changed)
            {
                Undo.RecordObject(target, "Value Change");
            }

            so.ApplyModifiedProperties();
            if (changed)
            {
                var newValue = fieldInfo.GetValue(wrapper) as IEnumerable<Object>;
                inst = Activator.CreateInstance(slot.Type);
                o.value = new List<Object>();
                if (newValue != null)
                {
                    foreach (var element in newValue)
                    {
                        o.value.Add(element);
                        addMethod?.Invoke(inst, new object[] {element});
                    }
                }

                if (Application.isPlaying)
                {
                    instance?.Set(slot.Name, inst);
                }
            }

            EditorGUI.indentLevel -= level;
            return changed;
        }

        private static bool DrawObjectField(LuaSchemaSlot slot, Object target, LuaTable instance,
            IEnumerable<LuaSerializedProperty<Object>> objects, int level)
        {
            var o = FindSerializedProperty(slot.Name, objects);
            if (o == null)
            {
                return false;
            }

            if (Application.isPlaying)
            {
                instance?.Get(slot.Name, out o.value);
            }

            EditorGUI.indentLevel += level;
            var newObject = EditorGUILayout.ObjectField(slot.MangledName, o.value, slot.Type, true);
            var changed = newObject != o.value;
            if (changed)
            {
                Undo.RecordObject(target, "Object Change");
                o.value = newObject;

                if (Application.isPlaying)
                {
                    instance?.Set(slot.Name, o.value);
                }
            }

            EditorGUI.indentLevel -= level;
            return changed;
        }

        private static bool DrawValueField(LuaSchemaSlot slot, Object target, LuaTable instance,
            IEnumerable<LuaSerializedProperty<string>> values, int level)
        {
            var o = FindSerializedProperty(slot.Name, values);
            if (o == null)
            {
                return false;
            }

            if (slot.Name == o.key)
            {
                EditorGUI.indentLevel += level;
                if (Application.isPlaying)
                {
                    object result = null;
                    instance?.Get(slot.Name, out result);
                    result = LuaBehaviourUtils.ChangeType(result, slot.Type);
                    if (result != null)
                    {
                        o.value = JsonConvert.SerializeObject(result, LuaBehaviourUtils.Settings);
                    }
                }

                var wrapperType = GetWrapperType(slot.Type);
                var fieldInfo = wrapperType.GetField(ValueFieldName);

                var wrapper = CreateInstance(wrapperType);
                var value = string.IsNullOrEmpty(o.value)
                    ? LuaBehaviourUtils.GetDefaultValue(slot)
                    : JsonConvert.DeserializeObject(o.value, slot.Type, LuaBehaviourUtils.Settings);

                fieldInfo.SetValue(wrapper, value);

                var so = new SerializedObject(wrapper);
                EditorGUI.BeginChangeCheck();
                EditorGUILayout.PropertyField(so.FindProperty(ValueFieldName), new GUIContent(slot.MangledName));
                var changed = EditorGUI.EndChangeCheck();
                if (changed)
                {
                    Undo.RecordObject(target, "Value Change");
                }

                so.ApplyModifiedProperties();
                if (changed)
                {
                    var newValue = fieldInfo.GetValue(wrapper);
                    o.value = JsonConvert.SerializeObject(newValue, LuaBehaviourUtils.Settings);

                    if (Application.isPlaying)
                    {
                        instance?.Set(slot.Name, newValue);
                    }
                }

                EditorGUI.indentLevel -= level;
                return changed;
            }

            return false;
        }

        private static bool DrawEnumField(LuaSchemaSlot slot, Object target, LuaTable instance,
            IEnumerable<LuaSerializedProperty<string>> values, int level)
        {
            var o = FindSerializedProperty(slot.Name, values);
            if (o == null)
            {
                return false;
            }

            if (slot.Name == o.key)
            {
                EditorGUI.indentLevel += level;
                if (Application.isPlaying)
                {
                    object result = null;
                    instance?.Get(slot.Name, out result);
                    result = LuaBehaviourUtils.ChangeType(result, slot.Type);
                    if (result != null)
                    {
                        o.value = JsonConvert.SerializeObject(result, LuaBehaviourUtils.Settings);
                    }
                }

                var value = string.IsNullOrEmpty(o.value)
                    ? LuaBehaviourUtils.GetDefaultValue(slot)
                    : JsonConvert.DeserializeObject(o.value, slot.Type, LuaBehaviourUtils.Settings);

                var oldIndex = slot.Enum.GetIndex(value != null ? (int)value : 0);

                var newIndex = EditorGUILayout.Popup(slot.MangledName, oldIndex, slot.Enum.GetOptions());
                var changed = newIndex != oldIndex;
                if (changed)
                {
                    Undo.RecordObject(target, "Enum Change");

                    value = slot.Enum.GetValueByIndex(newIndex);
                    o.value = JsonConvert.SerializeObject(value, LuaBehaviourUtils.Settings);

                    if (Application.isPlaying)
                    {
                        instance?.Set(slot.Name, value);
                    }
                }

                EditorGUI.indentLevel -= level;
                return changed;
            }

            return false;
        }

        protected static LuaSerializedProperty<T> FindSerializedProperty<T>(string name,
            IEnumerable<LuaSerializedProperty<T>> objects)
        {
            return objects.FirstOrDefault(o => name == o.key);
        }

        protected static LuaSerializedProperty<T> FindSerializedList<T>(string name, IEnumerable<LuaSerializedProperty<T>> objects)
        {
            return objects.FirstOrDefault(o => name == o.key);
        }

        protected static LuaSerializedObject FindSerializedObject(string name,
            IEnumerable<LuaSerializedObject> objects)
        {
            return objects.FirstOrDefault(o => name == o.key);
        }

        private static Type GetWrapperType(Type type)
        {
            if (EditorWrapperTypes.TryGetValue(type, out var wrapperType))
            {
                return wrapperType;
            }

            var wrapperBuilder = EditorModule.DefineType("LuaBehaviourEditor." + type.FullName,
                TypeAttributes.Public, typeof(ScriptableObject));

            wrapperBuilder.DefineField(ValueFieldName, type, FieldAttributes.Public);
            EditorWrapperTypes[type] = wrapperType = wrapperBuilder.CreateType();
            return wrapperType;
        }


        private static LuaSchemaSlot ReloadSchemaTree(string name, byte[] schema, LuaSchemaSlot oldTreeRoot,
            LuaSerializedObject serializedObject)
        {
            var newTreeRoot = new LuaSchemaSlot();
            
            if (schema != null)
            {
                RebuildSchemaSlotTree(oldTreeRoot.Children, newTreeRoot.Children, schema, name);
                RebuildSerializedObject(newTreeRoot, serializedObject);
            }
            
            return newTreeRoot;
        }

        private static void RebuildSchemaSlotTree(List<LuaSchemaSlot> oldSlots, List<LuaSchemaSlot> newSlots, byte[] code, string schemaName)
        {
#if USE_SHARED_FILE_WATCHER
            if (!LuaEditorShareEnv.instance.DoString(code, out var results))
            {
                return;
            }
            LuaBehaviourUtils.GetSchemaSlotTree(results[0] as LuaTable, oldSlots, newSlots, schemaName);
#else
            LuaEnv env = null;

            if (code == null || code.Length <= 0)
            {
                return;
            }

            try
            {
                env = new LuaEnv();
                env.AddLoader(LoadEditor);

                var results = env.DoString(code);
                if (results == null || results.Length <= 0)
                {
                    return;
                }

                LuaBehaviourUtils.GetSchemaSlotTree(results[0] as LuaTable, oldSlots, newSlots, schemaName);
            }
            catch (Exception e)
            {
                Debug.LogError($"[LuaBehaviourEditor] GetSchemaSlots: {e}");
            }
            finally
            {
                env?.Dispose();
            }
#endif
        }

        private static void RebuildSerializedObject(LuaSchemaSlot treeRoot, LuaSerializedObject serializedObject)
        {
            if (treeRoot == null || serializedObject == null)
            {
                return;
            }
            
            var values = serializedObject.values;
            var objects = serializedObject.objects;
            var children = serializedObject.children;
            var objectArray = serializedObject.objectArray;
            
            serializedObject.values = new List<LuaSerializedProperty<string>>();
            serializedObject.objects = new List<LuaSerializedProperty<Object>>();
            serializedObject.children = new List<LuaSerializedObject>();
            serializedObject.objectArray = new List<LuaSerializedProperty<List<Object>>>();
            
            foreach (var slot in treeRoot.Children)
            {
                switch (slot.SlotType)
                {
                    case LuaSchemaSlotType.Object:
                    {
                        serializedObject.objects.Add(new LuaSerializedProperty<Object>
                        {
                            key = slot.Name,
                            value = GetSerializedProperty(slot.Name, objects)
                        });
                        break;
                    }
            
                    case LuaSchemaSlotType.Value:
                    case LuaSchemaSlotType.Enum:
                    {
                        serializedObject.values.Add(new LuaSerializedProperty<string>
                        {
                            key = slot.Name,
                            value = GetSerializedProperty(slot.Name, values)
                        });
                        break;
                    }
            
                    case LuaSchemaSlotType.Table:
                    {
                        var so = GetSerializedObject(slot.Name, children) ?? new LuaSerializedObject {key = slot.Name};
                        RebuildSerializedObject(slot, so);
                        serializedObject.children.Add(so);
                        break;
                    }

                    case LuaSchemaSlotType.List:
                    {
                        serializedObject.objectArray.Add(new LuaSerializedProperty<List<Object>>
                        {
                            key = slot.Name,
                            value = GetSerializedProperty(slot.Name, objectArray),
                        });
                        break;
                    }
                }
            }
        }

        private static LuaSerializedObject GetSerializedObject(string name, IEnumerable<LuaSerializedObject> objects)
        {
            if (objects == null)
            {
                return default;
            }

            foreach (var value in objects)
            {
                if (value.key == name)
                {
                    return value;
                }
            }

            return default;
        }

        private static T GetSerializedProperty<T>(string name, IEnumerable<LuaSerializedProperty<T>> objects)
        {
            if (objects == null)
            {
                return default;
            }

            foreach (var value in objects)
            {
                if (value.key == name)
                {
                    return value.value;
                }
            }

            return default;
        }

        // ReSharper disable once UnusedMember.Local
        private static byte[] LoadEditor(ref string scriptName)
        {
            try
            {
                return LuaBehaviourEditorUtils.FindTextAsset(scriptName);
            }
            catch (Exception e)
            {
                Debug.LogError($"[LuaBehaviourEditor] Error = {e}");
                return null;
            }
        }
        
        private void CreateFileSystemWatcher()
        {
#if USE_SHARED_FILE_WATCHER
            _watcherHandle?.Dispose();
            _watcherHandle = LuaBehaviourFileWatcher.instance.RegisterEvent(OnCreated, OnRenamed, OnDeleted, OnChanged);
#else
            _watcher?.Dispose();
            var (rootFolder, ext) = LuaBehaviourEditorUtils.GetCurrentRootPath();
            _watcher = new FileSystemWatcher(rootFolder)
            {
                NotifyFilter = NotifyFilters.Attributes
                               | NotifyFilters.CreationTime
                               | NotifyFilters.DirectoryName
                               | NotifyFilters.FileName
                               | NotifyFilters.LastAccess
                               | NotifyFilters.LastWrite
                               | NotifyFilters.Security
                               | NotifyFilters.Size
            };

            _watcher.Created += OnCreated;
            _watcher.Changed += OnChanged;
            _watcher.Deleted += OnDeleted;
            _watcher.Renamed += OnRenamed;

            _watcher.Filter = "*" + ext;
            _watcher.IncludeSubdirectories = true;
            _watcher.EnableRaisingEvents = true;
#endif
        }

        private void OnRenamed(object sender, RenamedEventArgs e)
        {
            TrySetDirty();
        }

        private void OnDeleted(object sender, FileSystemEventArgs e)
        {
            TrySetDirty();
        }

        private void OnChanged(object sender, FileSystemEventArgs e)
        {
            TrySetDirty();
        }

        private void OnCreated(object sender, FileSystemEventArgs e)
        {
            TrySetDirty();
        }

        private void TrySetDirty()
        {
            _dirty = true;
        }

        private void Update()
        {
            OnFileDirty();
        }

        private void OnFileDirty()
        {
            if (!_dirty)
            {
                return;
            }

            _dirty = false;
            
            UpdateScriptAndSchema();

            if (_schema == null)
            {
                return;
            }

            Behaviour.SlotTreeRoot = ReloadSchemaTree(Behaviour.schemaName, _schema, Behaviour.SlotTreeRoot,
                Behaviour.serializedObject);
        }

        private void DestroyFileSystemWatcher()
        {
#if USE_SHARED_FILE_WATCHER
            _watcherHandle?.Dispose();
            _watcherHandle = null;
#else
            _watcher?.Dispose();
            _watcher = null;
#endif
        }
    }
}