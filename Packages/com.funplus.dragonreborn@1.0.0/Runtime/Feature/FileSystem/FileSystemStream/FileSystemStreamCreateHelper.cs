using System;
using System.IO;
using UnityEngine;

namespace DragonReborn
{
    public class FileSystemStreamCreateHelper : IFileSystemStreamCreateHelper
    {
        private static readonly string PersistentDataPath = Application.persistentDataPath;
        private static readonly string StreamingAssetsPath = Application.streamingAssetsPath;
        
        public IFileSystemStream CreateFileSystemStream(string fullPath, FileSystemAccess access, bool createNew)
        {
            IFileSystemStream systemStream = null;
            try
            {
                if (access == FileSystemAccess.Read)
                {
#if !UNITY_EDITOR && UNITY_ANDROID
                    if (UseNativeApkFileStream())
                    {
                        systemStream = new APKFileSystemStreamNative(fullPath);
                    }
                    else
                    {
                        systemStream = new APKFileSystemStream(fullPath);
                    }
#else
                    systemStream = new CommonFileSystemStream(fullPath, access, createNew);
#endif
                }
                else
                {
                    systemStream = new CommonFileSystemStream(fullPath, access, createNew);
                }
            }
            catch (Exception e)
            {
                NLogger.Error("FileSystemStreamCreateHelper CreateFileSystemStream Exception:{0}", e.ToString());
            }
            return systemStream;
        }
        
        public string GetFileSystemFullPath(string relativePath, FileSystemPathType pathType)
        {
            var fullPath = string.Empty;
            if (pathType == FileSystemPathType.StreamingAssetsPath)
            {
#if !UNITY_EDITOR && UNITY_ANDROID
                fullPath = relativePath;
#else
                fullPath = AssetPath.Combine(StreamingAssetsPath, relativePath);
#endif
            }
            else
            {
                fullPath = AssetPath.Combine(PersistentDataPath, relativePath);
            }

            return fullPath;
        }

        public bool HasFileSystemAsset(string relativePath, FileSystemPathType pathType)
        {
            if (pathType == FileSystemPathType.StreamingAssetsPath)
            {
                return IOUtils.HaveBundleAssetInPackage(relativePath);
            }
            
            return IOUtils.HaveBundleAssetInDocument(relativePath);
        }

        // ReSharper disable once UnusedMember.Local
        private bool UseNativeApkFileStream()
        {
            return true;
        }
    }
}
