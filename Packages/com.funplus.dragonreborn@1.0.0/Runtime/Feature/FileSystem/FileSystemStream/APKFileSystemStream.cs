using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.Serialization;
using UnityEngine;

namespace DragonReborn
{
    public sealed class APKFileSystemStream : IFileSystemStream
    {
        private const int CachedBytesLength = 0x1000;
		private static readonly byte[] s_CachedBytes = new byte[CachedBytesLength];
        
#if UNITY_ANDROID && !UNITY_EDITOR
        public static AndroidJavaObject assetManager { get { if (_assetManager == null) { GetAsstesManger(); } return _assetManager; } }
        static AndroidJavaObject _assetManager;
        AndroidJavaObject stream;
        IntPtr METHOD_read;

        private static void GetAsstesManger()
        {
            AndroidJavaObject activityJO = new AndroidJavaClass("com.unity3d.player.UnityPlayer").GetStatic<AndroidJavaObject>("currentActivity");
            if (activityJO == null)
            {
                NLogger.Error("APKFileSystemStream GetAsstesManger Initial unityActivity Failed.");
            }

            //从Activity取得AssetManager实例
            _assetManager = activityJO.Call<AndroidJavaObject>("getAssets");
            if (_assetManager == null)
            {
                NLogger.Error("APKFileSystemStream GetAsstesManger Initial assetManager Failed.");
            }
        }
        
        private bool OpenApkFile(string fullPath)
        {
            //打开文件流
            stream = assetManager.Call<AndroidJavaObject>("open", fullPath);
            if (stream == null)
            {
                return false;
            }

            //取得InputStream.read的MethodID
            IntPtr clsPtr = AndroidJNI.FindClass("java/io/InputStream");
            if (clsPtr == IntPtr.Zero)
            {
                return false;
            }

            METHOD_read = AndroidJNIHelper.GetMethodID(clsPtr, "read", "([B)I");
            if (METHOD_read == IntPtr.Zero)
            {
                AndroidJNI.DeleteLocalRef(clsPtr);
                return false;
            }
            AndroidJNI.DeleteLocalRef(clsPtr);
            return true;
        }
#endif
        
        public APKFileSystemStream(string fullPath)
        {
            if (string.IsNullOrEmpty(fullPath))
            {
                throw new ArgumentException("Full path is invalid.");
            }
            
#if UNITY_ANDROID && !UNITY_EDITOR
            if (!OpenApkFile(fullPath))
            {
                NLogger.Error("APKFileSystemStream OpenApkFile Error " + fullPath);
            }
#endif
        }
        
        public long Length
        {
            get
            {
#if UNITY_ANDROID && !UNITY_EDITOR
                if (stream != null)
                {
                    return stream.Call<int>("available");
                }
                else
                {
                    return 0;
                }
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
            if (stream != null)
            {
                stream.Call("reset");
                while (offset > 0)
                {
                    long rsp = stream.Call<long>("skip", offset);
                    if (rsp == -1)
                    {
                        return;
                    }
                    offset -= rsp;
                }
            }
#endif
        }

        public unsafe int Read(IntPtr buffer, int length)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            if (stream != null && METHOD_read != IntPtr.Zero)
            {
                //申请一个Java ByteArray对象句柄
                IntPtr byteArray = AndroidJNI.NewByteArray(length);
                if (byteArray == IntPtr.Zero)
                    return -1;

                //调用方法
                int lengthRead = AndroidJNI.CallIntMethod(stream.GetRawObject(), METHOD_read, new[] { new jvalue() { l = byteArray } });
                if (lengthRead > 0)
                {
                    //byte[] bufferTmp = AndroidJNI.FromByteArray(byteArray);  //从Java ByteArray中得到C# byte数组
                    // Array.Copy(bufferTmp, buffer, lengthRead);

                    for (int i = 0; i < lengthRead; i++)
                    {
                        var bytePtr = (sbyte*)buffer.ToPointer();
                        bytePtr[i] = AndroidJNI.GetSByteArrayElement(byteArray, i);
                    }

                    AndroidJNI.DeleteLocalRef(byteArray);
                    return lengthRead;
                }
                else
                    AndroidJNI.DeleteLocalRef(byteArray);
            }
#endif


            return -1;
        }
        
        public int Read(byte[] buffer, int length)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            if (stream != null && METHOD_read != IntPtr.Zero)
            {
                //申请一个Java ByteArray对象句柄
                IntPtr byteArray = AndroidJNI.NewByteArray(length);
                if (byteArray == IntPtr.Zero)
                    return -1;

                //调用方法
                int lengthRead = AndroidJNI.CallIntMethod(stream.GetRawObject(), METHOD_read, new[] { new jvalue() { l = byteArray } });
                if (lengthRead > 0)
                {
                    byte[] bufferTmp = AndroidJNI.FromByteArray(byteArray);  //从Java ByteArray中得到C# byte数组
                    Array.Copy(bufferTmp, buffer, lengthRead);
                    AndroidJNI.DeleteLocalRef(byteArray);
                    return lengthRead;
                }
                else
                    AndroidJNI.DeleteLocalRef(byteArray);
            }
#endif
            return -1;
        }

        public int Read(Stream stream, int length)
        {
            int bytesRead;
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
            if (stream != null)
            {
                //关闭文件流
                stream.Call("close");
                stream.Dispose();
                stream = null;
            }
#endif
        }
    }
}
