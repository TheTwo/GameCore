using System;
using System.Collections;
using System.Collections.Generic;
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

// ReSharper disable once CheckNamespace
namespace XLua
{
    public partial class ObjectTranslator
    {
        public void Get(RealStatePtr luaL, int index, out LuaTableRefReadOnly val)
        {
            if (!LuaAPI.lua_istable(luaL, index))
            {
                throw new Exception("unpack fail for LuaTableReadOnly");
            }
            var refV = LuaAPI.luaL_ref(luaL);
            val = new LuaTableRefReadOnly(refV, luaEnv);
        }
        
        public void Get(RealStatePtr L, int index, out ReadOnlySpan<byte> val)
        {
            if (!LuaAPI.lua_isstring(L, index))
            {
                throw new Exception("ReadOnlySpan can only convert from string");
            }
            val = LuaAPI.xlua_toreadonlyspanbytes(L, index);
        }

        public void Get(RealStatePtr L, int index, out LuaArrayTableRef val)
        {
	        if (!LuaAPI.lua_istable(L, index))
	        {
		        throw new Exception("LuaArrayTableRef can only convert from table");
	        }

	        val = new LuaArrayTableRef(LuaAPI.lua_topointer(L, index));
        }
    }
    
    public ref struct LuaTableRefReadOnly
    {
        private int _luaReference;
        private readonly LuaEnv _luaEnv;

        public LuaTableRefReadOnly(int luaReference, LuaEnv luaEnv)
        {
            _luaReference = luaReference;
            _luaEnv = luaEnv;
        }

        public int Length
        {
            get
            {
                if (_luaReference == 0) return 0;
#if THREAD_SAFE || HOTFIX_ENABLE
                LockUtils.CheckLock(_luaEnv.luaEnvLock); lock (_luaEnv.luaEnvLock)
                {
#endif
                    var intPtrL = _luaEnv.L;
                    int oldTop = LuaAPI.lua_gettop(intPtrL);
                    LuaAPI.lua_getref(intPtrL, _luaReference);
                    var len = (int)LuaAPI.xlua_objlen(intPtrL, -1);
                    LuaAPI.lua_settop(intPtrL, oldTop);
                    return len;
#if THREAD_SAFE || HOTFIX_ENABLE
                }
#endif
            }
        }

        public bool TryGet<TKey, TValue>(in TKey key, out TValue value)
        {
            if (_luaReference == 0)
            {
                value = default;
                return false;
            }
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(_luaEnv.luaEnvLock); lock (_luaEnv.luaEnvLock)
            {
#endif
                var intPtrL = _luaEnv.L;
                var translator = _luaEnv.translator;
                int oldTop = LuaAPI.lua_gettop(intPtrL);
                LuaAPI.lua_getref(intPtrL, _luaReference);
                translator.PushByType(intPtrL, key);

                if (0 != LuaAPI.xlua_pgettable(intPtrL, -2))
                {
                    string err = LuaAPI.lua_tostring(intPtrL, -1);
                    LuaAPI.lua_settop(intPtrL, oldTop);
                    throw new Exception("get field [" + key + "] error:" + err);
                }

                var luaType = LuaAPI.lua_type(intPtrL, -1);
                if (luaType == LuaTypes.LUA_TNIL)
                {
                    value = default;
                    return false;
                }
                try
                {
                    translator.Get(intPtrL, -1, out value);
                    return true;
                }
                finally
                {
                    LuaAPI.lua_settop(intPtrL, oldTop);
                }
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }

        public void ForEach<TKey, TValue>(Func<TKey, TValue, bool> call)
        {
            if (_luaReference == 0)
            {
                return;
            }
#if THREAD_SAFE || HOTFIX_ENABLE
            LockUtils.CheckLock(_luaEnv.luaEnvLock); lock (_luaEnv.luaEnvLock)
            {
#endif
                var intPrtL = _luaEnv.L;
                var translator = _luaEnv.translator;
                var oldTop = LuaAPI.lua_gettop(intPrtL);
                try
                {
                    LuaAPI.lua_getref(intPrtL, _luaReference);
                    LuaAPI.lua_pushnil(intPrtL);
                    while (LuaAPI.lua_next(intPrtL, -2) != 0)
                    {
                        if (translator.Assignable<TKey>(intPrtL, -2))
                        {
                            translator.Get(intPrtL, -2, out TKey key);
                            translator.Get(intPrtL, -1, out TValue val);
                            if (!call(key, val))
                            {
                                return;
                            }
                        }

                        LuaAPI.lua_pop(intPrtL, 1);
                    }
                }
                finally
                {
                    LuaAPI.lua_settop(intPrtL, oldTop);
                }
#if THREAD_SAFE || HOTFIX_ENABLE
            }
#endif
        }

        public Enumerator<TKey, TValue> GetEnumerator<TKey, TValue>()
        {
            return new Enumerator<TKey, TValue>(_luaEnv.L, _luaEnv.translator, _luaReference);
        }
        
        public struct Enumerator<TKey, TValue> : IEnumerator<KeyValuePair<TKey, TValue>>
        {
            private IntPtr _intPtrL;
            private readonly ObjectTranslator _translator;
            private readonly int _oldTop;
            private KeyValuePair<TKey, TValue> _current;

            public Enumerator(IntPtr intPtrL, ObjectTranslator translator, int luaReference)
            {
                _intPtrL = intPtrL;
                _translator = translator;
                _oldTop = LuaAPI.lua_gettop(_intPtrL);
                _current = default;
                LuaAPI.lua_getref(_intPtrL, luaReference);
                LuaAPI.lua_pushnil(_intPtrL);
            }

            public bool MoveNext()
            {
                while (LuaAPI.lua_next(_intPtrL, -2) != 0)
                {
                    if (_translator.Assignable<TKey>(_intPtrL, -2))
                    {
                        _translator.Get(_intPtrL, -2, out TKey key);
                        _translator.Get(_intPtrL, -1, out TValue val);
                        _current = new KeyValuePair<TKey, TValue>(key, val);
                        LuaAPI.lua_pop(_intPtrL, 1);
                        return true;
                    }
                    LuaAPI.lua_pop(_intPtrL, 1);
                }
                return false;
            }

            public void Reset()
            {
                
            }

            object IEnumerator.Current => Current;

            public void Dispose()
            {
                if (_intPtrL == IntPtr.Zero) return;
                LuaAPI.lua_settop(_intPtrL, _oldTop);
                _intPtrL = IntPtr.Zero;
            }

            public KeyValuePair<TKey, TValue> Current => _current;
        }

        public void Dispose()
        {
            if (_luaReference == 0) return;
            _luaEnv.translator.ReleaseLuaBase(_luaEnv.L, _luaReference, false);
            _luaReference = 0;
        }
    }
}