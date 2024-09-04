
using Object = UnityEngine.Object;
#if USE_XLUA
using System;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace DragonReborn.UI
{
    public class LuaTableViewProCell : TableViewProCell,ILuaComponent
    {
        //private LuaTable _currentTable;
      
        public bool IsUseNewLuaClass {
            get { return true; }
            set { }
        }

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

        [SerializeField]
        private string _luaScriptPath;

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

		enum LuaFuncType
        {
            OnCreate,
			OnShow,
            OnOpened,
            OnFeedData,
			OnHide,
            OnClose,
            Select,
            UnSelect,
            OnRecycle,
			SetDynamicCellRectSize,
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
		public void InitLua()
        {
			//设置之前先删除所有的回调函数，防止component被重用的时候导致问题，调用其他的函数
			//ClearAllLuaFunc();
			DelLuaObject();
            Lua = LuaUIUtility.GetLuaTableForUI(this);
            _luaFuncs = LuaUIUtility.InitAllLuaFunc(Lua,typeof(LuaFuncType));
        }
        public bool IsCellResetData 
        {
            get
            {
                return isCellResetData;
            }
            set
            {
                 isCellResetData = value;
            }
        }
        protected override void Init()
        {
            base.Init();
            if (!string.IsNullOrEmpty(_luaScriptPath) && Lua == null)
            {
                InitLua();
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
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnShow, param);
		}
		public override void FeedData(object data)
        {
            base.FeedData(data);
            LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnFeedData,data);
        }

        protected override void OnOpened(object param)
        {
            base.OnOpened(param);
            LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnOpened,param);
        }
        
        public override void Select()
        {
            base.Select();
            //_luaSelect?.Action(_currentTable);
            LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.Select,Lua);
        }

        public override void UnSelect()
        {
            base.UnSelect();
            // _luaUnSelect?.Action(_currentTable);
            LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.UnSelect,Lua);
        }

        
        public override void OnRecycle(TableViewProState way)
        {
            base.OnRecycle(way);
            LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnRecycle,way);
        }
		protected override void OnHide(object param)
		{
			base.OnHide(param);
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.OnHide, param);
		}
		protected override void OnClose(object param)
        {
            base.OnClose(param);
            if (Lua!=null)
            {
                LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.OnClose,param);
                LuaUIUtility.InvokeLuaFunc(Lua,_luaFuncs,(int)LuaFuncType.InvokeClearFunctions);
				DelLuaObject();
            }
        }

        
        public override bool CtrlSelf()
        {
            return !string.IsNullOrEmpty(_luaScriptPath);
        }

		public override void SetDynamicCellRectSize(Vector2 size)
		{
			//if(!LuaUIUtility.TryInvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.SetDynamicCellRectSize)){
			//	(transform as RectTransform).sizeDelta = size;
			//}
			LuaUIUtility.InvokeLuaFunc(Lua, _luaFuncs, (int)LuaFuncType.SetDynamicCellRectSize,size);
		}

		// public override void Release()
		// {
		//     base.Release();
		//     _luaRelease?.Action(_currentTable);
		//     ReleaseLuaReference();
		//     
		//     //强制断开self对this的引用
		//     var translator = ObjectTranslatorPool.Instance.Find(LuaManager.Instance.LuaEnv.L);
		//     translator?.ReleaseCSObjInCS(this);
		// }

		// [ReadOnlyInSpector] public Object _luaScriptObject;
	
        //
        // public void SetLuaScriptObject(Object script)
        // {
        //     _luaScriptObject = script;
        // }
        //
        // public Object GetLuaScriptObject()
        // {
        //     return _luaScriptObject;
        // }
               
        // public object GetDataByIndex(int index)
        // {
        //     if (_dataVessels.IsNullOrEmpty())
        //         return null;
        //
        //     if (_dataVessels.Count <= index)
        //         return null;
        //
        //     return _dataVessels[index].GetValue();
        // }
        //
        // public object GetDataByName(string name)
        // {
        //     if (name.IsNullOrEmpty())
        //         return null;
        //     
        //     if (_dataVessels.IsNullOrEmpty())
        //         return null;
        //     
        //     return _dataVessels.Find(x => x.CustomName == name)?.GetValue();
        // }
    }
}

#endif
