/********************************************************************************/
/* 严重警告：不要随意修改这个基类，否则可能导致严重的性能问题！
/********************************************************************************/

using System;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace DragonReborn
{
    public static class LuaCleanupHelper
    {
        private static readonly HashSet<ILuaCleanup> AliveSet = new();

        internal static void OnQuit()
        {
            foreach (var luaCleanup in AliveSet)
            {
                luaCleanup.Cleanup();
            }
            AliveSet.Clear();
        }

        public static bool Add(ILuaCleanup toTrack)
        {
            return AliveSet.Add(toTrack);
        }
        
        public static bool Remove(ILuaCleanup unTrack)
        {
            return AliveSet.Remove(unTrack);
        }
    }

    public interface ILuaCleanup
    {
        void Cleanup();
    }
    
    public class LuaBehaviour : MonoBehaviour, IUpdater
    {
        [SerializeField] [HideInInspector] public string scriptName;
        [SerializeField] [HideInInspector] public string schemaName;
        [SerializeReference] [HideInInspector] public LuaSerializedObject serializedObject = new LuaSerializedObject();
        
        private LuaTable _instance;
        private Action<LuaTable> _awake;
        private Action<LuaTable> _start;
        private Action<LuaTable> _update;
        private Action<LuaTable> _lateUpdate;
        private Action<LuaTable> _enable;
        private Action<LuaTable> _disable;

        private static readonly HashSet<LuaBehaviour> AliveSet = new HashSet<LuaBehaviour>();


        internal static void OnQuit()
        {
	        foreach (var luaBehaviour in AliveSet)
	        {
		        luaBehaviour.Cleanup();
	        }


	        AliveSet.Clear();
            LuaCleanupHelper.OnQuit();
        }

        public LuaSchemaSlot SlotTreeRoot { get; set; } = new LuaSchemaSlot();

        public LuaTable Instance
        {
            get
            {
                if (Application.isPlaying)
                {
                    Awake();
                }
                
                return _instance;
            }
        }

        protected LuaTable InternalGetLuaInstance => _instance;

        protected virtual void OnBeforeLuaAwake()
        {
            
        }

        internal void Awake()
        {
            if (_instance != null)
                return;

            if (!ScriptEngine.Initialized)
	            return;
            
            LoadScript();
            LoadSchema();

            LuaBehaviourUtils.Populate(_instance, SlotTreeRoot,  serializedObject);

            OnBeforeLuaAwake();
            
            _awake?.Invoke(_instance);
            AliveSet.Add(this);
        }

        private void Start()
        {
            _start?.Invoke(_instance);
        }

        public void DoUpdate()
        {
            _update?.Invoke(_instance);
        }

        public void DoLateUpdate()
        {
            _lateUpdate?.Invoke(_instance);
        }

        private void OnEnable()
        {
            _enable?.Invoke(_instance);
            Updater.Add(this);
        }

        private void OnDisable()
        {
            _disable?.Invoke(_instance);
            Updater.Remove(this);
        }

        private void OnDestroy()
        {
            if(AliveSet.Contains(this))
            {
	            Cleanup();
                AliveSet.Remove(this);
            }
        }
        
        protected virtual void Cleanup()
        {
	        _instance?.Dispose();
            _instance = null;
            _awake = null;
            _start = null;
            _update = null;
            _lateUpdate = null;
            _enable = null;
            _disable = null;

            if (ScriptEngine.Initialized)
            {
	            ScriptEngine.Instance.ReleaseCSharpObject(this);
            }
        }
        
        protected virtual bool LoadScript()
        {
            if (string.IsNullOrEmpty(scriptName))
            {
                return false;
            }
            
            try
            {
                // _instance = ScriptEngine.Instance.LuaInstance.CreateLuaClassInstance(this);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat(this, "[LuaBehaviour]LoadScript:{0} on Go:{1},Error = {2}", scriptName, gameObject.name, e);
                return false;
            }
            
            _instance?.Set("behaviour", this);
            _instance?.Get("Awake", out _awake);
            _instance?.Get("Start", out _start);
            _instance?.Get("Update", out _update);
            _instance?.Get("LateUpdate", out _lateUpdate);
            _instance?.Get("OnEnable", out _enable);
            _instance?.Get("OnDisable", out _disable);

            return true;
        }

        private void LoadSchema()
        {
            SlotTreeRoot = new LuaSchemaSlot();

            if (string.IsNullOrEmpty(schemaName))
            {
                return;
            }

            // // var results = ScriptEngine.Instance.LuaInstance.CreateLuaSchema(this);
            // if (results is not { Length: > 0 })
            // {
            //     return;
            // }
            //
            // LuaBehaviourUtils.GetSchemaSlotTree(results[0] as LuaTable, null, SlotTreeRoot.Children, schemaName);
        }
	}
}
