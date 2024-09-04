

using Object = UnityEngine.Object;
#if USE_XLUA
using System;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace DragonReborn.UI
{
	public class LuaBaseComponent : BaseComponent,ILuaComponent
	{
		[SerializeField]
		private string _luaScriptPath;

		public string LuaScriptPath()
		{
			return _luaScriptPath;
		}
#if UNITY_EDITOR
		[NonSerialized]
		private string _luaScriptFullPath;
		public string LuaScriptFullPath()
		{			
			return _luaScriptFullPath;
		}
		public void SetLuaScriptFullPath(string fullPath)
		{
			_luaScriptFullPath = fullPath;
		}
#endif


		public LuaTable Lua
		{
			get
			{
				return LogicObject as LuaTable;
			}
			set
			{
				LogicObject = value;
			}
		}

		enum LuaFuncType
		{
			OnCreate,
			OnShow,
			OnOpened,
			OnFeedData,
			OnHide,
			OnClose,
			OnUnityMessage,
			InvokeClearFunctions, //清理函数，不要重载
		}
		
		private LuaFunction[] _luaFuncs = null;
		private void ClearAllLuaFunc()
		{
			if (_luaFuncs == null) return;
			for (int i = 0; i < _luaFuncs.Length; i++)
			{
				_luaFuncs[i]?.Dispose();
				_luaFuncs[i] = null;
			}
		}
		private void DelLuaObject()
		{
			if (Lua == null) return;
			ClearAllLuaFunc();
			Lua.Set("CSComponent", (BaseComponent)null);
			Lua.Dispose();
			Lua = null;
			//强制断开self对this的引用
			if (ScriptEngine.Initialized)
			{
				ScriptEngine.Instance.ReleaseCSharpObject(this);
			}
		}
		private void InitLua()
		{
			//设置之前先删除所有的回调函数，防止component被重用的时候导致问题，调用其他的函数
			DelLuaObject();
			//_luaScriptPath = luaScriptPath;
			Lua = LuaUIUtility.GetLuaTableForUI(this);
			_luaFuncs = LuaUIUtility.InitAllLuaFunc(Lua,typeof(LuaFuncType));
		}

		protected override void Init()
		{
			base.Init();
			//防止重复初始化，导致Lua对象丢失引用
			if (!string.IsNullOrEmpty(_luaScriptPath) && Lua == null)
			{
				try
				{
					InitLua();
				}
				catch (Exception e)
				{
					Debug.LogException(e);
					Debug.LogError($"Init Lua Failed!{gameObject.name} with LuaPath:{_luaScriptPath}" );
				}
			}
		}

		protected override void OnCreate(object param)
		{
			base.OnCreate(param);
			LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnCreate,param);
		}

		protected override void OnShow(object param)
		{
			base.OnShow(param);
			LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnShow,param);
		}
		
		protected override void OnOpened(object param)
		{
			base.OnOpened(param);
			LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnOpened,param);
		}

		protected override void OnFeedData(object data)
		{
			base.OnFeedData(data);	
			LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnFeedData,data);
		}

		protected override void OnHide(object param)
		{
			base.OnHide(param);
			LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnHide,param);
		}
		
		protected override void OnClose(object param)
		{
			base.OnClose(param);
			
			if (Lua!=null)
			{
				LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnClose,param);
				LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.InvokeClearFunctions);
				//ClearAllLuaFunc();
				//Lua.Set("CSComponent", (BaseComponent)null);
				//Lua.Dispose();
				//Lua = null;
				////强制断开self对this的引用
				//if (ScriptEngine.Initialized)
				//{
				//	ScriptEngine.Instance.ReleaseCSharpObject(this);
				//}
				DelLuaObject();
			}
		}

		public override bool CtrlSelf()
		{
			return !string.IsNullOrEmpty(_luaScriptPath);
		}

		public void SetLuaScriptPath(string luaPath)
		{
			_luaScriptPath = luaPath;
			if (Lua != null)
			{
				Close();
				Create();
			}
		}

		protected void OnUnityMessage(object param)
		{
			LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnUnityMessage,param);
		}
		
	}
}

#endif

