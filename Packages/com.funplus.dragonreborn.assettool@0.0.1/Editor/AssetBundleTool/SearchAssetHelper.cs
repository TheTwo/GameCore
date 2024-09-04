using System.Collections.Generic;
using UnityEditor;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public static class SearchAssetHelper
	{
		public static string[] SearchAssetInFoldersTopOnly(string filter, string[] folders)
		{
			var ret = new List<string>();
			foreach (var folder in folders)
			{
				var trimEnd = folder.Replace('\\', '/').TrimEnd('/');
				var lastSplitPos = trimEnd.Length;
				var allResult = AssetDatabase.FindAssets(filter, new[] { folder });
				foreach (var resultGuid in allResult)
				{
					var p = AssetDatabase.GUIDToAssetPath(resultGuid).Replace('\\', '/');
					var l = p.LastIndexOf('/');
					if (l != lastSplitPos) continue;
					ret.Add(resultGuid);
				}
			}
			return ret.ToArray();
		}
	}
}
