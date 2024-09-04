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

namespace XLua
{
    public partial class StaticLuaCallbacks
    {
        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        public static int PrintFunction(RealStatePtr L)
        {
            try
            {
                int top = LuaAPI.lua_gettop(L);
                if (top == 0)
                    return 0;
                
                if (top > 1)
                    LuaAPI.lua_settop(L, 1);

                if (LuaAPI.lua_isfunction(L, -1))
                {
                    LuaAPI.xlua_getglobal(L, "debug");
                    LuaAPI.lua_pushstring(L, "getinfo");
                    LuaAPI.xlua_pgettable(L, -2);
                    LuaAPI.lua_rotate(L, -3, -1);
                    LuaAPI.lua_pushstring(L, "nS");
                    LuaAPI.lua_pcall(L, 2, 1, -1);
                    ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
                    var env = translator.luaEnv;
                    var info = new LuaTable(LuaAPI.luaL_ref(L), env);
                    var source = info.Get<string>("source");
                    var line = info.Get<string>("linedefined");
                    UnityEngine.Debug.Log($"{source} : {line}");
                    LuaAPI.lua_settop(L, 0);
                }

                return 0;
            }
            catch (LuaStackTraceException e)
            {
                UnityEngine.Debug.LogException(e);
                return LuaAPI.luaL_error(L, "c# exception in PrintFunction: " + e);
            }
            catch (System.Exception e)
            {
                return LuaAPI.luaL_error(L, "c# exception in PrintFunction: " + e);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        public static int PrintDelegateWrapFunction(RealStatePtr L)
        {
            try
            {
                int top = LuaAPI.lua_gettop(L);
                if (top == 0)
                    return 0;
                
                if (top > 1)
                    LuaAPI.lua_settop(L, 1);

                if (LuaAPI.lua_isfunction(L, -1))
                {
                    LuaAPI.xlua_getglobal(L, "debug");
                    LuaAPI.lua_pushstring(L, "getinfo");
                    LuaAPI.xlua_pgettable(L, -2);
                    LuaAPI.lua_getupvalue(L, -3, 1);
                    if (LuaAPI.lua_gettop(L) != 4 || !LuaAPI.lua_isfunction(L, -1))
                    {
                        LuaAPI.lua_settop(L, 0);
                        return 0;
                    }
                    LuaAPI.lua_pushstring(L, "nS");
                    LuaAPI.lua_pcall(L, 2, 1, -1);
                    ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
                    var env = translator.luaEnv;
                    var info = new LuaTable(LuaAPI.luaL_ref(L), env);
                    var source = info.Get<string>("source");
                    var line = info.Get<string>("linedefined");
                    UnityEngine.Debug.Log($"{source} : {line}");
                    LuaAPI.lua_settop(L, 0);
                }

                return 0;
            }
            catch (LuaStackTraceException e)
            {
                UnityEngine.Debug.LogException(e);
                return LuaAPI.luaL_error(L, "c# exception in PrintDelegateWrapFunction: " + e);
            }
            catch (System.Exception e)
            {
                return LuaAPI.luaL_error(L, "c# exception in PrintDelegateWrapFunction: " + e);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        public static int ManualCrush(RealStatePtr L)
        {
	        LuaAPI.lua_ssr_manual_crush(L);
	        return 0;
        }
        
        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        public static int ManualStackOverflow(RealStatePtr L)
        {
	        LuaAPI.lua_ssr_manual_stackoverflow(L);
	        return 0;
        }
    }
}