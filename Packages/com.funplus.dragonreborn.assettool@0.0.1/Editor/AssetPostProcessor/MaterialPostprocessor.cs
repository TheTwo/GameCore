using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public partial class CustomAssetPostprocessor
	{
		private static Dictionary<string, string> shaderWhiteList = null;

		[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterAssembliesLoaded)]
		static void ResetMaterialsWhiteList()
		{
			shaderWhiteList = MaterialTools.ShaderWhiteList();
		}


		static void CheckMaterial(Material material)
		{
			if (shaderWhiteList == null)
			{
				shaderWhiteList = MaterialTools.ShaderWhiteList();
			}

			if (!shaderWhiteList.ContainsKey(material.shader.name))
			{
				NLogger.Error($"材质{material.name}使用的shader:{material.shader.name}在白名单之外，请修正！");
			}
		}
	}
}
