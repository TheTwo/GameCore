#if USE_UNI_LUA
using LuaAPI = UniLua.Lua;
#else
#if CHECK_XLUA_API_CALL_ENABLE
using LuaAPI = XLua.LuaDLL.LuaDLLWrapper;
#else
using LuaAPI = XLua.LuaDLL.Lua;
#endif
#endif

namespace XLua.LuaDLL
{
	using System.Runtime.InteropServices;
#if UNITY_EDITOR_WIN || UNITY_STANDALONE_WIN || XLUA_GENERAL || (UNITY_WSA && !UNITY_EDITOR)
	[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
	public delegate void LuaBeginGCCallback();

	[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
	public delegate void LuaEndGCCallback();
#else
    public delegate void LuaBeginGCCallback();

    public delegate void LuaEndGCCallback();
#endif

	public partial class Lua
	{
		[DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
		public static extern void xlua_set_gc_callback(LuaBeginGCCallback cb1, LuaEndGCCallback cb2);
		[DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
		public static extern void xlua_clear_gc_callback();
	}
	
	public static class LuaGCMonitor
	{
		private static LuaGCMonitorStrategy _strategy;
		public static int LuaGCTimesPer10Min => _strategy?.GCTimesPer10Min ?? -1;
		public static double GCAverageCostTime => _strategy?.GCAverageCostTime ?? -1.0;

		public static void OnInitialize()
		{
			_strategy = new LuaGCMonitorStrategy();
			SetGcCallback(OnStart, OnEnd);
		}

		public static void OnRelease()
		{
			ClearGcCallback();
			_strategy = null;
		}

		[MonoPInvokeCallback(typeof(LuaBeginGCCallback))]
		private static void OnStart()
		{
			_strategy.OnStart();
		}

		[MonoPInvokeCallback(typeof(LuaEndGCCallback))]
		private static void OnEnd()
		{
			_strategy.OnEnd();
		}
		
		private static void SetGcCallback(LuaBeginGCCallback onStart, LuaEndGCCallback onEnd)
		{
			LuaAPI.xlua_set_gc_callback(onStart, onEnd);
		}

		private static void ClearGcCallback()
		{
			LuaAPI.xlua_clear_gc_callback();
		}
	}
}
