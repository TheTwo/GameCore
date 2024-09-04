using System;
using System.IO;
using System.Runtime.Serialization;
using UnityEngine;
using System.Runtime.InteropServices;

namespace DragonReborn
{
    public sealed class APKFileSystemStreamNative : IFileSystemStream
    {
        private const int CachedBytesLength = 0x1000;
		private static readonly byte[] s_CachedBytes = new byte[CachedBytesLength];
        
#region CachedBuffer

        private const int BlockSize = 1024 * 4;
        private const int MaxCachedSize = 1024 * 32;
        private static IntPtr s_CachedHGlobalPtr = IntPtr.Zero;
        private static int s_CachedHGlobalSize = 0;
        
        public static void EnsureCachedHGlobalSize(int ensureSize)
        {
            if (ensureSize < 0)
            {
                throw new ArgumentException("ensureSize size is invalid.");
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
#endregion

#if UNITY_ANDROID && !UNITY_EDITOR
        private static bool sInitialized = false;
#endif

        private string m_Path;
        
        
#if UNITY_ANDROID && !UNITY_EDITOR
        [DllImport("ApkNativeRead", EntryPoint = "Android_IOUtils_Initial")]
        public static extern int Android_IOUtils_Initial();
	
        [DllImport("ApkNativeRead", EntryPoint = "Android_OpenFile")]
        public static extern int Android_OpenFile(string filename);
	
        [DllImport("ApkNativeRead", EntryPoint = "Android_CloseFile")]
        public static extern int Android_CloseFile(string filename);
	
        [DllImport("ApkNativeRead", EntryPoint = "Android_GetFileLength")]
        public static extern int Android_GetFileLength(string filename);

        [DllImport("ApkNativeRead", EntryPoint = "Android_SeekFile")]
        public static extern int Android_SeekFile(string filename, int offset);

        [DllImport("ApkNativeRead", EntryPoint = "Android_ReadFileBytes")]
        public static extern int Android_ReadFileBytes(string filename, ref IntPtr ptr, int length);
#endif
        
        public APKFileSystemStreamNative(string fullPath)
        {
            if (string.IsNullOrEmpty(fullPath))
            {
                throw new ArgumentException("Full path is invalid.");
            }

            m_Path = fullPath;
            
#if UNITY_ANDROID && !UNITY_EDITOR
            if (!sInitialized)
            {
                if (Android_IOUtils_Initial() == 0)
                {
                    NLogger.Error("APKFileSystemStreamNative Android_IOUtils_Initial  Failed.");
                    return;
                }
                sInitialized = true;
            }
            
            if (Android_OpenFile(fullPath) == 0)
            {
                NLogger.Error("APKFileSystemStreamNative Android_OpenFile Error " + fullPath);
            }
#endif
        }
        
        public long Length
        {
            get
            {
#if UNITY_ANDROID && !UNITY_EDITOR
                if (string.IsNullOrEmpty(m_Path))
                {
                    return 0;
                }
                return Android_GetFileLength(m_Path);
#else
                return 0;
#endif
            }
        }
        
        public void SetLength(long length)
        {
            throw new NotImplementedException();
        }
        
        public void Seek(long offset)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            if (string.IsNullOrEmpty(m_Path))
            {
                return;
            }
            Android_SeekFile(m_Path, (int) offset);
#endif
        }

        public unsafe int Read(IntPtr buffer, int length)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            int nRet = Android_ReadFileBytes(m_Path, ref buffer, length);
            return nRet;
#endif
            return -1;
        }

        public int Read(byte[] buffer, int length)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            
            if (length > MaxCachedSize)
            {
                IntPtr ptrBuff = IntPtr.Zero;
                ptrBuff = Marshal.AllocHGlobal(length);
                int nRet = Android_ReadFileBytes(m_Path, ref ptrBuff, length);
                if (nRet > 0)
                {
                    Marshal.Copy(ptrBuff, buffer, 0, nRet);
                }

                Marshal.FreeHGlobal(ptrBuff);
                return nRet;
            }
            else
            {
                EnsureCachedHGlobalSize(length);
                
                int nRet = Android_ReadFileBytes(m_Path, ref s_CachedHGlobalPtr, length);
                if (nRet > 0)
                {
                    Marshal.Copy(s_CachedHGlobalPtr, buffer, 0, nRet);
                    return nRet;
                }
            }
#endif
            return -1;
        }

        public int Read(Stream stream, int length)
        {
            int bytesRead = 0;
            int bytesLeft = length;
            while ((bytesRead = Read(s_CachedBytes, bytesLeft < CachedBytesLength ? bytesLeft : CachedBytesLength)) > 0)
            {
                bytesLeft -= bytesRead;
                stream.Write(s_CachedBytes, 0, bytesRead);
            }

            Array.Clear(s_CachedBytes, 0, CachedBytesLength);
            return length - bytesLeft;
        }

        public void Write(byte[] buffer, int length)
        {
            throw new NotImplementedException();
        }

        public void Write(Stream stream, int length)
        {
            throw new NotImplementedException();
        }
        
        public void Flush()
        {
            throw new NotImplementedException();
        }
        
        public void Close()
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            Android_CloseFile(m_Path);
#endif
        }
    }
}
