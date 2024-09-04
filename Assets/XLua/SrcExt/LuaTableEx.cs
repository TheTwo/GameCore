using System;
using System.Collections.Generic;
using System.Text;
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
    public partial class LuaTable
    {
        public object Cast(Type typ)
        {
            var L = luaEnv.L;
            var translator = luaEnv.translator;
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
                push(L);
                object ret = translator.GetObject(L, -1, typ);
                LuaAPI.lua_pop(luaEnv.L, 1);
                return ret;
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }

        /// <summary>
        /// unsafe when multi-threads invoke
        /// </summary>
        public LuaFunction FastGetFunction(string key)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
	        LockUtils.CheckLock(luaEnv.luaEnvLock);
	        lock (luaEnv.luaEnvLock)
#endif
	        {
		        var L = luaEnv.L;
		        var translator = luaEnv.translator;
		        int oldTop = LuaAPI.lua_gettop(L);
		        LuaAPI.lua_getref(L, luaReference);
		        LuaAPI.lua_pushstring(L, key);

		        if (0 != LuaAPI.xlua_pgettable(L, -2))
		        {
			        string err = LuaAPI.lua_tostring(L, -1);
			        LuaAPI.lua_settop(L, oldTop);
			        throw new Exception("get field [" + key + "] error:" + err);
		        }

		        if (!LuaAPI.lua_isfunction(L, -1))
		        {
			        LuaAPI.lua_settop(L, oldTop);
			        return null;
		        }

		        var ret = new LuaFunction(LuaAPI.luaL_ref(L), translator.luaEnv);
		        LuaAPI.lua_settop(L, oldTop);
		        return ret;
	        }
        }

        private static readonly byte[] clear = Encoding.UTF8.GetBytes("clear");
        
        public void Clear()
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
#endif
            {

                var L = luaEnv.L;
                var oldTop = LuaAPI.lua_gettop(L);
                int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
                LuaAPI.xlua_getglobal(L, "table");
                LuaAPI.xlua_pushlstring(L, clear, clear.Length);
                LuaAPI.xlua_pgettable(L, -2);
                LuaAPI.lua_getref(L, luaReference);
                int error = LuaAPI.lua_pcall(L, 1, 1, errFunc);
                if (error != 0)
                    luaEnv.ThrowExceptionFromError(oldTop);
                LuaAPI.lua_pop(L, 1);
                LuaAPI.lua_settop(L, oldTop);
            }
        }

        private static readonly byte[] insert = Encoding.UTF8.GetBytes("insert");

        public void AddRange<TValue>(IEnumerable<TValue> values)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
#endif
            {

                var L = luaEnv.L;
                var translator = luaEnv.translator;
                var oldTop = LuaAPI.lua_gettop(L);
                int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
                foreach (var value in values)
                {
                    LuaAPI.xlua_getglobal(L, "table");
                    LuaAPI.xlua_pushlstring(L, insert, insert.Length);
                    LuaAPI.xlua_pgettable(L, -2);
                    LuaAPI.lua_getref(L, luaReference);
                    translator.PushByType(L, value);
                    int error = LuaAPI.lua_pcall(L, 2, 1, errFunc);
                    if (error != 0)
                        luaEnv.ThrowExceptionFromError(oldTop);
                    LuaAPI.lua_pop(L, 1);
                }
                LuaAPI.lua_settop(L, oldTop);
            }
        }
    }
}