using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace DragonReborn
{
    [Flags]
    public enum FileSystemAccess
    {
        Read = 1,
        Write = 2,
        ReadWrite = Write | Read, // 0x00000003
    }
    
    [Flags]
    public enum FileSystemPathType
    {
        StreamingAssetsPath = 1,
        PersistentDataPath = 2,
    }

    public readonly struct FileEntryInfo
    {
        public readonly string Name;
        public readonly long Offset;
        public readonly int Length;

        public FileEntryInfo(string name, long offset, int length)
        {
            Name = name;
            Offset = offset;
            Length = length;
        }

        public bool IsValid => !string.IsNullOrEmpty(Name) && Offset >= 0L && Length >= 0;
    }

    public partial class FileSystem : IFileSystem
    {
        private const int ClusterSize = 1024 * 4;
        private const int CachedBytesLength = 0x1000;

        private static readonly byte[] s_CachedBytes = new byte[CachedBytesLength];

        private static readonly int HeaderDataSize = Marshal.SizeOf(typeof(HeaderData));
        private static readonly int BlockDataSize = Marshal.SizeOf(typeof(BlockData));
        private static readonly int StringDataSize = Marshal.SizeOf(typeof(StringData));

        private readonly string m_FullPath;
        private readonly FileSystemAccess m_Access;
        private readonly IFileSystemStream m_Stream;
        private readonly Dictionary<string, int> m_FileDatas;
        private readonly List<BlockData> m_BlockDatas;
        private readonly MultiValueDictionary<int, int> m_FreeBlockIndexes;
        private readonly SortedDictionary<int, StringData> m_StringDatas;
        private readonly Queue<int> m_FreeStringIndexes;
        private readonly Queue<StringData> m_FreeStringDatas;

        private HeaderData m_HeaderData;
        private int m_BlockDataOffset;
        private int m_StringDataOffset;
        private int m_FileDataOffset;

        private FileSystem(string fullPath, FileSystemAccess access, IFileSystemStream systemStream)
        {
            m_FullPath = fullPath;
            m_Access = access;
            m_Stream = systemStream;
            m_FileDatas = new Dictionary<string, int>(StringComparer.Ordinal);
            m_BlockDatas = new List<BlockData>();
            m_FreeBlockIndexes = new MultiValueDictionary<int, int>();
            m_StringDatas = new SortedDictionary<int, StringData>();
            m_FreeStringIndexes = new Queue<int>();
            m_FreeStringDatas = new Queue<StringData>();

            m_HeaderData = default(HeaderData);
            m_BlockDataOffset = 0;
            m_StringDataOffset = 0;
            m_FileDataOffset = 0;

            MarshalUtils.EnsureCachedHGlobalSize(CachedBytesLength);
        }

        public string FullPath
        {
            get { return m_FullPath; }
        }

        public FileSystemAccess Access
        {
            get { return m_Access; }
        }

        public int FileCount
        {
            get { return m_FileDatas.Count; }
        }

        public int MaxFileCount
        {
            get { return m_HeaderData.MaxFileCount; }
        }
        
        public int BlockCount
        {
            get { return m_HeaderData.BlockCount; }
        }
        
        public int MaxBlockCount
        {
            get { return m_HeaderData.MaxBlockCount; }
        }

        public static FileSystem Create(string fullPath, FileSystemAccess access, IFileSystemStream stream, int maxFileCount, int maxBlockCount)
        {
            if (maxFileCount <= 0 || maxBlockCount <= 0)
            {
                return null;
            }

            FileSystem fileSystem = new FileSystem(fullPath, access, stream) {m_HeaderData = new HeaderData(maxFileCount, maxBlockCount)};
            CalcOffsets(fileSystem);
            MarshalUtils.StructureToBytes(fileSystem.m_HeaderData, HeaderDataSize, s_CachedBytes);

            try
            {
                stream.Write(s_CachedBytes, HeaderDataSize);
                stream.SetLength(fileSystem.m_FileDataOffset);
                return fileSystem;
            }
            catch
            {
                fileSystem.Shutdown();
                return null;
            }
        }

        public static FileSystem Load(string fullPath, FileSystemAccess access, IFileSystemStream stream)
        {
            FileSystem fileSystem = new FileSystem(fullPath, access, stream);

            stream.Read(s_CachedBytes, HeaderDataSize);

            fileSystem.m_HeaderData = MarshalUtils.BytesToStructure<HeaderData>(HeaderDataSize, s_CachedBytes);
            if (!fileSystem.m_HeaderData.IsValid)
            {
                return null;
            }

            CalcOffsets(fileSystem);

            if (fileSystem.m_BlockDatas.Capacity < fileSystem.m_HeaderData.BlockCount)
            {
                fileSystem.m_BlockDatas.Capacity = fileSystem.m_HeaderData.BlockCount;
            }

            for (int i = 0; i < fileSystem.m_HeaderData.BlockCount; i++)
            {
                stream.Read(s_CachedBytes, BlockDataSize);
                BlockData blockData = MarshalUtils.BytesToStructure<BlockData>(BlockDataSize, s_CachedBytes);
                fileSystem.m_BlockDatas.Add(blockData);
            }

            for (int i = 0; i < fileSystem.m_BlockDatas.Count; i++)
            {
                BlockData blockData = fileSystem.m_BlockDatas[i];
                if (blockData.Using)
                {
                    StringData stringData = fileSystem.ReadStringData(blockData.StringIndex);
                    fileSystem.m_StringDatas.Add(blockData.StringIndex, stringData);
                    fileSystem.m_FileDatas.Add(stringData.GetString(), i);
                }
                else
                {
                    fileSystem.m_FreeBlockIndexes.Add(blockData.Length, i);
                }
            }

            int index = 0;
            foreach (KeyValuePair<int, StringData> i in fileSystem.m_StringDatas)
            {
                while (index < i.Key)
                {
                    fileSystem.m_FreeStringIndexes.Enqueue(index++);
                }

                index++;
            }

            return fileSystem;
        }

        public void Shutdown()
        {
            m_Stream.Close();

            m_FileDatas.Clear();
            m_BlockDatas.Clear();
            m_FreeBlockIndexes.Clear();
            m_StringDatas.Clear();
            m_FreeStringIndexes.Clear();
            m_FreeStringDatas.Clear();

            m_BlockDataOffset = 0;
            m_StringDataOffset = 0;
            m_FileDataOffset = 0;
        }

        public FileEntryInfo GetFileInfo(string name)
        {
            if (!m_FileDatas.TryGetValue(name, out var blockIndex))
            {
                return default(FileEntryInfo);
            }

            BlockData blockData = m_BlockDatas[blockIndex];
            return new FileEntryInfo(name, GetClusterOffset(blockData.ClusterIndex), blockData.Length);
        }
        
        public FileEntryInfo[] GetAllFileInfos()
        {
            int index = 0;
            FileEntryInfo[] results = new FileEntryInfo[m_FileDatas.Count];
            foreach (KeyValuePair<string, int> fileData in m_FileDatas)
            {
                BlockData blockData = m_BlockDatas[fileData.Value];
                results[index++] = new FileEntryInfo(fileData.Key, GetClusterOffset(blockData.ClusterIndex), blockData.Length);
            }

            return results;
        }

        public bool HasFile(string name)
        {
            return m_FileDatas.ContainsKey(name);
        }

        public void ReadFile(string name, IntPtr buffer, int readStartOffset, int readLength)
        {
            if (m_Access != FileSystemAccess.Read && m_Access != FileSystemAccess.ReadWrite)
            {
                return;
            }

            FileEntryInfo fileEntryInfo = GetFileInfo(name);
            if (!fileEntryInfo.IsValid)
            {
                return;
            }

            if (readStartOffset + readLength > fileEntryInfo.Length)
            {
                NLogger.Error($"ReadFile {name}, read length exceed {readStartOffset} + {readLength} bigger than {fileEntryInfo.Length}");
                return;
            }

            int length = fileEntryInfo.Length;
            if (length > 0)
            {
                m_Stream.Seek(fileEntryInfo.Offset + readStartOffset);
                m_Stream.Read(buffer, readLength);
            }
        }

        public byte[] ReadFile(string name)
        {
            if (m_Access != FileSystemAccess.Read && m_Access != FileSystemAccess.ReadWrite)
            {
                return null;
            }

            FileEntryInfo fileEntryInfo = GetFileInfo(name);
            if (!fileEntryInfo.IsValid)
            {
                return null;
            }

            int length = fileEntryInfo.Length;
            byte[] buffer = new byte[length];
            if (length > 0)
            {
                m_Stream.Seek(fileEntryInfo.Offset);
                m_Stream.Read(buffer, length);
            }

            return buffer;
        }

        public bool WriteFile(string name, Stream stream)
        {
            if (m_Access != FileSystemAccess.Write && m_Access != FileSystemAccess.ReadWrite)
            {
                return false;
            }

            if (name.Length > byte.MaxValue)
            {
                return false;
            }

            if (stream == null || !stream.CanRead)
            {
                return false;
            }
            
            bool hasFile = m_FileDatas.TryGetValue(name, out var oldBlockIndex);

            if (!hasFile && m_FileDatas.Count >= m_HeaderData.MaxFileCount)
            {
                NLogger.Error($"[FileSystem] WriteFile {name} error, exceed MaxFileCount {m_HeaderData.MaxFileCount}");
                return false;
            }

            int length = (int)(stream.Length - stream.Position);
            int blockIndex = AllocBlock(length);
            if (blockIndex < 0)
            {
                return false;
            }

            if (length > 0)
            {
                m_Stream.Seek(GetClusterOffset(m_BlockDatas[blockIndex].ClusterIndex));
                m_Stream.Write(stream, length);
            }

            ProcessWriteFile(name, hasFile, oldBlockIndex, blockIndex, length);
            m_Stream.Flush();
            return true;
        }
        
        public bool WriteFile(string name, string filePath)
        {
            if (!File.Exists(filePath))
            {
                return false;
            }

            using (FileStream fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                return WriteFile(name, fileStream);
            }
        }
        
        public bool DeleteFile(string name)
        {
            if (m_Access != FileSystemAccess.Write && m_Access != FileSystemAccess.ReadWrite)
            {
                return false;
            }

            if (!m_FileDatas.TryGetValue(name, out var blockIndex))
            {
                return false;
            }

            m_FileDatas.Remove(name);

            BlockData blockData = m_BlockDatas[blockIndex];
            int stringIndex = blockData.StringIndex;
            StringData stringData = m_StringDatas[stringIndex].Clear();
            m_FreeStringIndexes.Enqueue(stringIndex);
            m_FreeStringDatas.Enqueue(stringData);
            m_StringDatas.Remove(stringIndex);
            WriteStringData(stringIndex, stringData);

            blockData = blockData.Free();
            m_BlockDatas[blockIndex] = blockData;
            if (!TryCombineFreeBlocks(blockIndex))
            {
                m_FreeBlockIndexes.Add(blockData.Length, blockIndex);
                WriteBlockData(blockIndex);
            }

            m_Stream.Flush();
            return true;
        }
        
        public bool SaveAsFile(string name, string filePath)
        {
            if (m_Access != FileSystemAccess.Read && m_Access != FileSystemAccess.ReadWrite)
            {
                return false;
            }

            if (string.IsNullOrEmpty(name) || string.IsNullOrEmpty(filePath))
            {
                 return false;
            }
            
            FileEntryInfo fileEntryInfo = GetFileInfo(name);
            if (!fileEntryInfo.IsValid)
            {
                return false;
            }

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }

            string directory = Path.GetDirectoryName(filePath);
            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            using (FileStream fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                int length = fileEntryInfo.Length;
                if (length > 0)
                {
                    m_Stream.Seek(fileEntryInfo.Offset);
                    return m_Stream.Read(fileStream, length) == length;
                }
                return true;
            }
        }

        private int AllocBlock(int length)
        {
            if (length <= 0)
            {
                return GetEmptyBlockIndex();
            }
            
            length = (int) GetUpBoundClusterOffset(length);

            int lengthFound = -1;
            HashSet<int> lengthRange = default(HashSet<int>);
            foreach (KeyValuePair<int, HashSet<int>> i in m_FreeBlockIndexes)
            {
                if (i.Key < length)
                {
                    continue;
                }

                if (lengthFound >= 0 && lengthFound < i.Key)
                {
                    continue;
                }

                lengthFound = i.Key;
                lengthRange = i.Value;
            }

            if (lengthFound >= 0)
            {
                if (lengthFound > length && m_BlockDatas.Count >= m_HeaderData.MaxBlockCount)
                {
                    return -1;
                }

                int blockIndex = lengthRange.ElementAt(0);
                m_FreeBlockIndexes.Remove(lengthFound, blockIndex);
                if (lengthFound > length)
                {
                    BlockData blockData = m_BlockDatas[blockIndex];
                    m_BlockDatas[blockIndex] = new BlockData(blockData.ClusterIndex, length);
                    WriteBlockData(blockIndex);

                    int deltaLength = lengthFound - length;
                    int anotherBlockIndex = GetEmptyBlockIndex();
                    m_BlockDatas[anotherBlockIndex] = new BlockData(blockData.ClusterIndex + GetUpBoundClusterCount(length), deltaLength);
                    m_FreeBlockIndexes.Add(deltaLength, anotherBlockIndex);
                    WriteBlockData(anotherBlockIndex);
                }

                return blockIndex;
            }
            else
            {
                int blockIndex = GetEmptyBlockIndex();
                if (blockIndex < 0)
                {
                    return -1;
                }

                long fileLength = m_Stream.Length;
                try
                {
                    m_Stream.SetLength(fileLength + length);
                }
                catch
                {
                    return -1;
                }

                m_BlockDatas[blockIndex] = new BlockData(GetUpBoundClusterCount(fileLength), length);
                WriteBlockData(blockIndex);
                return blockIndex;
            }
        }

        private void ProcessWriteFile(string name, bool hasFile, int oldBlockIndex, int blockIndex, int length)
        {
            BlockData blockData = m_BlockDatas[blockIndex];
            if (hasFile)
            {
                BlockData oldBlockData = m_BlockDatas[oldBlockIndex];
                blockData = new BlockData(oldBlockData.StringIndex, blockData.ClusterIndex, length);
                m_BlockDatas[blockIndex] = blockData;
                WriteBlockData(blockIndex);

                oldBlockData = oldBlockData.Free();
                m_BlockDatas[oldBlockIndex] = oldBlockData;
                if (!TryCombineFreeBlocks(oldBlockIndex))
                {
                    m_FreeBlockIndexes.Add(oldBlockData.Length, oldBlockIndex);
                    WriteBlockData(oldBlockIndex);
                }
            }
            else
            {
                int stringIndex = AllocString(name);
                blockData = new BlockData(stringIndex, blockData.ClusterIndex, length);
                m_BlockDatas[blockIndex] = blockData;
                WriteBlockData(blockIndex);
            }

            if (hasFile)
            {
                m_FileDatas[name] = blockIndex;
            }
            else
            {
                m_FileDatas.Add(name, blockIndex);
            }
        }

        private int GetEmptyBlockIndex()
        {
            if (m_FreeBlockIndexes.TryGetValue(0, out var lengthRange))
            {
                int blockIndex = lengthRange.ElementAt(0);
                m_FreeBlockIndexes.Remove(0, blockIndex);
                return blockIndex;
            }

            if (m_BlockDatas.Count < m_HeaderData.MaxBlockCount)
            {
                int blockIndex = m_BlockDatas.Count;
                m_BlockDatas.Add(BlockData.Empty);
                WriteHeaderData();
                return blockIndex;
            }

            return -1;
        }

        private bool TryCombineFreeBlocks(int freeBlockIndex)
        {
            BlockData freeBlockData = m_BlockDatas[freeBlockIndex];
            if (freeBlockData.Length <= 0)
            {
                return false;
            }

            int previousFreeBlockIndex = -1;
            int nextFreeBlockIndex = -1;
            int nextBlockDataClusterIndex = freeBlockData.ClusterIndex + GetUpBoundClusterCount(freeBlockData.Length);
            foreach (KeyValuePair<int, HashSet<int>> blockIndexes in m_FreeBlockIndexes)
            {
                if (blockIndexes.Key <= 0)
                {
                    continue;
                }

                int blockDataClusterCount = GetUpBoundClusterCount(blockIndexes.Key);
                foreach (int blockIndex in blockIndexes.Value)
                {
                    BlockData blockData = m_BlockDatas[blockIndex];
                    if (blockData.ClusterIndex + blockDataClusterCount == freeBlockData.ClusterIndex)
                    {
                        previousFreeBlockIndex = blockIndex;
                    }
                    else if (blockData.ClusterIndex == nextBlockDataClusterIndex)
                    {
                        nextFreeBlockIndex = blockIndex;
                    }
                }
            }

            if (previousFreeBlockIndex < 0 && nextFreeBlockIndex < 0)
            {
                return false;
            }

            m_FreeBlockIndexes.Remove(freeBlockData.Length, freeBlockIndex);
            if (previousFreeBlockIndex >= 0)
            {
                BlockData previousFreeBlockData = m_BlockDatas[previousFreeBlockIndex];
                m_FreeBlockIndexes.Remove(previousFreeBlockData.Length, previousFreeBlockIndex);
                freeBlockData = new BlockData(previousFreeBlockData.ClusterIndex, previousFreeBlockData.Length + freeBlockData.Length);
                m_BlockDatas[previousFreeBlockIndex] = BlockData.Empty;
                m_FreeBlockIndexes.Add(0, previousFreeBlockIndex);
                WriteBlockData(previousFreeBlockIndex);
            }

            if (nextFreeBlockIndex >= 0)
            {
                BlockData nextFreeBlockData = m_BlockDatas[nextFreeBlockIndex];
                m_FreeBlockIndexes.Remove(nextFreeBlockData.Length, nextFreeBlockIndex);
                freeBlockData = new BlockData(freeBlockData.ClusterIndex, freeBlockData.Length + nextFreeBlockData.Length);
                m_BlockDatas[nextFreeBlockIndex] = BlockData.Empty;
                m_FreeBlockIndexes.Add(0, nextFreeBlockIndex);
                WriteBlockData(nextFreeBlockIndex);
            }

            m_BlockDatas[freeBlockIndex] = freeBlockData;
            m_FreeBlockIndexes.Add(freeBlockData.Length, freeBlockIndex);
            WriteBlockData(freeBlockIndex);
            return true;
        }

        private int AllocString(string value)
        {
            int stringIndex = -1;
            StringData stringData = default(StringData);

            if (m_FreeStringIndexes.Count > 0)
            {
                stringIndex = m_FreeStringIndexes.Dequeue();
            }
            else
            {
                stringIndex = m_StringDatas.Count;
            }

            if (m_FreeStringDatas.Count > 0)
            {
                stringData = m_FreeStringDatas.Dequeue();
            }
            else
            {
                byte[] bytes = new byte[byte.MaxValue];
                stringData = new StringData(0, bytes);
            }

            stringData = stringData.SetString(value);
            m_StringDatas.Add(stringIndex, stringData);
            WriteStringData(stringIndex, stringData);
            return stringIndex;
        }

        private void WriteHeaderData()
        {
            m_HeaderData = m_HeaderData.SetBlockCount(m_BlockDatas.Count);
            MarshalUtils.StructureToBytes(m_HeaderData, HeaderDataSize, s_CachedBytes);
            m_Stream.Seek(0L);
            m_Stream.Write(s_CachedBytes, HeaderDataSize);
        }

        private void WriteBlockData(int blockIndex)
        {
            MarshalUtils.StructureToBytes(m_BlockDatas[blockIndex], BlockDataSize, s_CachedBytes);
            m_Stream.Seek(m_BlockDataOffset + BlockDataSize * blockIndex);
            m_Stream.Write(s_CachedBytes, BlockDataSize);
        }

        private void WriteStringData(int stringIndex, StringData stringData)
        {
            MarshalUtils.StructureToBytes(stringData, StringDataSize, s_CachedBytes);
            m_Stream.Seek(m_StringDataOffset + StringDataSize * stringIndex);
            m_Stream.Write(s_CachedBytes, StringDataSize);
        }

        private StringData ReadStringData(int stringIndex)
        {
            m_Stream.Seek(m_StringDataOffset + StringDataSize * stringIndex);
            m_Stream.Read(s_CachedBytes, StringDataSize);
            return MarshalUtils.BytesToStructure<StringData>(StringDataSize, s_CachedBytes);
        }

        private static void CalcOffsets(FileSystem fileSystem)
        {
            fileSystem.m_BlockDataOffset = HeaderDataSize;
            fileSystem.m_StringDataOffset = fileSystem.m_BlockDataOffset + BlockDataSize * fileSystem.m_HeaderData.MaxBlockCount;
            fileSystem.m_FileDataOffset = (int) GetUpBoundClusterOffset(fileSystem.m_StringDataOffset + StringDataSize * fileSystem.m_HeaderData.MaxFileCount);
        }

        private static long GetUpBoundClusterOffset(long offset)
        {
            return (offset - 1L + ClusterSize) / ClusterSize * ClusterSize;
        }

        private static int GetUpBoundClusterCount(long length)
        {
            return (int) ((length - 1L + ClusterSize) / ClusterSize);
        }

        private static long GetClusterOffset(int clusterIndex)
        {
            return (long) ClusterSize * clusterIndex;
        }
    }
}