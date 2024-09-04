using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;

namespace DragonReborn.Utilities.Editor
{
    /// <summary>
    ///   Util class to find asset in project
    /// </summary>
    public class FileUtility
    {
        /// <summary>
        /// Determine whether a given path is a directory.
        /// </summary>
        public static bool PathIsDirectory (string absolutePath)
        {
            FileAttributes attr = File.GetAttributes(absolutePath);
            if ((attr & FileAttributes.Directory) == FileAttributes.Directory)
                return true;
            else
                return false;
        }


        /// <summary>
        /// Given an absolute path, return a path rooted at the Assets folder.
        /// </summary>
        /// <remarks>
        /// Asset relative paths can only be used in the editor. They will break in builds.
        /// </remarks>
        /// <example>
        /// /Folder/UnityProject/Assets/resources/music returns Assets/resources/music
        /// </example>
        public static string AssetsRelativePath (string absolutePath)
        {
            if (absolutePath.StartsWith(Application.dataPath)) {
                return "Assets" + absolutePath.Substring(Application.dataPath.Length);
            }
            else {
                throw new System.ArgumentException("Full path does not contain the current project's Assets folder", "absolutePath");
            }
        }


        /// <summary>
        /// Get all available Resources directory paths within the current project.
        /// </summary>
        public static string[] GetResourcesDirectories ()
        {
            List<string> result = new List<string>();
            Stack<string> stack = new Stack<string>();
            // Add the root directory to the stack
            stack.Push(Application.dataPath);
            // While we have directories to process...
            while (stack.Count > 0) {
                // Grab a directory off the stack
                string currentDir = stack.Pop();
                try {
                    foreach (string dir in Directory.GetDirectories(currentDir)) {
                        if (Path.GetFileName(dir).Equals("Resources")) {
                            // If one of the found directories is a Resources dir, add it to the result
                            result.Add(dir);
                        }
                        // Add directories at the current level into the stack
                        stack.Push(dir);
                    }
                }
                catch {
                    Debug.LogError("Directory " + currentDir + " couldn't be read from.");
                }
            }
            return result.ToArray();
        }

        public static List<string> GetAllResources(string dirPath,string rootPath)
        {
            if(string.IsNullOrEmpty(dirPath))
            {
                Debug.LogError("dirPath is null or empty");
                return null;
            }

    		string fullPath = Path.Combine(rootPath,dirPath);

    		if(!Directory.Exists(fullPath))
            {
                Debug.LogError("dirPath not exitst.");
            }

    		DirectoryInfo dir = new DirectoryInfo(fullPath);

            FileInfo[] fileInfo = dir.GetFiles("*.*", SearchOption.AllDirectories);

            List<string> resList = new List<string>();

            foreach (FileInfo file in fileInfo)
            {
    			if(file.Name[0] == '.')
    			{
    				continue;
    			}

                if (file.Extension == ".meta")
                {
                    continue;
                }

                //resList.Add(file.FullName.Replace(rootPath, string.Empty));
                resList.Add(file.FullName.Substring(file.FullName.IndexOf("Assets")));
            }

            return resList;
        }

        public static void CopyFodlerToTarget(string source, string target, List<string> exclude = null)
        {
            if(Directory.Exists(target))
            {
                Directory.Delete(target, true);
            }

            //Now Create all of the directories
            foreach (string dirPath in Directory.GetDirectories(source, "*", 
                SearchOption.AllDirectories))
                Directory.CreateDirectory(dirPath.Replace(source, target));

            //Copy all the files & Replaces any files with the same name
            foreach (string newPath in Directory.GetFiles(source, "*.*", SearchOption.AllDirectories))
            {
                var fileName = Path.GetFileName(newPath);
                if (exclude == null || !exclude.Contains(fileName))
                {
                    File.Copy(newPath, newPath.Replace(source, target), true);
                }
            }
        }
        
        public static void DeleteDir(string srcPath)
        {
            DirectoryInfo dir = new DirectoryInfo(srcPath);
            FileSystemInfo[] fileinfo = dir.GetFileSystemInfos(); //返回目录中所有文件和子目录
            foreach (FileSystemInfo i in fileinfo)
            {
                if (i is DirectoryInfo) //判断是否文件夹
                {
                    DirectoryInfo subdir = new DirectoryInfo(i.FullName);
                    subdir.Delete(true); //删除子目录和文件
                }
                else
                {
                    File.Delete(i.FullName); //删除指定文件
                }
            }                            
        }
    }
}