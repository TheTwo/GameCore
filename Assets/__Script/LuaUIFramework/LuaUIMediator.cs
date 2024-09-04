using Object = UnityEngine.Object;
#if USE_XLUA
using UnityEngine;
using System;
using System.Collections.Generic;
using System.IO;
using XLua;

namespace DragonReborn.UI
{
	// public sealed class LuaUIParameter
	// {
	//     public object Parameter;
	//
	//     public LuaUIParameter(object parameter)
	//     {
	//         Parameter = parameter;
	//     }
	// }

	public class LuaUIMediator : UIMediator, ILuaComponent
	{
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

		[SerializeField] private string _luaScriptPath;
		
		// public LuaTable Lua
		// {
		//     get
		//     {
		//         return Lua;
		//     }
		//     set
		//     {
		//         Lua = value;
		//     }
		// }
		//
		// private LuaTable Lua;
		public string LuaScriptPath()
		{
			return _luaScriptPath;
		}

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
			OnOpenedTrace,
			OnFeedData,
			OnHide,
			OnClose,
			OnReOpen,
			OnCloseTrace,
			OnTypeVisible,
			OnTypeInvisible,
			InvokeClearFunctions, //清理函数，不要重载
			TriggerShowMsg,
			TriggerHideMsg,
			IsPreventESC,
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
			Lua = LuaUIUtility.GetLuaTableForUI(this);
			_luaFuncs = LuaUIUtility.InitAllLuaFunc(Lua, typeof(LuaFuncType));
		}

		public override string GetClassName()
		{
			return Path.GetFileNameWithoutExtension(_luaScriptPath);
		}
		protected override void Init()
		{
			base.Init();
			if (!string.IsNullOrEmpty(_luaScriptPath))
			{
				InitLua();
			}
		}
		protected override void OnCreate(object param)
		{
			base.OnCreate(param);

			try
			{
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnCreate, param);
			}
			catch (Exception e)
			{
				UnityEngine.Debug.LogException(e);
#if UNITY_EDITOR
				if (UnityEditor.EditorUtility.DisplayDialog("Error", $"{_luaScriptPath}:OnCreate()发生错误！ {gameObject.name}", "销毁窗口", "保留现场"))
				{
#endif
					Invoke(nameof(CloseSelf), 0.2f);
#if UNITY_EDITOR
				}
#endif
			}
		}



		protected override void OnShow(object param)
		{
			base.OnShow(param);
			try
			{
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnShow, param);
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.TriggerShowMsg, this.Property.UIName);
			}
			catch (Exception e)
			{
				UnityEngine.Debug.LogException(e);
#if UNITY_EDITOR
				if (UnityEditor.EditorUtility.DisplayDialog("Error", $"{_luaScriptPath}:OnShow()发生错误！ {gameObject.name}", "销毁窗口", "保留现场"))
				{
#endif
					Invoke(nameof(CloseSelf), 1f);
#if UNITY_EDITOR
				}
#endif
			}
		}

		protected override void OnOpened(object param)
		{
			base.OnOpened(param);
#if UNITY_EDITOR
			try
			{
#endif
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnOpened, param);
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnOpenedTrace, param);
#if UNITY_EDITOR
			}
			catch (Exception e)
			{
				UnityEngine.Debug.LogException(e);
				if (UnityEditor.EditorUtility.DisplayDialog("Error", $"{_luaScriptPath}:OnOpened()发生错误！ {gameObject.name}", "销毁窗口", "保留现场"))
				{
					Invoke(nameof(CloseSelf), 1f);
				}
			}
#endif
		}

		protected override void OnFeedData(object data)
		{
			base.OnFeedData(data);
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnFeedData, data);
		}

		protected override void OnHide(object param)
		{
			base.OnHide(param);
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnHide, param);
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.TriggerHideMsg, this.Property.UIName);
		}

		protected override void OnClose(object param)
		{
			base.OnClose(param);
			// if (param is LuaUIParameter luaParam)
			// {
			//     LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnClose,luaParam.Parameter);
			// }
			// else
			{
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnClose, param);
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnCloseTrace, param);
				LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.InvokeClearFunctions);
			}
			//if (Lua != null)
			//{
			//	ClearAllLuaFunc();
			//	Lua.Set("CSComponent", (BaseComponent)null);
			//	Lua.Dispose();
			//	Lua = null;
			//	//强制断开self对this的引用
			//	if (ScriptEngine.Initialized)
			//	{
			//		ScriptEngine.Instance.ReleaseCSharpObject(this);
			//	}
			//}
			DelLuaObject();
		}
		
		public override void OnReOpen()
		{
			base.OnReOpen();
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnReOpen);
		}
		public override bool IsPreventESC()
		{
			return LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.IsPreventESC, out bool ret)
				? ret
				: base.IsPreventESC();
		}
		
		public override void ZBlockBehaviour()
		{
			if (IsRespondZBlock() &&
				(Property.Type == UIMediatorType.Popup ||
					Property.Type == UIMediatorType.Tip ||
					Property.Type == UIMediatorType.Dialog ||
					Property.Type == UIMediatorType.TopMostHud
				   )
				)
			{				
				CallLuaFunction("CloseSelf");
			}
		}
		

		public override bool CtrlSelf()
		{
			return !string.IsNullOrEmpty(_luaScriptPath);
		}

		public void CloseSelf()
		{
			UIManager.Instance.Close(this.RuntimeId);
		}

		public override void OnTypeVisible(bool fastForward = false)
		{
			base.OnTypeVisible(fastForward);
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnTypeVisible, fastForward);
		}

		public override void OnTypeInvisible(bool fastForward = false)
		{
			base.OnTypeInvisible(fastForward);
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnTypeInvisible, fastForward);
		}

		public override string Name
		{
			get { return $"{this._luaScriptPath}(id:{RuntimeId})"; }
		}

		public int UIMediatorTypeValue
		{
			get
			{
				return (int)this.Property.Type;
			}
		}

		public void CallLuaFunction(string funcName)
		{
			if (Lua == null || string.IsNullOrEmpty(funcName)) return;
			LuaUIUtility.InvokeLuaFunction(Lua, funcName);
		}
		
	}
}

#endif
