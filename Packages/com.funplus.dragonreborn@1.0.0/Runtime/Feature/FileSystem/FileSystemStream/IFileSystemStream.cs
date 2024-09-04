using System;
using System.IO;

namespace DragonReborn
{
    public interface IFileSystemStream
    {
        long Length { get; }

        void SetLength(long length);

        void Seek(long offset);

        int Read(IntPtr buffer, int length);

        int Read(byte[] buffer, int length);

        int Read(Stream stream, int length);

        void Write(byte[] buffer, int length);

        void Write(Stream stream, int length);

        void Flush();

        void Close();
    }
}
