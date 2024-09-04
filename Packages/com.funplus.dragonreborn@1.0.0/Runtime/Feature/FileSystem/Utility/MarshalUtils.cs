using System;
using System.Runtime.InteropServices;

namespace DragonReborn
{
    public static class MarshalUtils
    {
        private const int BlockSize = 1024 * 4;
        private static IntPtr s_CachedHGlobalPtr = IntPtr.Zero;
        private static int s_CachedHGlobalSize = 0;
        
        public static void EnsureCachedHGlobalSize(int ensureSize)
        {
            if (ensureSize < 0)
            {
                throw new ArgumentException("Structure size is invalid.");
            }

            if (s_CachedHGlobalPtr == IntPtr.Zero || s_CachedHGlobalSize < ensureSize)
            {
                FreeCachedHGlobal();
                int size = (ensureSize - 1 + BlockSize) / BlockSize * BlockSize;
                s_CachedHGlobalPtr = Marshal.AllocHGlobal(size);
                s_CachedHGlobalSize = size;
            }
        }
        
        public static void FreeCachedHGlobal()
        {
            if (s_CachedHGlobalPtr != IntPtr.Zero)
            {
                Marshal.FreeHGlobal(s_CachedHGlobalPtr);
                s_CachedHGlobalPtr = IntPtr.Zero;
                s_CachedHGlobalSize = 0;
            }
        }
        
        public static void StructureToBytes<T>(T structure, int structureSize, byte[] result)
        {
            StructureToBytes(structure, structureSize, result, 0);
        }
        
        public static void StructureToBytes<T>(T structure, int structureSize, byte[] result, int startIndex)
        {
            if (structureSize < 0)
            {
                throw new ArgumentException("Structure size is invalid.");
            }

            if (result == null)
            {
                throw new ArgumentException("Result is invalid.");
            }

            if (startIndex < 0)
            {
                throw new ArgumentException("Start index is invalid.");
            }

            if (startIndex + structureSize > result.Length)
            {
                throw new ArgumentException("Result length is not enough.");
            }

            EnsureCachedHGlobalSize(structureSize);
            Marshal.StructureToPtr(structure, s_CachedHGlobalPtr, true);
            Marshal.Copy(s_CachedHGlobalPtr, result, startIndex, structureSize);
        }
        
        public static T BytesToStructure<T>(int structureSize, byte[] buffer)
        {
            return BytesToStructure<T>(structureSize, buffer, 0);
        }
        
        public static T BytesToStructure<T>(int structureSize, byte[] buffer, int startIndex)
        {
            if (structureSize < 0)
            {
                throw new ArgumentException("Structure size is invalid.");
            }

            if (buffer == null)
            {
                throw new ArgumentException("Buffer is invalid.");
            }

            if (startIndex < 0)
            {
                throw new ArgumentException("Start index is invalid.");
            }

            if (startIndex + structureSize > buffer.Length)
            {
                throw new ArgumentException("Buffer length is not enough.");
            }

            EnsureCachedHGlobalSize(structureSize);
            Marshal.Copy(buffer, startIndex, s_CachedHGlobalPtr, structureSize);
            return Marshal.PtrToStructure<T>(s_CachedHGlobalPtr);
        }
    }
}
