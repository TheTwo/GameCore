namespace DragonReborn
{
    public interface IFileSystemStreamCreateHelper
    {
        IFileSystemStream CreateFileSystemStream(string fullPath, FileSystemAccess access, bool createNew);
        
        string GetFileSystemFullPath(string relativePath, FileSystemPathType pathType);
        
        bool HasFileSystemAsset(string relativePath, FileSystemPathType pathType);
    }
}