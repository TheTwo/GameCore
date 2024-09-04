#if USE_UNI_LUA
using LuaAPI = UniLua.Lua;
using RealStatePtr = UniLua.ILuaState;
using LuaCSFunction = UniLua.CSharpFunctionDelegate;
#else
using System;
#if CHECK_XLUA_API_CALL_ENABLE
using LuaAPI = XLua.LuaDLL.LuaDLLWrapper;
#else
using LuaAPI = XLua.LuaDLL.Lua;
#endif
using RealStatePtr = System.IntPtr;
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;
#endif
namespace XLua
{
    public partial class LuaFunction
    {
        public void Action()
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            int error = LuaAPI.lua_pcall(L, 0, 0, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            LuaAPI.lua_settop(L, oldTop);
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public void Action<T1, T2, T3>(T1 a1, T2 a2, T3 a3)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            translator.PushByType(L, a1);
            translator.PushByType(L, a2);
            translator.PushByType(L, a3);
            int error = LuaAPI.lua_pcall(L, 3, 0, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            LuaAPI.lua_settop(L, oldTop);
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public void Action<T1, T2, T3, T4>(T1 a1, T2 a2, T3 a3, T4 a4)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            translator.PushByType(L, a1);
            translator.PushByType(L, a2);
            translator.PushByType(L, a3);
            translator.PushByType(L, a4);
            int error = LuaAPI.lua_pcall(L, 4, 0, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            LuaAPI.lua_settop(L, oldTop);
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public void Action<T1, T2, T3, T4, T5>(T1 a1, T2 a2, T3 a3, T4 a4, T5 a5)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            translator.PushByType(L, a1);
            translator.PushByType(L, a2);
            translator.PushByType(L, a3);
            translator.PushByType(L, a4);
            translator.PushByType(L, a5);
            int error = LuaAPI.lua_pcall(L, 5, 0, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            LuaAPI.lua_settop(L, oldTop);
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public void Action<T1, T2, T3, T4, T5, T6>(T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            translator.PushByType(L, a1);
            translator.PushByType(L, a2);
            translator.PushByType(L, a3);
            translator.PushByType(L, a4);
            translator.PushByType(L, a5);
            translator.PushByType(L, a6);
            int error = LuaAPI.lua_pcall(L, 3, 0, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            LuaAPI.lua_settop(L, oldTop);
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public TResult Func<TResult>()
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);            
            int error = LuaAPI.lua_pcall(L, 0, 1, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            TResult ret;
            try
            {
                translator.Get(L, -1, out ret);
            }
            catch (Exception e)
            {
                throw e;
            }
            finally
            {
                LuaAPI.lua_settop(L, oldTop);
            }
            return ret;
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public TResult Func<T1, T2, T3, TResult>(T1 a1, T2 a2, T3 a3)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            translator.PushByType(L, a1);
            translator.PushByType(L, a2);
            translator.PushByType(L, a3);
            int error = LuaAPI.lua_pcall(L, 3, 1, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            TResult ret;
            try
            {
                translator.Get(L, -1, out ret);
            }
            catch (Exception e)
            {
                throw e;
            }
            finally
            {
                LuaAPI.lua_settop(L, oldTop);
            }
            return ret;
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }

        public TResult Func<T1, T2, T3, T4, T5, TResult>(T1 a1, T2 a2, T3 a3, T4 a4, T5 a5)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
                var L = luaEnv.L;
                var translator = luaEnv.translator;
                int oldTop = LuaAPI.lua_gettop(L);
                int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
                LuaAPI.lua_getref(L, luaReference);
                translator.PushByType(L, a1);
                translator.PushByType(L, a2);
                translator.PushByType(L, a3);
                translator.PushByType(L, a4);
                translator.PushByType(L, a5);
                int error = LuaAPI.lua_pcall(L, 5, 1, errFunc);
                if (error != 0)
                    luaEnv.ThrowExceptionFromError(oldTop);
                TResult ret;
                try
                {
                    translator.Get(L, -1, out ret);
                }
                catch (Exception e)
                {
                    throw e;
                }
                finally
                {
                    LuaAPI.lua_settop(L, oldTop);
                }
                return ret;
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }

        public void Func<R1, R2, R3>(LuaTable tbl, out R1 r1, out R2 r2, out R3 r3)
        {
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(luaEnv.luaEnvLock); lock (luaEnv.luaEnvLock)
            {
#endif
            var L = luaEnv.L;
            var translator = luaEnv.translator;
            int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, luaEnv.errorFuncRef);
            LuaAPI.lua_getref(L, luaReference);
            translator.PushByType(L, tbl);
            int error = LuaAPI.lua_pcall(L, 1, 3, errFunc);
            if (error != 0)
                luaEnv.ThrowExceptionFromError(oldTop);
            try
            {
                translator.Get(L, -3, out r1);
                translator.Get(L, -2, out r2);
                translator.Get(L, -1, out r3);
            }
            catch (Exception e)
            {
                throw e;
            }
            finally
            {
                LuaAPI.lua_settop(L, oldTop);
            }
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }
        
        public void PrintFunction()
        {
            var function = this;
            var env = function.luaEnv;
            var L = env.L;
            // int oldTop = LuaAPI.lua_gettop(L);
            int errFunc = LuaAPI.load_error_func(L, env.errorFuncRef);
            LuaAPI.xlua_getglobal(L, "debug");
            LuaAPI.lua_pushstring(L, "getinfo");
            LuaAPI.xlua_pgettable(L, -2);
            LuaAPI.lua_getref(L, function.Ref);
            LuaAPI.lua_pushstring(L, "nS");
            LuaAPI.lua_pcall(L, 2, 1, errFunc);
            var info = new LuaTable(LuaAPI.luaL_ref(L), env);
            var source = info.Get<string>("source");
            var line = info.Get<string>("linedefined");
            UnityEngine.Debug.Log($"{source} : {line}");
        }
    }
}