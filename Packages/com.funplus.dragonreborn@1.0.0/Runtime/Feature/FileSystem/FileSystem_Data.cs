using System;
using System.Runtime.InteropServices;

namespace DragonReborn
{
    public partial class FileSystem : IFileSystem
    {
        private static readonly uint HEAD_FLAG = 0x534F5300; //'S' 'O' 'S'
        
        [StructLayout(LayoutKind.Sequential)]
        private struct HeaderData
        {
            private readonly uint m_Identity;
            private readonly int m_MaxFileCount;
            private readonly int m_MaxBlockCount;
            private readonly int m_BlockCount;
            
            public HeaderData(int maxFileCount, int maxBlockCount)
                : this(maxFileCount, maxBlockCount, 0)
            {
                
            }
            
            public HeaderData(int maxFileCount, int maxBlockCount, int blockCount)
            {
                m_Identity = HEAD_FLAG;
                m_MaxFileCount = maxFileCount;
                m_MaxBlockCount = maxBlockCount;
                m_BlockCount = blockCount;
            }

            public int BlockCount
            {
                get
                {
                    return m_BlockCount;
                }
            }
            
            public int MaxBlockCount
            {
                get
                {
                    return m_MaxBlockCount;
                }
            }
            
            public int MaxFileCount
            {
                get
                {
                    return m_MaxFileCount;
                }
            }
            
            public bool IsValid
            {
                get
                {
                    return m_Identity == HEAD_FLAG && m_MaxFileCount > 0 && m_MaxBlockCount > 0 && m_MaxFileCount <= m_MaxBlockCount && m_BlockCount > 0 && m_BlockCount <= m_MaxBlockCount;
                }
            }
            
            public HeaderData SetBlockCount(int blockCount)
            {
                return new HeaderData(m_MaxFileCount, m_MaxBlockCount, blockCount);
            }
        }


        [StructLayout(LayoutKind.Sequential)]
        private struct BlockData
        {
            public static readonly BlockData Empty = new BlockData(0, 0);
            
            private readonly int m_StringIndex;
            private readonly int m_ClusterIndex;
            private readonly int m_Length;
            
            public BlockData(int clusterIndex, int length)
                : this(-1, clusterIndex, length)
            {
            }

            public BlockData(int stringIndex, int clusterIndex, int length)
            {
                m_StringIndex = stringIndex;
                m_ClusterIndex = clusterIndex;
                m_Length = length;
            }
            
            public bool Using
            {
                get
                {
                    return m_StringIndex >= 0;
                }
            }

            public int StringIndex
            {
                get
                {
                    return m_StringIndex;
                }
            }

            public int ClusterIndex
            {
                get
                {
                    return m_ClusterIndex;
                }
            }

            public int Length
            {
                get
                {
                    return m_Length;
                }
            }
            
            public BlockData Free()
            {
                return new BlockData(m_ClusterIndex, (int)GetUpBoundClusterOffset(m_Length));
            }
        }
        
        [StructLayout(LayoutKind.Sequential)]
        private struct StringData
        {
            private static readonly byte[] s_CachedBytes = new byte[byte.MaxValue + 1];

            private readonly byte m_Length;

            [MarshalAs(UnmanagedType.ByValArray, SizeConst = byte.MaxValue)]
            private readonly byte[] m_Bytes;

            public StringData(byte length, byte[] bytes)
            {
                m_Length = length;
                m_Bytes = bytes;
            }

            public string GetString()
            {
                if (m_Length <= 0)
                {
                    return null;
                }
                
                Array.Copy(m_Bytes, 0, s_CachedBytes, 0, m_Length);
                return System.Text.Encoding.UTF8.GetString(s_CachedBytes, 0, m_Length);
            }

            public StringData SetString(string value)
            {
                if (string.IsNullOrEmpty(value))
                {
                    return Clear();
                }

                int length = System.Text.Encoding.UTF8.GetBytes(value, 0, value.Length, s_CachedBytes, 0);
                if (length > byte.MaxValue)
                {
                    throw new ArgumentException(string.Format("String '{0}' is too long.", value));
                }
                
                Array.Copy(s_CachedBytes, 0, m_Bytes, 0, length);
                return new StringData((byte)length, m_Bytes);
            }
            
            public StringData Clear()
            {
                return new StringData(0, m_Bytes);
            }
        }
    }
}