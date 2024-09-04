using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using Object = UnityEngine.Object;

namespace DragonReborn.AssetTool
{
    public class ResourcesLoader : IAssetLoader
    {
        private readonly Dictionary<string,string> _allPathMap = new Dictionary<string, string>();
        
        public void Initialize()
        {
#if UNITY_EDITOR
			CollectResourceFiles(_allPathMap);
			return;
#else

            _allPathMap.Clear();
            var configtxt = Resources.Load<TextAsset>("ResourcesPath");

            if (configtxt == null)
            {
                Debug.LogError("load ResourcesPath fail");
            }
            
            NLogger.LogChannel("ResourcesLoader", "ResourcesLoader Init with: " + configtxt.text);
            using var reader = new StringReader(configtxt.text);
            var line = reader.ReadLine();
            while (null != line)
            {
                if (!string.IsNullOrWhiteSpace(line))
                {
                    var sp = line.Split(',');
                    if (sp.Length > 1)
                    {
                        _allPathMap[sp[0]] = sp[1];
                    }
                }
                line = reader.ReadLine();
            }
            Resources.UnloadAsset(configtxt);
#endif
        }

        public void Reset()
        {
            
        }

        public Object LoadAsset(BundleAssetData data, bool isSprite)
        {
            var assetPath = GetResourcePath(data.AssetName);
            if (isSprite)
            {
                return Resources.Load<Sprite>(assetPath);
            }
            
            return Resources.Load(assetPath);
        }

        public bool LoadAssetAsync(BundleAssetData data, System.Action<Object> callback, bool isSprite)
        {
            var assetPath = GetResourcePath(data.AssetName);

            if (String.IsNullOrEmpty(assetPath))
            {
                callback(null);
                return false;
            }
            
            ResourceRequest request;
            if (isSprite)
            {
                request = Resources.LoadAsync<Sprite>(assetPath);
            }
            else
            {
                request = Resources.LoadAsync(assetPath);    
            }
            
            if (request != null)
            {
                var asyncReq = AsyncRequest<ResourceRequest>.Create(request, OnAssetLoaded, callback);
                AsyncRequestManager.Instance.AddTask(asyncReq);
                return true;
            }
            
            return false;
        }

        private void OnAssetLoaded(ResourceRequest req, object userData)
        {
            if (userData is System.Action<Object> callback)
            {
                callback(req.asset);
            }
        }

        public bool IsAssetReady(string assetName)
        {
            return AssetExist(assetName);
        }

        public bool AssetExist(string assetName)
        {
            return _allPathMap.ContainsKey(assetName);
        }
        
        private string GetResourcePath(string assetName)
        {
            _allPathMap.TryGetValue(assetName, out var assetPath);
            return string.IsNullOrEmpty(assetPath) ? string.Empty : assetPath;
        }

#if UNITY_EDITOR


		public static void CollectResourceFiles(Dictionary<string, string> pathMap)
        {
            var resourceFiles = new List<string>();
            
            // add __Art/Resources
            try
            {
                var art3dResourcePath = Application.dataPath + "/__Art/Resources/";
                if (Directory.Exists(art3dResourcePath))
                {
	                var art3dFiles = Directory.GetFiles(art3dResourcePath, "*", SearchOption.AllDirectories);
	                resourceFiles.AddRange(art3dFiles);
                }
            }
            catch (Exception e)
            {
                Debug.Log(e);
            }

			// add _UI/Resources
			try
			{
				var uidataResourcePath = Application.dataPath + "/__UI/Resources/";
				if (Directory.Exists(uidataResourcePath))
				{
					var uiFiles = Directory.GetFiles(uidataResourcePath, "*", SearchOption.AllDirectories);
					resourceFiles.AddRange(uiFiles);
				}
			}
			catch (Exception e)
			{
				Debug.Log(e);
			}

			const string splitString = "Resources/";
            for (int i = 0; i < resourceFiles.Count; ++i)
            {
                if (resourceFiles[i].EndsWith(".meta"))
                {
                    continue;
                }
                
                // ignore ResourcePath.txt
                var fileName = Path.GetFileNameWithoutExtension(resourceFiles[i]);
                if (fileName.Equals("resourcespath", StringComparison.CurrentCultureIgnoreCase))
                {
                    continue;
                }
                
                if (!string.IsNullOrEmpty(fileName) && !pathMap.ContainsKey(fileName))
                {
                    var directory = Path.GetDirectoryName(resourceFiles[i]);
                    directory = directory.Replace('\\', '/');
					var index = directory.IndexOf(splitString);
					var databasepath = fileName;
					if (index >= 0)
					{
						databasepath = directory.Substring(index + splitString.Length);
						databasepath += "/";
						databasepath += fileName;
					}
                    
                    pathMap.Add(fileName, databasepath);
                }
            }

			// save to file
			var sb = new StringBuilder();
			foreach (var (filename, relativePath) in pathMap)
			{
				sb.AppendLine($"{filename},{relativePath}");
			}
			// const string assetPath = "Assets/__Art/Resources/ResourcesPath.txt";
			var file = Path.Combine(Application.dataPath, "__Art/Resources/ResourcesPath.txt");
			UnityEditor.AssetDatabase.StartAssetEditing();
			try
			{
				// UnityEditor.AssetDatabase.DeleteAsset(assetPath);
				var folder = Path.GetDirectoryName(file);
				if (!Directory.Exists(folder))
				{
					Directory.CreateDirectory(folder);
				}
				File.WriteAllText(file, sb.ToString());
			}
			finally
			{
				UnityEditor.AssetDatabase.StopAssetEditing();
			}
        }
#endif
	}
}
