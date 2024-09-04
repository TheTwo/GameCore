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

// ReSharper disable SuggestVarOrType_BuiltInTypes
// ReSharper disable SuggestVarOrType_SimpleTypes
// ReSharper disable RedundantAttributeSuffix
// ReSharper disable RedundantNameQualifier
// ReSharper disable UnusedMember.Local
// ReSharper disable ArrangeTypeMemberModifiers
// ReSharper disable ConvertToAutoProperty
// ReSharper disable FieldCanBeMadeReadOnly.Local
// ReSharper disable ClassNeverInstantiated.Global
// ReSharper disable IdentifierTypo
// ReSharper disable InconsistentNaming
namespace XLua.CSObjectWrap
{
	public class XLua_Gen_Initer_Register__HandWritten__
	{
		static void Init(LuaEnv luaenv, ObjectTranslator translator)
		{
#if UNITY_ANDROID || UNITY_IOS || UNITY_EDITOR
			translator.DelayWrapLoader(typeof(UnityEngine.Handheld), UnityEngineHandheldWrap.__Register);
#endif
#if UWA_ENABLED_IN_PROJECT && (UNITY_IPHONE || UNITY_ANDROID || UNITY_STANDALONE_WIN)
			translator.DelayWrapLoader(typeof(UWAEngine), UWAEngineWrap.__Register);
#endif
		}

		static XLua_Gen_Initer_Register__HandWritten__()
		{
			XLua.LuaEnv.AddIniter(Init);
		}
	}
}

namespace XLua.CSObjectWrap
{
	using Utils = XLua.Utils;

#if UNITY_ANDROID || UNITY_IOS || UNITY_EDITOR
	public class UnityEngineHandheldWrap
	{
		public static void __Register(RealStatePtr L)
		{
			ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
			System.Type type = typeof(UnityEngine.Handheld);
			Utils.BeginObjectRegister(type, L, translator, 0, 0, 0, 0);
			Utils.EndObjectRegister(type, L, translator, null, null,
				null, null, null);

			Utils.BeginClassRegister(type, L, __CreateInstance, 2, 0, 0);
			Utils.RegisterFunc(L, Utils.CLS_IDX, "Vibrate", _m_Vibrate_xlua_st_);
			Utils.EndClassRegister(type, L, translator);
		}

		[MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
		static int __CreateInstance(RealStatePtr L)
		{
			try
			{
				ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
				if (LuaAPI.lua_gettop(L) == 1)
				{
					UnityEngine.Handheld gen_ret = new UnityEngine.Handheld();
					translator.Push(L, gen_ret);
					return 1;
				}
			}
			catch (System.Exception gen_e)
			{
				var t = ObjectTranslatorPool.Instance.Find(L);
				string traceback = t.luaEnv.TraceBack();
				var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
			}

			return LuaAPI.luaL_error(L, "invalid arguments to UnityEngine.Handheld constructor!");
		}

		[MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
		static int _m_Vibrate_xlua_st_(RealStatePtr L)
		{
			try
			{
				UnityEngine.Handheld.Vibrate();
				return 0;
			}
			catch (System.Exception gen_e)
			{
				var t = ObjectTranslatorPool.Instance.Find(L);
				string traceback = t.luaEnv.TraceBack();
				var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
			}
		}
	}
#endif
	
#if UWA_ENABLED_IN_PROJECT && (UNITY_IPHONE || UNITY_ANDROID || UNITY_STANDALONE_WIN)
	public class UWAEngineWrap 
    {
        public static void __Register(RealStatePtr L)
        {
			ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
			System.Type type = typeof(UWAEngine);
			Utils.BeginObjectRegister(type, L, translator, 0, 0, 0, 0);
			
			
			
			
			
			
			Utils.EndObjectRegister(type, L, translator, null, null,
			    null, null, null);

		    Utils.BeginClassRegister(type, L, __CreateInstance, 17, 1, 0);
			Utils.RegisterFunc(L, Utils.CLS_IDX, "AutoStart", _m_AutoStart_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "StaticInit", _m_StaticInit_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "Start", _m_Start_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "Stop", _m_Stop_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "Tag", _m_Tag_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "Note", _m_Note_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "SetUIActive", _m_SetUIActive_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "Dump", _m_Dump_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "PushSample", _m_PushSample_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "PopSample", _m_PopSample_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "Upload", _m_Upload_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "LogValue", _m_LogValue_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "AddMarker", _m_AddMarker_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "SetOverrideLuaState", _m_SetOverrideLuaState_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "SetOverrideLuaLib", _m_SetOverrideLuaLib_xlua_st_);
            Utils.RegisterFunc(L, Utils.CLS_IDX, "SetOverrideAndroidActivity", _m_SetOverrideAndroidActivity_xlua_st_);
            
			
            
			Utils.RegisterFunc(L, Utils.CLS_GETTER_IDX, "FrameId", _g_get_FrameId);
            
			
			
			Utils.EndClassRegister(type, L, translator);
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int __CreateInstance(RealStatePtr L)
        {
            
			try {
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
				if(LuaAPI.lua_gettop(L) == 1)
				{
					
					UWAEngine gen_ret = new UWAEngine();
					translator.Push(L, gen_ret);
                    
					return 1;
				}
				
			}
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            return LuaAPI.luaL_error(L, "invalid arguments to UWAEngine constructor!");
            
        }
        
		
        
		
        
        
        
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_AutoStart_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    
                    UWAEngine.AutoStart(  );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_StaticInit_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
			    int gen_param_count = LuaAPI.lua_gettop(L);
            
                if(gen_param_count == 1&& LuaTypes.LUA_TBOOLEAN == LuaAPI.lua_type(L, 1)) 
                {
                    bool _poco = LuaAPI.lua_toboolean(L, 1);
                    
                    UWAEngine.StaticInit( _poco );
                    
                    
                    
                    return 0;
                }
                if(gen_param_count == 0) 
                {
                    
                    UWAEngine.StaticInit(  );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
            return LuaAPI.luaL_error(L, "invalid arguments to UWAEngine.StaticInit!");
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_Start_xlua_st_(RealStatePtr L)
        {
		    try {
            
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            
            
            
                
                {
                    UWAEngine.Mode _mode;translator.Get(L, 1, out _mode);
                    
                    UWAEngine.Start( _mode );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_Stop_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    
                    UWAEngine.Stop(  );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_Tag_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    string _tag = LuaAPI.lua_tostring(L, 1);
                    
                    UWAEngine.Tag( _tag );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_Note_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    string _note = LuaAPI.lua_tostring(L, 1);
                    
                    UWAEngine.Note( _note );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_SetUIActive_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    bool _active = LuaAPI.lua_toboolean(L, 1);
                    
                    UWAEngine.SetUIActive( _active );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_Dump_xlua_st_(RealStatePtr L)
        {
		    try {
            
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            
            
            
                
                {
                    UWAEngine.DumpType _t;translator.Get(L, 1, out _t);
                    
                    UWAEngine.Dump( _t );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_PushSample_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    string _sampleName = LuaAPI.lua_tostring(L, 1);
                    
                    UWAEngine.PushSample( _sampleName );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_PopSample_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    
                    UWAEngine.PopSample(  );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_Upload_xlua_st_(RealStatePtr L)
        {
		    try {
            
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            
            
            
			    int gen_param_count = LuaAPI.lua_gettop(L);
            
                if(gen_param_count == 5&& translator.Assignable<System.Action<bool>>(L, 1)&& (LuaAPI.lua_isnil(L, 2) || LuaAPI.lua_type(L, 2) == LuaTypes.LUA_TSTRING)&& (LuaAPI.lua_isnil(L, 3) || LuaAPI.lua_type(L, 3) == LuaTypes.LUA_TSTRING)&& LuaTypes.LUA_TNUMBER == LuaAPI.lua_type(L, 4)&& LuaTypes.LUA_TNUMBER == LuaAPI.lua_type(L, 5)) 
                {
                    System.Action<bool> _callback = translator.GetDelegate<System.Action<bool>>(L, 1);
                    string _user = LuaAPI.lua_tostring(L, 2);
                    string _password = LuaAPI.lua_tostring(L, 3);
                    int _projectId = LuaAPI.xlua_tointeger(L, 4);
                    int _timeLimitS = LuaAPI.xlua_tointeger(L, 5);
                    
                    UWAEngine.Upload( _callback, _user, _password, _projectId, _timeLimitS );
                    
                    
                    
                    return 0;
                }
                if(gen_param_count == 5&& translator.Assignable<System.Action<bool>>(L, 1)&& (LuaAPI.lua_isnil(L, 2) || LuaAPI.lua_type(L, 2) == LuaTypes.LUA_TSTRING)&& (LuaAPI.lua_isnil(L, 3) || LuaAPI.lua_type(L, 3) == LuaTypes.LUA_TSTRING)&& (LuaAPI.lua_isnil(L, 4) || LuaAPI.lua_type(L, 4) == LuaTypes.LUA_TSTRING)&& LuaTypes.LUA_TNUMBER == LuaAPI.lua_type(L, 5)) 
                {
                    System.Action<bool> _callback = translator.GetDelegate<System.Action<bool>>(L, 1);
                    string _user = LuaAPI.lua_tostring(L, 2);
                    string _password = LuaAPI.lua_tostring(L, 3);
                    string _projectName = LuaAPI.lua_tostring(L, 4);
                    int _timeLimitS = LuaAPI.xlua_tointeger(L, 5);
                    
                    UWAEngine.Upload( _callback, _user, _password, _projectName, _timeLimitS );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
            return LuaAPI.luaL_error(L, "invalid arguments to UWAEngine.Upload!");
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_LogValue_xlua_st_(RealStatePtr L)
        {
		    try {
            
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            
            
            
			    int gen_param_count = LuaAPI.lua_gettop(L);
            
                if(gen_param_count == 2&& (LuaAPI.lua_isnil(L, 1) || LuaAPI.lua_type(L, 1) == LuaTypes.LUA_TSTRING)&& LuaTypes.LUA_TNUMBER == LuaAPI.lua_type(L, 2)) 
                {
                    string _valueName = LuaAPI.lua_tostring(L, 1);
                    float _value = (float)LuaAPI.lua_tonumber(L, 2);
                    
                    UWAEngine.LogValue( _valueName, _value );
                    
                    
                    
                    return 0;
                }
                if(gen_param_count == 2&& (LuaAPI.lua_isnil(L, 1) || LuaAPI.lua_type(L, 1) == LuaTypes.LUA_TSTRING)&& LuaTypes.LUA_TNUMBER == LuaAPI.lua_type(L, 2)) 
                {
                    string _valueName = LuaAPI.lua_tostring(L, 1);
                    int _value = LuaAPI.xlua_tointeger(L, 2);
                    
                    UWAEngine.LogValue( _valueName, _value );
                    
                    
                    
                    return 0;
                }
                if(gen_param_count == 2&& (LuaAPI.lua_isnil(L, 1) || LuaAPI.lua_type(L, 1) == LuaTypes.LUA_TSTRING)&& LuaTypes.LUA_TBOOLEAN == LuaAPI.lua_type(L, 2)) 
                {
                    string _valueName = LuaAPI.lua_tostring(L, 1);
                    bool _value = LuaAPI.lua_toboolean(L, 2);
                    
                    UWAEngine.LogValue( _valueName, _value );
                    
                    
                    
                    return 0;
                }
                if(gen_param_count == 2&& (LuaAPI.lua_isnil(L, 1) || LuaAPI.lua_type(L, 1) == LuaTypes.LUA_TSTRING)&& translator.Assignable<UnityEngine.Vector3>(L, 2)) 
                {
                    string _valueName = LuaAPI.lua_tostring(L, 1);
                    UnityEngine.Vector3 _value;translator.Get(L, 2, out _value);
                    
                    UWAEngine.LogValue( _valueName, _value );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
            return LuaAPI.luaL_error(L, "invalid arguments to UWAEngine.LogValue!");
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_AddMarker_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    string _valueName = LuaAPI.lua_tostring(L, 1);
                    
                    UWAEngine.AddMarker( _valueName );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_SetOverrideLuaState_xlua_st_(RealStatePtr L)
        {
		    try {
            
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            
            
            
                
                {
                    object _luaState = translator.GetObject(L, 1, typeof(object));
                    
                    UWAEngine.SetOverrideLuaState( _luaState );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_SetOverrideLuaLib_xlua_st_(RealStatePtr L)
        {
		    try {
            
            
            
                
                {
                    string _luaLib = LuaAPI.lua_tostring(L, 1);
                    
                    UWAEngine.SetOverrideLuaLib( _luaLib );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _m_SetOverrideAndroidActivity_xlua_st_(RealStatePtr L)
        {
		    try {
            
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            
            
            
                
                {
                    UnityEngine.AndroidJavaObject _activity = (UnityEngine.AndroidJavaObject)translator.GetObject(L, 1, typeof(UnityEngine.AndroidJavaObject));
                    
                    UWAEngine.SetOverrideAndroidActivity( _activity );
                    
                    
                    
                    return 0;
                }
                
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            
        }
        
        
        
        
        [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
        static int _g_get_FrameId(RealStatePtr L)
        {
		    try {
            
			    LuaAPI.xlua_pushinteger(L, UWAEngine.FrameId);
            }
            catch(System.Exception gen_e) {
                var t = ObjectTranslatorPool.Instance.Find(L);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, gen_e);
				return LuaAPI.luaL_error_exception(L, wrappedException);
            }
            return 1;
        }
        
        
        
		
		
		
		
    }
#endif
}

namespace XLua
{
	public partial class ObjectTranslator
	{
		static XLua.CSObjectWrap.XLua_Gen_Initer_Register__HandWritten__ s_gen_reg_dumb_obj_handwritten = new();

		static XLua.CSObjectWrap.XLua_Gen_Initer_Register__HandWritten__ gen_reg_dumb_obj_handwritten =>
			s_gen_reg_dumb_obj_handwritten;
	}
}
