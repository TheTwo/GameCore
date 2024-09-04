using System;
using System.IO;

namespace DragonReborn
{
    public interface IFileSystem
    {
        string FullPath { get; }

        FileSystemAccess Access { get; }

        int FileCount { get; }

        int MaxFileCount { get; }
        
        int BlockCount { get; }
        
        int MaxBlockCount { get; }

        FileEntryInfo GetFileInfo(string name);
        
        FileEntryInfo[] GetAllFileInfos();

        bool HasFile(string name);

        byte[] ReadFile(string name);

        void ReadFile(string name, IntPtr buffer, int offset, int length);

        bool WriteFile(string name, Stream stream);
        
        bool WriteFile(string name, string filePath);
        
        bool DeleteFile(string name);
        
        bool SaveAsFile(string name, string filePath);

        void Shutdown();
    }
}