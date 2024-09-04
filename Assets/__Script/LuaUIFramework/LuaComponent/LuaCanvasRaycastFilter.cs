#if USE_XLUA
using UnityEngine;
using XLua;

// ReSharper disable once CheckNamespace
namespace DragonReborn.UI
{
	public class LuaCanvasRaycastFilter : LuaBaseComponent ,ICanvasRaycastFilter
	{
		private enum SelfLuaFuncType
		{
			IsRaycastLocationValid,
		}

		protected override void Init()
		{
			base.Init();
			if (!string.IsNullOrEmpty(LuaScriptPath()))
			{
				InitSelfLua();
			}
		}

		protected override void OnClose(object param)
		{
			if (Lua != null)
			{
				ClearSelfAllLuaFunc();
			}
			base.OnClose(param);
		}

		public bool IsRaycastLocationValid(Vector2 sp, Camera eventCamera)
		{
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncArray, (int)SelfLuaFuncType.IsRaycastLocationValid, sp, eventCamera,
				out bool ret);
			return ret;
		}
		
		private LuaFunction[] _luaFuncArray;
		private void ClearSelfAllLuaFunc()
		{
			if (_luaFuncArray == null) return;
			for (var i = 0; i < _luaFuncArray.Length; i++)
			{
				_luaFuncArray[i]?.Dispose();
				_luaFuncArray[i] = null;
			}
		}
		
		private void InitSelfLua()
		{
			ClearSelfAllLuaFunc();
			_luaFuncArray = LuaUIUtility.InitAllLuaFunc(Lua,typeof(SelfLuaFuncType));
		}
	}
}
#endif
