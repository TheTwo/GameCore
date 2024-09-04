#if USE_UNI_LUA
using LuaAPI = UniLua.Lua;
#else
#if CHECK_XLUA_API_CALL_ENABLE
using LuaAPI = XLua.LuaDLL.LuaDLLWrapper;
#else
using LuaAPI = XLua.LuaDLL.Lua;
#endif
#endif

namespace XLua
{
    public partial class LuaEnv
    {
#if UNITY_EDITOR
	    [DragonReborn.ManuelWriteLibraryFunction("physics", "raycastnonalloc"
		    , typeof(UnityEngine.Ray), "ray", typeof(float), "maxDistance", typeof(int), "layerMask"
		    , typeof(int), typeof(LuaTable))]
	    [DragonReborn.ManuelWriteLibraryFunction("physics", "boxcastNonAlloc"
		    , typeof(UnityEngine.Vector3), "origin"
		    , typeof(UnityEngine.Vector3), "halfExtents"
		    , typeof(UnityEngine.Vector3), "direction"
		    , typeof(UnityEngine.Quaternion), "orientation"
		    , typeof(float), "maxDistance"
		    , typeof(int), "layerMask"
		    , typeof(int), typeof(LuaTable))]
#endif
	    public void OpenSsrLib_Physics()
        {
            LuaAPI.lua_newtable(L);
            LuaAPI.xlua_pushasciistring(L, "raycastnonalloc");
            LuaAPI.lua_pushstdcallcfunction(L, RaycastHelper.RaycastNonAlloc);
            LuaAPI.lua_rawset(L, -3);
            LuaAPI.xlua_pushasciistring(L, "boxcastNonAlloc");
            LuaAPI.lua_pushstdcallcfunction(L, RaycastHelper.BoxcastNonAlloc);
            LuaAPI.lua_rawset(L, -3);
            if (LuaAPI.xlua_setglobal(L, "physics") != 0)
            {
	            DragonReborn.NLogger.Error("Load Lib Failed");
            }
        }

        public void OpenSsrLib_Debug()
        {
            if (0 != LuaAPI.xlua_getglobal(L, "debug"))
            {
                throw new System.Exception("call xlua_getglobal fail!" + LuaAPI.lua_tostring(L, -1));
            }
            LuaAPI.xlua_pushasciistring(L, "printfunc");
            LuaAPI.lua_pushstdcallcfunction(L, StaticLuaCallbacks.PrintFunction);
            LuaAPI.lua_rawset(L, -3);
            LuaAPI.xlua_pushasciistring(L, "printdelegate");
            LuaAPI.lua_pushstdcallcfunction(L, StaticLuaCallbacks.PrintDelegateWrapFunction);
            LuaAPI.lua_rawset(L, -3);
            LuaAPI.xlua_pushasciistring(L, "manual_crush");
            LuaAPI.lua_pushstdcallcfunction(L, StaticLuaCallbacks.ManualCrush);
            LuaAPI.lua_rawset(L, -3);
            LuaAPI.xlua_pushasciistring(L, "manual_stackoverflow");
            LuaAPI.lua_pushstdcallcfunction(L, StaticLuaCallbacks.ManualStackOverflow);
            LuaAPI.lua_rawset(L, -3);
            LuaAPI.lua_pop(L, 1);
        }
        
#if UNITY_EDITOR
        [DragonReborn.ManuelWriteLibraryFunction("ssr", "update_finish")]
#endif
        public void OpenSsrLib_HotReloadMark()
        {
	        LuaAPI.lua_newtable(L);
	        LuaAPI.xlua_pushasciistring(L, "update_finish");
	        LuaAPI.lua_pushstdcallcfunction(L, ScriptEngine.HotReloadFinish);
	        LuaAPI.lua_rawset(L, -3);
	        if (LuaAPI.xlua_setglobal(L, "ssr") != 0)
	        {
		        DragonReborn.NLogger.Error("Load Lib Failed");
	        }
        }
        
#if UNITY_EDITOR
        [DragonReborn.ManuelWriteLibraryFunction(nameof(IOUtilsWrap), nameof(IOUtilsWrap.ReadStreamingAssetAsText), typeof(string), "relativePath", typeof(string))]
        [DragonReborn.ManuelWriteLibraryFunction(nameof(IOUtilsWrap), nameof(IOUtilsWrap.ReadGameAssetAsText), typeof(string), "relativePath", typeof(string))]
        [DragonReborn.ManuelWriteLibraryFunction(nameof(IOUtilsWrap), nameof(IOUtilsWrap.ReadTextAsLuaJsonObject), typeof(DragonReborn.AssetTool.AssetManager), "assetMgr", typeof(LuaFunction), "jsonDecode", typeof(string), "textPath", typeof(DragonReborn.AssetTool.AssetManager.SyncLoadReason), "reason", typeof(LuaTable))]
#endif
        public void OpenSsrLib_IOUtilsReadTextFile()
        {
	        LuaAPI.lua_newtable(L);
	        LuaAPI.xlua_pushasciistring(L, nameof(IOUtilsWrap.ReadStreamingAssetAsText));
	        LuaAPI.lua_pushstdcallcfunction(L, IOUtilsWrap.ReadStreamingAssetAsText);
	        LuaAPI.lua_rawset(L, -3);
	        LuaAPI.xlua_pushasciistring(L, nameof(IOUtilsWrap.ReadGameAssetAsText));
	        LuaAPI.lua_pushstdcallcfunction(L, IOUtilsWrap.ReadGameAssetAsText);
	        LuaAPI.lua_rawset(L, -3);
	        LuaAPI.xlua_pushasciistring(L, nameof(IOUtilsWrap.ReadTextAsLuaJsonObject));
	        LuaAPI.lua_pushstdcallcfunction(L, IOUtilsWrap.ReadTextAsLuaJsonObject);
	        LuaAPI.lua_rawset(L, -3);
	        if (LuaAPI.xlua_setglobal(L, "IOUtilsWrap") != 0)
	        {
		        DragonReborn.NLogger.Error("Load Lib Failed");
	        }
        }

#if UNITY_EDITOR
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.Alloc), typeof(int), "size", typeof(long))]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.GetLocalPosition), typeof(long), "target", typeof(long))]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.Seek), typeof(long), "target", typeof(long), "offset", typeof(System.IO.SeekOrigin), "loc")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.Free), typeof(long), "target")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteChar), typeof(long), "target", typeof(char), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteSByte), typeof(long), "target", typeof(sbyte), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteByte), typeof(long), "target", typeof(byte), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", "WriteBoolean", typeof(long), "target", typeof(bool), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteUInt16), typeof(long), "target", typeof(ushort), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteInt16), typeof(long), "target", typeof(short), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteUInt32), typeof(long), "target", typeof(uint), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteInt32), typeof(long), "target", typeof(int), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteUInt64), typeof(long), "target", typeof(ulong), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteInt64), typeof(long), "target", typeof(long), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteFloat), typeof(long), "target", typeof(float), "value")]
        [DragonReborn.ManuelWriteLibraryFunction("Unmanaged", nameof(DragonReborn.Utilities.UnmanagedMemoryHelper.WriteDouble), typeof(long), "target", typeof(double), "value")]
#endif
        public void OpenSsrLib_UnmanagedMemoryHelper()
        {
	        DragonReborn.Utilities.UnmanagedMemoryHelperWrap.Register(L);
        }

        public string TraceBack()
        {
	        int oldTop = LuaAPI.lua_gettop(L);
	        int errFunc = LuaAPI.load_error_func(L, errorFuncRef);
	        LuaAPI.xlua_getglobal(L, "debug");
	        LuaAPI.lua_pushstring(L, "traceback");
	        LuaAPI.xlua_pgettable(L, -2);
	        LuaAPI.lua_pcall(L, 0, 1, errFunc);
	        string traceback = LuaAPI.lua_tostring(L, -1);
	        LuaAPI.lua_settop(L, oldTop);
	        return traceback;
        }

#if UNITY_EDITOR
        [DragonReborn.ManuelWriteLibraryFunction("streamhandle", "new", "streamhandle")]
        [DragonReborn.ManuelWriteLibraryFunction("streamhandle", "readbyte", "streamhandle", "self", "number")]
        [DragonReborn.ManuelWriteLibraryFunction("streamhandle", "writebyte", "streamhandle", "self", "number", "value")]
#endif
        private static void Dummy()
        {}
    }
}