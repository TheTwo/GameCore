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

namespace XLua
{
	public partial class LuaTable
	{
		public LuaTableEnumerable<TKey, TValue> GetEnumerable<TKey, TValue>() => new(luaReference, luaEnv);
		public LuaTableEnumerator<TKey, TValue> GetEnumerator<TKey, TValue>() => new(luaReference, luaEnv);
	}
	
	public struct LuaTableKeyValue<TKey, TValue>
	{
		public TKey Key;
		public TValue Value;
	}
	
	public struct LuaTableEnumerable<TKey, TValue> : IEnumerable<LuaTableKeyValue<TKey, TValue>>
	{
		public LuaTableEnumerable(int reference, LuaEnv luaEnv)
		{
			_reference = reference;
			_luaEnv = luaEnv;
		}
		
		private int _reference;
		private LuaEnv _luaEnv;
		public IEnumerator<LuaTableKeyValue<TKey, TValue>> GetEnumerator()
		{
			return new LuaTableEnumerator<TKey, TValue>(_reference, _luaEnv);
		}

		IEnumerator IEnumerable.GetEnumerator()
		{
			return GetEnumerator();
		}
	}

	public struct LuaTableEnumerator<TKey, TValue> : IEnumerator<LuaTableKeyValue<TKey, TValue>>
	{
		private readonly int _reference;
		private readonly LuaEnv _luaEnv;
		private TKey _lastKey;
		private TValue _lastValue;
		private bool _isFirst;

		public LuaTableEnumerator(int reference, LuaEnv luaEnv)
		{
			_reference = reference;
			_luaEnv = luaEnv;
			_lastKey = default;
			_lastValue = default;
			_isFirst = true;
		}

		public bool MoveNext()
		{
#if THREAD_SAFE || HOTFIX_ENABLE
			LockUtils.CheckLock(_luaEnv.luaEnvLock); lock(_luaEnv.luaEnvLock)
			{
#endif
				var L = _luaEnv.L;
				var translator = _luaEnv.translator;
				var findValue = false;
				var oldTop = LuaAPI.lua_gettop(L);
				try
				{
					LuaAPI.lua_getref(L, _reference);
					if (_isFirst)
					{
						LuaAPI.lua_pushnil(L);
					}
					else
					{
						translator.PushAny(L, _lastKey);
					}
					_isFirst = false;
					
					while (LuaAPI.lua_next(L, -2) != 0)
					{
						if (translator.Assignable<TKey>(L, -2))
						{
							translator.Get(L, -2, out _lastKey);
							translator.Get(L, -1, out _lastValue);
						}
						LuaAPI.lua_pop(L, 1);
						findValue = true;
						break;
					}
				}
				finally
				{
					LuaAPI.lua_settop(L, oldTop);
				}
				return findValue;
#if THREAD_SAFE || HOTFIX_ENABLE
			}
#endif
		}

		public void Reset()
		{
			_lastKey = default;
			_lastValue = default;
			_isFirst = true;
		}

		public LuaTableKeyValue<TKey, TValue> Current => new()
		{
			Key = _lastKey,
			Value = _lastValue,
		};

		object IEnumerator.Current => Current;

		public void Dispose()
		{
			
		}
	}
}
