using System.Collections.Generic;
using UnityEditor;

namespace DragonReborn.AssetTool.Editor
{
    public class AssetPathService : AssetModificationProcessor
    {
        public static void OnWillCreateAsset (string path)
        {
            //	Debug.Log ("OnWillCreateAsset " + path);
        }
        
        //asset保存\场景保存
        public static string[] OnWillSaveAssets (string[] paths)
        {
            var result = new List<string>();
            foreach( var path in paths )
            {
                result.Add ( path );
            }
            return result.ToArray();
        }
 
        //资源移动
        public static AssetMoveResult OnWillMoveAsset (string oldPath, string newPath)
        {
            AssetPathProvider.IsDirty = true;
            return AssetMoveResult.DidNotMove;
        }

        //资源删除
        public static AssetDeleteResult OnWillDeleteAsset (string assetPath, RemoveAssetOptions option)
        {
            AssetPathProvider.IsDirty = true;
            return AssetDeleteResult.DidNotDelete;
        } 
	
        public static string GetSavePath(string fileName)
        {
            if (AssetPathProvider.IsDirty)
            {
                AssetPathProvider.PrepareAssetPath();
            }
            return AssetPathProvider.InternalGetSavedPath(fileName);
        }
    }
}
