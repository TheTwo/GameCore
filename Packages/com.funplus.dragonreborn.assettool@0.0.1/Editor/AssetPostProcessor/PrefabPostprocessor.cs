using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public partial class CustomAssetPostprocessor
	{
		void OnPostprocessPrefab(GameObject go)
		{
			ProcessParticleSystems(go);
		}

		private void ProcessParticleSystems(GameObject go)
		{
			var particleSystems = go.GetComponentsInChildren<ParticleSystem>();
			if (particleSystems == null || particleSystems.Length == 0)
			{
				return;
			}

			foreach (var particleSystem in particleSystems)
			{
				// 获取粒子系统的渲染组件
				var particleRenderSystem = particleSystem.GetComponent<ParticleSystemRenderer>();
				if (particleRenderSystem == null)
				{
					continue;
				}

				// 检查渲染模式是否不是Mesh，如果是，则将mesh设置为null
				if (particleRenderSystem.renderMode != ParticleSystemRenderMode.Mesh && particleRenderSystem.mesh != null)
				{
					particleRenderSystem.mesh = null;
					// 标记预制体已修改，需要保存
					EditorUtility.SetDirty(go);
				}

				var material = particleRenderSystem.sharedMaterial;
				if (material != null && material.name.Contains("ParticlesUnlit"))
				{
					particleRenderSystem.sharedMaterial = null;
					// 标记预制体已修改，需要保存
					EditorUtility.SetDirty(go);
				}
			}
		}
	}
}
