using System;
using UnityEngine;

namespace DragonReborn.AssetTool
{
    public class AssetBundleConfig : Singleton<AssetBundleConfig>
    {
		public ulong GetHeadOffset(string hashName)
		{
			if (IOUtils.HasEncryptTag())
			{
				return (ulong) SafetyUtils.GetHeadOffset(hashName);
			}

			return 0;
		}

        public bool TryGetBundleInfo(string info, out string md5, out string crc)
        {
            md5 = string.Empty;
            crc = string.Empty;
            
            if (string.IsNullOrEmpty(info))
            {
                return false;
            }
            var infos = info.Split('@');
            if (infos.Length == 2)
            {
                md5 = infos[0];
                crc = infos[1];
                return true;
            }

            return false;
        }
    }
}
