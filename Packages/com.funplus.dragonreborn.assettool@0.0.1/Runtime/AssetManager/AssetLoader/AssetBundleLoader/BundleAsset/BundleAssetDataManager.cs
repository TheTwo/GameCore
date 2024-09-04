using System;
using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn.AssetTool
{
    /// <summary>
    /// 管理BundleAssetData
    /// </summary>
    public class BundleAssetDataManager : Singleton<BundleAssetDataManager>
    {
	    public const string BUNDLE_ASSETS_CONFIG_FILE = "bundle_assets.json";
	    
        private Dictionary<string, BundleAssetData> _allAssetData = new Dictionary<string, BundleAssetData>();
        private bool _init;
        
        /// <summary>
        /// 从导出的bundle_assets.json中读取asset和bundle关系
        /// </summary>
        /// <param name="resVersion"></param>
        public void LoadAssetBundleConfig()
		{
			_init = false;

			var jsonFile = BUNDLE_ASSETS_CONFIG_FILE;
			var jsonText = IOUtils.ReadGameAssetAsText(PathHelper.FormatStreamingAssetsBundleFolder(jsonFile), IOUtils.HasEncryptTag());
			if (!string.IsNullOrEmpty(jsonText))
			{
				var allData = DataUtils.FromJson<BundleAssetAndSceneConfigJson>(jsonText);
				if (allData?.AssetBundleMap == null)
				{
					throw new Exception($"LoadAssetBundleConfig {jsonFile} error");
				}

				foreach (var pair in allData.AssetBundleMap)
				{
					foreach (var assetIndex in pair.Assets)
					{
						var bundleAssetData = new BundleAssetData(assetIndex, pair.BundleName);
						_allAssetData[bundleAssetData.AssetName] = bundleAssetData;
					}
				}

				foreach (var pair in allData.SceneBundleMap)
				{
					foreach (var assetIndex in pair.Assets)
					{
						var bundleAssetData = new BundleAssetData(assetIndex, pair.BundleName, true);
						_allAssetData[bundleAssetData.AssetName] = bundleAssetData;	
					}
				}
				_init = true;
			}
		}

		public bool ContainsAsset(string assetIndex)
	    {
	        return _allAssetData.ContainsKey(assetIndex);
	    }

	    public BundleAssetData GetAssetData(string assetIndex)
	    {
		    _allAssetData.TryGetValue(assetIndex, out var data);
	        return data;
	    }

	    public bool DataAllInit()
	    {
		    return _init;
	    }
    }

    [UnityEngine.Scripting.Preserve]
    [Serializable]
    public class BundleAssetAndSceneConfigJson
    {
	    public BundleAssetConfigJson[] AssetBundleMap;
	    public BundleAssetConfigJson[] SceneBundleMap;

	    public static BundleAssetAndSceneConfigJson Create(IReadOnlyDictionary<string, string> src, IReadOnlyDictionary<string, string> sceneBundle, IReadOnlyDictionary<string, Hash128> bundle2Hash)
	    {
		    var ret = new BundleAssetAndSceneConfigJson();
		    var dic = new Dictionary<string, List<string>>();
		    foreach (var kv in src)
		    {
			    if (!dic.TryGetValue(kv.Value, out var l))
			    {
				    l = new List<string>();
				    dic.Add(kv.Value, l);
			    }
			    l.Add(kv.Key);
		    }
		    var keys = new List<string>(dic.Keys);
		    keys.Sort(StringComparer.Ordinal);
		    ret.AssetBundleMap = new BundleAssetConfigJson[keys.Count];
		    for (int i = 0; i < keys.Count; i++)
		    {
			    var bundleName = keys[i];
			    var bundleAssets = dic[bundleName];
			    bundleAssets.Sort(StringComparer.Ordinal);
			    ret.AssetBundleMap[i] = BundleAssetConfigJson.Create(bundleName, bundleAssets.ToArray(), bundle2Hash[bundleName].ToString());
		    }
		    dic.Clear();
		    keys.Clear();
		    foreach (var kv in sceneBundle)
		    {
			    if (!dic.TryGetValue(kv.Value, out var l))
			    {
				    l = new List<string>();
				    dic.Add(kv.Value, l);
			    }
			    l.Add(kv.Key);
		    }
		    keys.AddRange(dic.Keys);
		    keys.Sort(StringComparer.Ordinal);
		    ret.SceneBundleMap = new BundleAssetConfigJson[keys.Count];
		    for (int i = 0; i < keys.Count; i++)
		    {
			    var bundleName = keys[i];
			    var scenes = dic[bundleName];
			    scenes.Sort(StringComparer.Ordinal);
			    ret.SceneBundleMap[i] = BundleAssetConfigJson.Create(bundleName, scenes.ToArray(), bundle2Hash[bundleName].ToString());
		    }
		    return ret;
	    }
    }
	
	[Serializable]
	public class BundleAssetConfigJson
	{
		public string BundleName;
		public string[] Assets;
		// public string Hash;

		public static BundleAssetConfigJson Create(string bundleName, string[] assets, string hash)
		{
			return new BundleAssetConfigJson()
			{
				BundleName = bundleName,
				Assets = assets,
				// Hash = hash,
			};
		}
	}
}
