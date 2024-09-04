using System;
using System.Collections.Generic;

namespace DragonReborn
{
    public class FileSystemManager : Singleton<FileSystemManager>, IManager
    {
        private readonly Dictionary<string, IFileSystem> m_ReadOnlyFileSystems = new Dictionary<string, IFileSystem>();
        private readonly Dictionary<string, IFileSystem> m_ReadWriteFileSystems = new Dictionary<string, IFileSystem>();

        private IFileSystemStreamCreateHelper m_StreamCreateHelper = new FileSystemStreamCreateHelper();
        
        public static int DefaultFileMaxCount = 2048;
        public static int DefaultBlockMaxCount = 4096;

        public void OnGameInitialize(object configParam)
        {
            
        }

        public void Reset()
        {
            Clean();
        }

        private void Clean()
        {
            foreach (var pair in m_ReadOnlyFileSystems)
            {
                pair.Value.Shutdown();
            }
            m_ReadOnlyFileSystems.Clear();

            foreach (var pair in m_ReadWriteFileSystems)
            {
                pair.Value.Shutdown();
            }
            m_ReadWriteFileSystems.Clear();
        }

        public bool HasFile(string relativePath, string fileName, bool externalStorageOnly = false)
        {
            var fileInfo = GetFileInfo(relativePath, fileName, out var inDocument, externalStorageOnly);
            if (fileInfo.IsValid)
            {
                return true;
            }
            
            return false;
        }

        public FileEntryInfo GetFileInfo(string relativePath, string fileName, out bool inDocument, bool externalStorageOnly = false)
        {
            inDocument = false;
            
            FileEntryInfo entryInfo = default(FileEntryInfo);

            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                entryInfo = fileSystem.GetFileInfo(fileName);
                if (entryInfo.IsValid)
                {
                    inDocument = true;
                    return entryInfo;
                }
            }

            if (externalStorageOnly)
            {
                return entryInfo;
            }

            fileSystem = GetFileSystemInPackage(relativePath);
            if (fileSystem != null)
            {
                entryInfo = fileSystem.GetFileInfo(fileName);
            }
            
            return entryInfo;
        }

        private readonly HashSet<string> _filesInDocumentNameSet = new HashSet<string>();
        public List<FileEntryInfo> GetAllFileInfos(string relativePath, bool externalStorageOnly = false)
        {
            List<FileEntryInfo> list = new List<FileEntryInfo>();
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                list.AddRange(fileSystem.GetAllFileInfos());
            }

            if (externalStorageOnly)
            {
                return list;
            }
            
            fileSystem = GetFileSystemInPackage(relativePath);
            if (fileSystem != null)
            {
                _filesInDocumentNameSet.Clear();
                foreach (var infoInDocument in list)
                {
                    _filesInDocumentNameSet.Add(infoInDocument.Name);
                }
                
                //InDocument 的file 是最新的
                var infos = fileSystem.GetAllFileInfos();
                foreach (var info in infos)
                {
                    if (!_filesInDocumentNameSet.Contains(info.Name))
                    {
                        list.Add(info);
                    }
                }
            }
            
            return list;
        }

        /// <summary>
        /// 从pack中读文件到buff中
        /// </summary>
        /// <param name="relativePath">pack相对路径，GameAssets/...</param>
        /// <param name="fileName">pack中的文件名</param>
        /// <param name="buffer">需要</param>
        /// <param name="readStartOffset">从filename的offset处开始读</param>
        /// <param name="readLength">读取的长度</param>
        /// <param name="externalStorageOnly"></param>
        public void ReadFile(string relativePath, string fileName, IntPtr buffer, int readStartOffset, int readLength, bool externalStorageOnly = false)
        {
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                if (fileSystem.HasFile(fileName))
                {
                    fileSystem.ReadFile(fileName, buffer, readStartOffset, readLength);
                    return;
                }
            }

            if (externalStorageOnly)
            {
                return;
            }

            fileSystem = GetFileSystemInPackage(relativePath);
            if (fileSystem != null)
            {
                fileSystem.ReadFile(fileName, buffer, readStartOffset, readLength);
                return;
            }
        }

        public byte[] ReadFile(string relativePath, string fileName, bool externalStorageOnly = false)
        {
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                if (fileSystem.HasFile(fileName))
                {
                    return fileSystem.ReadFile(fileName);
                }
            }

            if (externalStorageOnly)
            {
                return null;
            }

            fileSystem = GetFileSystemInPackage(relativePath);
            if (fileSystem != null)
            {
                return fileSystem.ReadFile(fileName);
            }
            
            return null;
        }
        
        public bool ReadFile(IReadBuffer buffer, string relativePath, string fileName, out ReadOnlySpan<byte> readResult, bool externalStorageOnly = false)
        {
	        readResult = default;
	        var fileSystem = GetFileSystemInDocument(relativePath);
	        if (fileSystem != null)
	        {
		        if (fileSystem.HasFile(fileName))
		        {
			        var fileInfo = fileSystem.GetFileInfo(fileName);
			        var ptr = buffer.BeginReadPtr(fileInfo.Length);
			        try
			        {
				        fileSystem.ReadFile(fileName, ptr, 0, fileInfo.Length);
			        }
			        finally
			        {
				        readResult = buffer.EndReadPtr(ptr);
			        }
			        return !readResult.IsEmpty;
		        }
	        }

	        if (externalStorageOnly)
	        {
		        return false;
	        }

	        fileSystem = GetFileSystemInPackage(relativePath);
	        if (fileSystem != null)
	        {
		        var fileInfo = fileSystem.GetFileInfo(fileName);
		        var ptr = buffer.BeginReadPtr(fileInfo.Length);
		        try
		        {
			        fileSystem.ReadFile(fileName, ptr, 0, fileInfo.Length);
		        }
		        finally
		        {
			        readResult = buffer.EndReadPtr(ptr);
		        }
		        return !readResult.IsEmpty;
	        }
	        return false;
        }

        public bool WriteFile(string relativePath, string fileName, string filePath, bool createNew = true, int maxFileCount = 2048, int maxBlockCount = 4096)
        {
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                return fileSystem.WriteFile(fileName, filePath);
            }

            if (createNew)
            {
                fileSystem = CreateFileSystem(relativePath, FileSystemAccess.ReadWrite, maxFileCount, maxBlockCount);
                if (fileSystem != null)
                {
                    return fileSystem.WriteFile(fileName, filePath);
                }
            }
            return false;
        }

        public bool SaveAsFile(string relativePath, string fileName, string outFilePath, bool externalStorageOnly = false)
        {
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                if (fileSystem.HasFile(fileName))
                {
                    return fileSystem.SaveAsFile(fileName, outFilePath);
                }
            }

            if (externalStorageOnly)
            {
                return false;
            }

            fileSystem = GetFileSystemInPackage(relativePath);
            if (fileSystem != null)
            {
                return fileSystem.SaveAsFile(fileName, outFilePath);
            }
            
            return false;
        }
        
        public bool DeleteFile(string relativePath, string fileName)
        {
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                return fileSystem.DeleteFile(fileName);
            }
            return false;
        }

        public bool HasFileSystem(string relativePath, bool externalStorageOnly = false)
        {
            if (string.IsNullOrEmpty(relativePath))
            {
                return false;
            }
            
            if (GetFileSystemInDocument(relativePath) != null)
            {
                return true;
            }

            if (externalStorageOnly)
            {
                return false;
            }

            return GetFileSystemInPackage(relativePath) != null;
        }

        public IFileSystem EnsureFileSystemInDocument(string relativePath)
        {
            var fileSystem = GetFileSystemInDocument(relativePath);
            if (fileSystem != null)
            {
                return fileSystem;
            }

            int maxFileCount = DefaultFileMaxCount;
            int maxBlockCount = DefaultBlockMaxCount;
            var fileSystemInPackage = GetFileSystemInPackage(relativePath);
            if (fileSystemInPackage != null)
            {
                maxFileCount = fileSystemInPackage.MaxFileCount;
                maxBlockCount = fileSystemInPackage.MaxBlockCount;
            }

            return CreateFileSystem(relativePath, FileSystemAccess.ReadWrite, maxFileCount, maxBlockCount);
        }

        public IFileSystem CreateFileSystem(string relativePath, FileSystemAccess access, int maxFileCount, int maxBlockCount)
        {
            if (m_StreamCreateHelper == null)
            {
                return null;
            }

            if (string.IsNullOrEmpty(relativePath))
            {
                return null;
            }

            IFileSystem retFileSystem = GetFileSystemInDocument(relativePath);
            if (retFileSystem != null)
            {
                return retFileSystem;
            }
            
            var fullPath = m_StreamCreateHelper.GetFileSystemFullPath(relativePath, FileSystemPathType.PersistentDataPath);
            IFileSystemStream fileSystemStream = m_StreamCreateHelper.CreateFileSystemStream(fullPath, access, true);
            if (fileSystemStream == null)
            {
                return null;
            }

            retFileSystem = FileSystem.Create(fullPath, access, fileSystemStream, maxFileCount, maxBlockCount);
            if (retFileSystem == null)
            {
                fileSystemStream.Close();
                return null;
            }

            m_ReadWriteFileSystems.Add(relativePath, retFileSystem);
            
            return retFileSystem;
        }
        
        private IFileSystem GetFileSystemInPackage(string relativePath)
        {
            if (string.IsNullOrEmpty(relativePath))
            {
                return null;
            }

            IFileSystem fileSystem = null;
            if (!m_ReadOnlyFileSystems.TryGetValue(relativePath, out fileSystem))
            {
                fileSystem = LoadFileSystem(relativePath, FileSystemPathType.StreamingAssetsPath, FileSystemAccess.Read);
                if (fileSystem != null)
                {
                    m_ReadOnlyFileSystems.Add(relativePath, fileSystem);
                }
            }
            
            return fileSystem;
        }
        
        private IFileSystem GetFileSystemInDocument(string relativePath)
        {
            if (string.IsNullOrEmpty(relativePath))
            {
                return null;
            }

            IFileSystem fileSystem = null;
            
            if (!m_ReadWriteFileSystems.TryGetValue(relativePath, out fileSystem))
            {
                fileSystem = LoadFileSystem(relativePath, FileSystemPathType.PersistentDataPath, FileSystemAccess.ReadWrite);
                if (fileSystem != null)
                {
                    m_ReadWriteFileSystems.Add(relativePath, fileSystem);
                }
            }
            
            return fileSystem;
        }

        private IFileSystem LoadFileSystem(string relativePath, FileSystemPathType pathType, FileSystemAccess access)
        {
            if (string.IsNullOrEmpty(relativePath))
            {
                return null;
            }

            if (!m_StreamCreateHelper.HasFileSystemAsset(relativePath, pathType))
            {
                return null;
            }

            var fullPath = m_StreamCreateHelper.GetFileSystemFullPath(relativePath, pathType);
            IFileSystemStream fileSystemStream = m_StreamCreateHelper.CreateFileSystemStream(fullPath, access, false);
            if (fileSystemStream == null)
            {
                return null;
            }

            FileSystem fileSystem = FileSystem.Load(fullPath, access, fileSystemStream);
            if (fileSystem == null)
            {
                fileSystemStream.Close();
                return null;
            }

            return fileSystem;
        }

		public void OnLowMemory()
		{

		}
	}
}
