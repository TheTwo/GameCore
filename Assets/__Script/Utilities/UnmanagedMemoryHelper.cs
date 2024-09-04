using System;
using System.IO;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using Unity.Collections.LowLevel.Unsafe;
using XLua;
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
namespace DragonReborn.Utilities
{
    public static class UnmanagedMemoryHelperWrap
    {
        // ReSharper disable once InconsistentNaming
        public static void Register(RealStatePtr L)
        {
            LuaAPI.lua_newtable(L);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.Alloc));
            LuaAPI.lua_pushstdcallcfunction(L, _m_Alloc_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.GetLocalPosition));
            LuaAPI.lua_pushstdcallcfunction(L, _m_GetLocalPosition_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.Seek));
            LuaAPI.lua_pushstdcallcfunction(L, _m_Seek_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.Free));
            LuaAPI.lua_pushstdcallcfunction(L, _m_Free_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteChar));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteChar_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteByte));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteByte_xlua_st_);
            LuaAPI.lua_rawset(L, -3);
            
            LuaAPI.xlua_pushasciistring(L, "WriteBoolean");
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteByte_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteSByte));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteSByte_xlua_st_);
            LuaAPI.lua_rawset(L, -3);
            
            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteUInt16));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteUInt16_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteInt16));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteInt16_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteUInt32));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteUInt32_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteInt32));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteInt32_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteUInt64));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteUInt64_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteInt64));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteInt64_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteFloat));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteFloat_xlua_st_);
            LuaAPI.lua_rawset(L, -3);

            LuaAPI.xlua_pushasciistring(L, nameof(UnmanagedMemoryHelper.WriteDouble));
            LuaAPI.lua_pushstdcallcfunction(L, _m_WriteDouble_xlua_st_);
            LuaAPI.lua_rawset(L, -3);


            if (LuaAPI.xlua_setglobal(L, "Unmanaged") != 0)
            {
                NLogger.Error("Load Lib Failed");
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_Alloc_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    int size = LuaAPI.xlua_tointeger(l, 1);

                    long genRet = UnmanagedMemoryHelper.Alloc(size);
                    LuaAPI.lua_pushint64(l, genRet);


                    return 1;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_GetLocalPosition_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);

                    long genRet = UnmanagedMemoryHelper.GetLocalPosition(target);
                    LuaAPI.lua_pushint64(l, genRet);


                    return 1;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_Seek_xlua_st_(RealStatePtr l)
        {
            try
            {
                ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(l);


                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    long offset = LuaAPI.lua_toint64(l, 2);
                    SeekOrigin loc;
                    translator.Get(l, 3, out loc);

                    UnmanagedMemoryHelper.Seek(target, offset, loc);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_Free_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);

                    UnmanagedMemoryHelper.Free(target);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteChar_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    char value = (char)LuaAPI.xlua_tointeger(l, 2);

                    UnmanagedMemoryHelper.WriteChar(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteSByte_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    sbyte value = (sbyte)LuaAPI.xlua_tointeger(l, 2);

                    UnmanagedMemoryHelper.WriteSByte(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteByte_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    byte value = (byte)LuaAPI.xlua_tointeger(l, 2);

                    UnmanagedMemoryHelper.WriteByte(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteUInt16_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    ushort value = (ushort)LuaAPI.xlua_touint(l, 2);

                    UnmanagedMemoryHelper.WriteUInt16(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }
        
        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteInt16_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    short value = (short)LuaAPI.xlua_tointeger(l, 2);

                    UnmanagedMemoryHelper.WriteInt16(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteUInt32_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    uint value = LuaAPI.xlua_touint(l, 2);

                    UnmanagedMemoryHelper.WriteUInt32(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteInt32_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    int value = LuaAPI.xlua_tointeger(l, 2);

                    UnmanagedMemoryHelper.WriteInt32(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteUInt64_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    ulong value = LuaAPI.lua_touint64(l, 2);

                    UnmanagedMemoryHelper.WriteUInt64(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteInt64_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    long value = LuaAPI.lua_toint64(l, 2);

                    UnmanagedMemoryHelper.WriteInt64(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteFloat_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    float value = (float)LuaAPI.lua_tonumber(l, 2);

                    UnmanagedMemoryHelper.WriteFloat(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }

        [MonoPInvokeCallback(typeof(LuaCSFunction))]
        private static int _m_WriteDouble_xlua_st_(RealStatePtr l)
        {
            try
            {
                {
                    long target = LuaAPI.lua_toint64(l, 1);
                    double value = LuaAPI.lua_tonumber(l, 2);

                    UnmanagedMemoryHelper.WriteDouble(target, value);


                    return 0;
                }
            }
            catch (Exception genE)
            {
                var t = ObjectTranslatorPool.Instance.Find(l);
                string traceback = t.luaEnv.TraceBack();
                var wrappedException = new LuaStackTraceException(traceback, genE);
                return LuaAPI.luaL_error_exception(l, wrappedException);
            }
        }
    }
    
    public static unsafe class UnmanagedMemoryHelper
    {
        private const ulong Magic = 0xFFFF01CE;

        private struct MetaInfo
        {
            public ulong MagicFlag;
            // ReSharper disable once NotAccessedField.Local
            public ulong Id;
            public long Size;
            public long WritePos;
        }

        private static ulong _indexCounter;

        public static BinaryReader CreateReader(long memoryAddress)
        {
            var ptr = new IntPtr(memoryAddress);
            CheckMagic(ptr);
            ref var metaInfo = ref UnsafeUtility.AsRef<MetaInfo>(ptr.ToPointer());
            return new BinaryReader(new UnmanagedMemoryStream((byte*)(ptr + sizeof(MetaInfo)).ToPointer(), metaInfo.Size,
                metaInfo.Size, FileAccess.Read));
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static long Alloc(int size)
        {
            var index = unchecked(_indexCounter++);
            var start = Marshal.AllocHGlobal(sizeof(MetaInfo) + size);
            ref var metaInfo = ref UnsafeUtility.AsRef<MetaInfo>(start.ToPointer());
            metaInfo.MagicFlag = Magic;
            metaInfo.Id = index;
            metaInfo.Size = size;
            metaInfo.WritePos = 0;
            return start.ToInt64();
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static long GetLocalPosition(long target)
        {
            var prt = new IntPtr(target);
            ref var metaInfo = ref CheckMagic(prt);
            return metaInfo.WritePos;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Seek(long target, long offset, SeekOrigin loc)
        {
            var prt = new IntPtr(target);
            ref var metaInfo = ref CheckMagic(prt);
            var size = metaInfo.Size;
            if (offset > size)
                throw new ArgumentOutOfRangeException(nameof(offset), offset, null);
            ref var pos = ref metaInfo.WritePos;
            var toPos = loc switch
            {
                SeekOrigin.Begin => offset,
                SeekOrigin.Current => pos + offset,
                SeekOrigin.End => size + offset,
                _ => throw new ArgumentOutOfRangeException(nameof(loc), loc, null)
            };
            if (toPos < 0 || toPos >= size)
                throw new ArgumentOutOfRangeException(nameof(offset), offset, null);
            pos = toPos;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Free(long target)
        {
            var prt = new IntPtr(target);
            ref var metaInfo = ref CheckMagic(prt);
            metaInfo.MagicFlag = 0;
            metaInfo.Size = 0;
            metaInfo.WritePos = 0;
            Marshal.FreeHGlobal(prt);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteChar(long target, char value)
        {
            const int charMaxBytes = 4;
            var byteBuffer = stackalloc byte[charMaxBytes];
            var numBytes = System.Text.Encoding.UTF8.GetBytes(&value, 1, byteBuffer, charMaxBytes);
            for (var i = 0; i < numBytes; i++)
            {
                Write(target, byteBuffer[i]);
            }
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteSByte(long target, sbyte value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteByte(long target, byte value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteUInt16(long target, ushort value)
        {
            Write(target, value);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteInt16(long target, short value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteUInt32(long target, uint value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteInt32(long target, int value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteUInt64(long target, ulong value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteInt64(long target, long value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteFloat(long target, float value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void WriteDouble(long target, double value)
        {
            Write(target, value);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static ref MetaInfo CheckMagic(IntPtr target)
        {
            ref var ret = ref UnsafeUtility.AsRef<MetaInfo>(target.ToPointer());
            if (ret.MagicFlag != Magic)
                throw new InvalidOperationException("Invalid memory pointer");
            return ref ret;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void Write<T>(long target, T value) where T : unmanaged
        {
            var ptr = new IntPtr(target);
            ref var metaInfo = ref CheckMagic(ptr);
            ref var writePos = ref metaInfo.WritePos;
            (*(T*)(ptr + sizeof(MetaInfo) + (int)writePos).ToPointer()) = value;
            writePos += sizeof(T);
        }
    }
}