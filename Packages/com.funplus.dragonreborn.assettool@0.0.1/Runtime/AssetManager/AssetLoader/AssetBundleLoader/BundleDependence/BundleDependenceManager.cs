using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
    public class BundleDependenceManager : Singleton<BundleDependenceManager>
    {
	    public const string BUNDLE_DEPENDENCE_CONFIG_FILE = "bundle_dependence.json";
	    
        private bool _init;

        private Dictionary<string, BundleDependenceData> _allDependence = new Dictionary<string, BundleDependenceData>();

        public bool LoadBundleDependence()
        {
	        _init = false;
	        //Assets/StreamingAssets/GameAssets/AssetBundle/Android/bundle_assets_0.0.0.0.json
	        var jsonFile = BUNDLE_DEPENDENCE_CONFIG_FILE;
	        var jsonText = IOUtils.ReadGameAssetAsText(PathHelper.FormatStreamingAssetsBundleFolder(jsonFile), IOUtils.HasEncryptTag());
	        if (!string.IsNullOrEmpty(jsonText))
			{
				var allData = DataUtils.FromJson<BundleDependenceConfigJson>(jsonText);
				if (allData == null || allData.DependenceMap == null || allData.DependenceMap.Length == 0)
				{
					throw new Exception("bundle dependence data parse error");
				}

				foreach (var pair in allData.DependenceMap)
				{
					var bundleDependenceData = new BundleDependenceData();
					bundleDependenceData.BundleName = pair.BundleName;
					bundleDependenceData.Dependence = pair.Dependencies;
					//bundleDependenceData.Hash = pair.Hash;
					_allDependence[pair.BundleName] = bundleDependenceData;
				}

				_init = true;
			}

			return true;
		}

        public BundleDependenceData GetBundleDependence(string bundleName)
	    {
		    _allDependence.TryGetValue(bundleName, out var data);
		    
		    // bundle可以没有依赖
	        if (data == null)
	        {
		        data = new BundleDependenceData();
		        data.BundleName = bundleName;
		        data.Dependence = null;
	        }
	        return data;
	    }
		
		public bool DataAllInit()
		{
			return _init;
		}
    }

    [Serializable]
    public class BundleDependence
    {
	    public string BundleName;
	    public string[] Dependencies;
	    //public string Hash;
    }

    [UnityEngine.Scripting.Preserve]
    [Serializable]
	public class BundleDependenceConfigJson
	{
		public BundleDependence[] DependenceMap;

		public static BundleDependenceConfigJson CreateFromDic(IDictionary<string, (string[],Hash128)> src)
		{
			var ret = new BundleDependenceConfigJson();
			var l = new List<BundleDependence>(src.Count);
			var keys = src.Keys;
			foreach (var bundleName in keys)
			{
				var dependencies = src[bundleName];
				l.Add(new BundleDependence
				{
					BundleName = bundleName,
					Dependencies = dependencies.Item1,
					//Hash = dependencies.Item2.ToString(),
				});
			}
			ret.DependenceMap = l.ToArray();
			return ret;
		}
	}
}
