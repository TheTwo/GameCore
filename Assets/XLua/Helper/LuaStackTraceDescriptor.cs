#if UNITY_EDITOR
using DragonReborn;
using UnityEngine;

namespace XLua.Helper
{
	internal class LuaStackTraceDescriptor : FrameInterfaceDescriptor<IFrameworkLuaStackTrace>, IFrameworkLuaStackTrace
	{
		[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterAssembliesLoaded)]
		internal static void RegisterInterface()
		{
			FrameworkInterfaceManager.RegisterFrameInterface(new LuaStackTraceDescriptor());
		}

		public string StackTrace()
		{
			return ScriptEngine.Instance.LuaInstance.TraceBack();
		}

		protected override IFrameworkLuaStackTrace Create()
		{
			return new LuaStackTraceDescriptor();
		}
	}
}
#endif