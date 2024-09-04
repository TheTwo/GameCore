using System;
using System.Collections;
using System.Collections.Generic;
#if USE_UNI_LUA
using LuaAPI = UniLua.Lua;
using RealStatePtr = UniLua.ILuaState;
using LuaCSFunction = UniLua.CSharpFunctionDelegate;
#else
#if CHECK_XLUA_API_CALL_ENABLE
using LuaAPI = XLua.LuaDLL.LuaDLLWrapper;
#else
using LuaAPI = XLua.LuaDLL.Lua;
#endif
using RealStatePtr = System.IntPtr;
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;
#endif

#if UNITY_EDITOR && !XLUA_GENERAL
// ReSharper disable once CheckNamespace
namespace XLua
{

    public partial class ObjectTranslator
    {
        private static INotAccessGenTypeChecker _iChecker;
        private static bool _setFlag;
        
        public static void RegisterTypeChecker(INotAccessGenTypeChecker checker)
        {
            _iChecker = checker;
        }

        private static void RecordNotAccessGenType(System.Type type)
        {
            _iChecker?.AddRecord(type);
        }
        
        public interface INotAccessGenTypeChecker
        {
            void AddRecord(System.Type type);
        }

        [UnityEngine.RuntimeInitializeOnLoadMethod(UnityEngine.RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void OnGameStart()
        {
            _iChecker = null;
            var m = UnityEditor.TypeCache.GetMethodsWithAttribute<NotAccessGenTypeCheckerCallAttribute>();
            if (m.Count <= 0) return;
            foreach (var info in m)
            {
                if (!info.IsStatic) continue;
                info.Invoke(null, null);
            }
        }

        public class NotAccessGenTypeCheckerCallAttribute : System.Attribute
        {
        }
    }
}
#endif