using UnityEngine;
using UnityEditor;

[InitializeOnLoad] // 确保在Unity编辑器加载时执行此脚本
public class DefaultParticleSystemSettings
{
	static DefaultParticleSystemSettings()
	{
		// 订阅到Unity的事件，当Hierarchy中创建新的GameObject时会触发
		EditorApplication.hierarchyChanged += OnHierarchyChanged;
	}

	private static void OnHierarchyChanged()
	{
		// 找到所有新创建的Particle Systems
		foreach (ParticleSystem ps in Object.FindObjectsOfType<ParticleSystem>())
		{
			// 检查如果是新创建的ParticleSystem，并且没有设置过maxParticles
			if (ps.main.maxParticles == 1000)
			{
				// 获取ParticleSystem的main模块
				var mainModule = ps.main;
				// 设置新的最大粒子数量
				mainModule.maxParticles = 30; // 你想要的默认值
			}
		}
	}
}
