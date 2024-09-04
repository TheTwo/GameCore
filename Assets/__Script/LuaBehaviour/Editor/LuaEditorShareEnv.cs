using System;
using UnityEditor;
using UnityEngine;
using XLua;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public class LuaEditorShareEnv : ScriptableSingleton<LuaEditorShareEnv>
    {
        private LuaEnv _luaEnv;

        private void EnsureLuaEnv()
        {
            if (null != _luaEnv) return;
            _luaEnv = new LuaEnv();
            _luaEnv.AddLoader(LoadEditor);
        }

        public bool DoString(byte[] code, out object[] ret)
        {
            ret = default;
            if (code is not { Length: > 0 })
            {
                return false;
            }

            try
            {
                EnsureLuaEnv();
                ret = _luaEnv.DoString(code);
                return true;
            }
            catch (Exception e)
            {
                _luaEnv?.Dispose();
                _luaEnv = null;
                Debug.LogException(e);
            }
            return false;
        }

        private void OnDestroy()
        {
            var env = _luaEnv;
            _luaEnv = null;
            env?.FullGc();
            env?.Dispose(true);
        }
        
        private static byte[] LoadEditor(ref string scriptName)
        {
            try
            {
                return LuaBehaviourEditorUtils.FindTextAsset(scriptName);
            }
            catch (Exception e)
            {
                Debug.LogError($"[LuaBehaviourEditor] Error = {e}");
                return null;
            }
        }
    }
}