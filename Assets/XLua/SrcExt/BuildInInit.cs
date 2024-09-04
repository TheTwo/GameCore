using DragonReborn;
using UnityEngine;

namespace XLua.LuaDLL
{
    using System.Runtime.InteropServices;

    public partial class Lua
    {
        /////////////////////////////////////////////////////////////////////////
        // for watcher
        delegate void LogCallback(int type, System.IntPtr message, int size);
        delegate void BeginSampleCallback(System.IntPtr message, int size);
        delegate void EndSampleCallback();
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        static extern void RegisterCSharpCallback(LogCallback logCallback, 
            BeginSampleCallback beginSample, EndSampleCallback endSample);
        public static void InitWatcher() {
            RegisterCSharpCallback(OnLogCallback, null, null);
        }
        public static void ClearWatcher()
        {
            RegisterCSharpCallback(null, null, null);
        }
        
        enum LogType { Normal, Warning, Error };
        [MonoPInvokeCallback(typeof(LogCallback))]
        static void OnLogCallback(int type, System.IntPtr message, int size) {
            var str = Marshal.PtrToStringAnsi(message, size);
            LogType logType = (LogType) type;
            switch (logType) {
                case LogType.Normal:
                    UnityEngine.Debug.Log(str);
                    break;
                case LogType.Warning:
                    UnityEngine.Debug.LogWarning(str);
                    break;
                case LogType.Error:
                    UnityEngine.Debug.LogError("<color=#ffff00>[watcher]</color> " + str);
                    break;
            }
        }
        [MonoPInvokeCallback(typeof(BeginSampleCallback))]
        static void OnBeginSampleCallback(System.IntPtr message, int size) {
            var str = Marshal.PtrToStringAnsi(message, size);
            UnityEngine.Profiling.Profiler.BeginSample(str);
        }
        [MonoPInvokeCallback(typeof(EndSampleCallback))]
        static void OnEndSampleCallback() {
            UnityEngine.Profiling.Profiler.EndSample();
        }
        
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        static extern void SetUnityFrameCount(int frameCount);

        public static void SetFrameCount(int frameCount)
        {
            SetUnityFrameCount(frameCount);
        }
        
        // lz4
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_lz4(System.IntPtr L);
        [MonoPInvokeCallback(typeof(lua_CSFunction))]
        internal static int LoadLz4(System.IntPtr L)
        {
            return luaopen_lz4(L);
        }
        
        // watcher
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_watcher(System.IntPtr L);
        [MonoPInvokeCallback(typeof(lua_CSFunction))]
        internal static int LoadWatcher(System.IntPtr L)
        {
	        Debug.Log("[Init LuaState] : Load Watcher");
            return luaopen_watcher(L);
        }
        
        // xxhash
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_xxhash(System.IntPtr L);
        [MonoPInvokeCallback(typeof(LuaDLL.lua_CSFunction))]
        internal static int LoadXXHash(System.IntPtr L)
        {
            return luaopen_xxhash(L);
        }
        
        // rapidjson
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_rapidjson(System.IntPtr L);

        [MonoPInvokeCallback(typeof(LuaDLL.lua_CSFunction))]
        public static int LoadRapidJson(System.IntPtr L)
        {            
	        Debug.Log("[Init LuaState] : Load RapidJson");
	        return luaopen_rapidjson(L);
        }
        // for watcher
        /////////////////////////////////////////////////////////////////////////
    }
}