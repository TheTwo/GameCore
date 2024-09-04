/*
 * Tencent is pleased to support the open source community by making xLua available.
 * Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

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

using System;
using DragonReborn;

namespace XLua
{
    public abstract class LuaBase : IDisposable
    {
        protected bool disposed;
        protected readonly int luaReference;
        protected readonly LuaEnv luaEnv;

#if UNITY_EDITOR || XLUA_GENERAL
        protected int _errorFuncRef { get { return luaEnv.errorFuncRef; } }
        protected RealStatePtr _L { get { return luaEnv.L; } }
        protected ObjectTranslator _translator { get { return luaEnv.translator; } }
#endif

        public int Ref
        {
            get { return luaReference; }
        }
        public LuaBase(int reference, LuaEnv luaenv)
        {
            luaReference = reference;
            luaEnv = luaenv;
        }

        ~LuaBase()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        public virtual void Dispose(bool disposeManagedResources)
        {
            if (!disposed)
            {
                if (luaReference != 0)
                {
#if THREAD_SAFE || HOTFIX_ENABLE
                    lock (luaEnv.luaEnvLock)
                    {
#endif
                        bool is_delegate = this is DelegateBridgeBase;
                        if (disposeManagedResources)
                        {
                            luaEnv.translator.ReleaseLuaBase(luaEnv.L, luaReference, is_delegate);
                        }
                        else //will dispse by LuaEnv.GC
                        {
                            luaEnv.equeueGCAction(new LuaEnv.GCAction { Reference = luaReference, IsDelegate = is_delegate });
                        }
#if THREAD_SAFE || HOTFIX_ENABLE
                    }
#endif
                }
                disposed = true;
            }
        }

        public override bool Equals(object o)
        {
            if (o != null && this.GetType() == o.GetType())
            {
#if THREAD_SAFE || HOTFIX_ENABLE
                LockUtils.CheckLock(luaEnv.luaEnvLock); lock(luaEnv.luaEnvLock)
                {
#endif
                    LuaBase rhs = (LuaBase)o;
                    var L = luaEnv.L;
                    if (L != rhs.luaEnv.L)
                        return false;
                    int top = LuaAPI.lua_gettop(L);
                    LuaAPI.lua_getref(L, rhs.luaReference);
                    LuaAPI.lua_getref(L, luaReference);
                    int equal = LuaAPI.lua_rawequal(L, -1, -2);
                    LuaAPI.lua_settop(L, top);
                    return (equal != 0);
#if THREAD_SAFE || HOTFIX_ENABLE
                }
#endif
            }
            else return false;
        }

        public override int GetHashCode()
        {
#if THREAD_SAFE || HOTFIX_ENABLE
	        LockUtils.CheckLock(luaEnv.luaEnvLock);
	        lock (luaEnv.luaEnvLock)
#endif
	        {
		        LuaAPI.lua_getref(luaEnv.L, luaReference);
		        var pointer = LuaAPI.lua_topointer(luaEnv.L, -1);
		        LuaAPI.lua_pop(luaEnv.L, 1);
		        return pointer.ToInt32();
	        }
        }
        
        public static bool operator ==(LuaBase lhv, LuaBase rhv)
        {
            var l_isNull = ReferenceEquals(lhv, null);
            var r_isNull = ReferenceEquals(rhv, null);
            if (l_isNull && r_isNull)
                return true;

            if (l_isNull || r_isNull)
                return false;

            return lhv.Equals(rhv);
        }

        public static bool operator !=(LuaBase lhv, LuaBase rhv)
        {
            return !(lhv == rhv);
        }

        internal virtual void push(RealStatePtr L)
        {
            LuaAPI.lua_getref(L, luaReference);
        }
    }
}
