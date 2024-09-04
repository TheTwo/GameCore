using System;
using System.IO;
using System.Runtime.InteropServices;

namespace DragonReborn
{
    public sealed class CommonFileSystemStream : IFileSystemStream
    {
#if UNITY_EDITOR
	    private FileStream m_FileStream;
#else
        private readonly FileStream m_FileStream;
#endif
        
        private const int CachedBytesLength = 0x1000;
		private static readonly byte[] s_CachedBytes = new byte[CachedBytesLength];
        
        public CommonFileSystemStream(string fullPath, FileSystemAccess access, bool createNew)
        {
            switch (access)
            {
                case FileSystemAccess.Read:
                    m_FileStream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
                    break;

                case FileSystemAccess.Write:
                    m_FileStream = new FileStream(fullPath, createNew ? FileMode.Create : FileMode.Open, FileAccess.Write, FileShare.Read);
                    break;

                case FileSystemAccess.ReadWrite:
                    m_FileStream = new FileStream(fullPath, createNew ? FileMode.Create : FileMode.Open, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete);
                    break;
            }
        }
        
        public long Length
        {
            get
            {
                return m_FileStream.Length;
            }
        }
        
        public void SetLength(long length)
        {
            m_FileStream.SetLength(length);
        }

        public void Seek(long offset)
        {
            m_FileStream.Seek(offset, SeekOrigin.Begin);
        }


        public unsafe int Read(IntPtr buffer, int length)
        {
            int bytesRead = 0;
            int bytesLeft = length;
            byte* dst = (byte *)buffer.ToPointer();

            while ((bytesRead = Read(s_CachedBytes, bytesLeft < CachedBytesLength ? bytesLeft : CachedBytesLength)) > 0)
            {
                fixed (byte* src = s_CachedBytes) 
                {
                    Buffer.MemoryCopy(src, dst, bytesLeft, bytesRead);
                    dst += bytesRead;
                }

                bytesLeft -= bytesRead;
            }

            Array.Clear(s_CachedBytes, 0, CachedBytesLength);
            return length - bytesLeft;
        }

        public int Read(byte[] buffer, int length)
        {
            return m_FileStream.Read(buffer, 0, length);
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
            m_FileStream.Write(buffer, 0, length);
        }

        public void Write(Stream stream, int length)
        {
            int bytesRead;
            int bytesLeft = length;
            while ((bytesRead = stream.Read(s_CachedBytes, 0, bytesLeft < CachedBytesLength ? bytesLeft : CachedBytesLength)) > 0)
            {
                bytesLeft -= bytesRead;
                Write(s_CachedBytes, bytesRead);
            }

            Array.Clear(s_CachedBytes, 0, CachedBytesLength);
        }

        public void Flush()
        {
            m_FileStream.Flush();
        }
        
        public void Close()
        {
#if UNITY_EDITOR
	        m_FileStream?.Close();
	        m_FileStream?.Dispose();
	        m_FileStream = null;
#else
            m_FileStream.Close();
#endif
        }
    }
}
