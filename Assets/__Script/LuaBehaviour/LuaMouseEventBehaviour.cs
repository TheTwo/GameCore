using System;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace DragonReborn
{
    public class LuaMouseEventBehaviour : LuaBehaviour
    {
        private Action<LuaTable> _onMouseUpAsButton;
        private Action<LuaTable> _onMouseDown;
        private Action<LuaTable> _onMouseUp;
        private Action<LuaTable> _onMouseDrag;
        private Action<LuaTable> _onMouseOver;
        
        void OnMouseUpAsButton()
        {
            _onMouseUpAsButton?.Invoke(Instance);
        }

        void OnMouseDown()
        {
			_onMouseDown?.Invoke(Instance);
        }

        void OnMouseUp()
        {
			_onMouseUp?.Invoke(Instance);
        }

        void OnMouseDrag()
        {
			_onMouseDrag?.Invoke(Instance);
        }

        void OnMouseOver()
        {
			_onMouseOver?.Invoke(Instance);
        }
        
        protected override void Cleanup()
        {
            _onMouseUpAsButton = null;
            _onMouseDown = null;
            _onMouseUp = null;
            _onMouseDrag = null;
            _onMouseOver = null;
            base.Cleanup();
        }

        protected override bool LoadScript()
        {
            bool isLoad = base.LoadScript();
            if (isLoad)
            {
                Instance?.Get("OnMouseUpAsButton", out _onMouseUpAsButton);
                Instance?.Get("OnMouseDown", out _onMouseDown);
                Instance?.Get("OnMouseUp", out _onMouseUp);
                Instance?.Get("OnMouseDrag", out _onMouseDrag);
                Instance?.Get("OnMouseOver", out _onMouseOver);
            }
            return isLoad;
        }
    }
}