using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace DragonReborn.AssetTool.Editor
{
	public partial class CustomAssetPostprocessor
	{
		private const string LABEL_ANI_CUSTOM = "M_Custom";
		/// <summary>
		/// This function is called before the final Prefab is created and before it is written to disk,
		/// thus you have full control over the generated game objects and components.
		/// </summary>
		/// <param name="go"></param>
		void OnPostprocessModel(GameObject model)
		{
			if (!ModelNeedProcess())
				return;
			
			// 处理Renderer
			SetupRendererSettings(model);
			// 处理Animator
			SetupAnimatorSetting(model);
			// 处理UV和Color
			ClearMeshUVAndColorChannel(model);
			// 处理动画
			ModelImporter modelImporter = assetImporter as ModelImporter;
			BasicAnimationSetting(modelImporter, model);
		}
		
		#region SetAnimation
		private bool HasAnimationClips()
		{
			return assetPath.Contains("@");
		}
		private bool HasAnimationClips(ModelImporter modelImporter)
		{
			return modelImporter.clipAnimations.Length > 0 || modelImporter.defaultClipAnimations.Length > 0;
		}
		
		private bool HasSkinnedMesh(GameObject model)
		{
			return model.GetComponentInChildren<SkinnedMeshRenderer>() != null;
		}
		
		private bool HasSkinnedMeshBones (GameObject model)
		{
			var renderers = model.GetComponentsInChildren<Renderer>();

			foreach (var renderer in renderers)
			{
				if (renderer is SkinnedMeshRenderer skinnedMeshRenderer)
				{
					if (skinnedMeshRenderer.bones != null && skinnedMeshRenderer.bones.Length > 0)
					{
						return true;
					}
				}
			}

			return false;
		}

		void BasicAnimationSetting(ModelImporter modelImporter, GameObject model) 
		{
			if (HasSkinnedMesh(model) || HasAnimationClips())
			{
				// 模型包含动画片段
				modelImporter.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
				modelImporter.skinWeights = ModelImporterSkinWeights.Standard;
				modelImporter.optimizeBones = true;
				
				modelImporter.importConstraints = false;
				var isClipAnimation = HasAnimationClips(modelImporter);
				modelImporter.importAnimation = isClipAnimation;
				modelImporter.resampleCurves = true;
				modelImporter.animationCompression = ModelImporterAnimationCompression.KeyframeReduction;

				if (isClipAnimation)
				{
					// 美术说需要放开, 根据标签放开
					string[] labels = VfxTools.GetdAssetLabels(assetPath);
					HashSet<string> Labels = labels != null ? new HashSet<string>(labels, StringComparer.OrdinalIgnoreCase) : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
					if (!Labels.Contains(LABEL_ANI_CUSTOM))
					{
						modelImporter.animationRotationError = 0.5f;
						modelImporter.animationPositionError = 0.5f;
						modelImporter.animationScaleError = 0.5f;
						modelImporter.removeConstantScaleCurves = true;
					}
					modelImporter.importAnimatedCustomProperties = false;
				}
			}
			else
			{
				modelImporter.avatarSetup = ModelImporterAvatarSetup.NoAvatar;
				modelImporter.skinWeights = ModelImporterSkinWeights.Standard;
				modelImporter.optimizeBones = true;
				
				modelImporter.animationType	= ModelImporterAnimationType.None;
				modelImporter.importConstraints = false;
				modelImporter.importAnimation = false;
			}
		}
		#endregion
		
		#region SetRenderer
		private void SetupRendererSettings(GameObject model)
		{
			Renderer[] renderers = model.GetComponentsInChildren<Renderer>(true);
			foreach (var renderer in renderers)
			{
				if (renderer == null)
				{
					continue;
				}

				//renderer.receiveShadows = false;
				//renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
				//renderer.lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
				//renderer.reflectionProbeUsage = UnityEngine.Rendering.ReflectionProbeUsage.Off;

				// FBX有可能会引用Default-Material，从而引用Standard Shader，所以需要清空材质，
				// 避免引用Standard Shader导致ShaderLab内存过大
				if (renderer.sharedMaterials != null && renderer.sharedMaterials.Length > 0)
				{
					renderer.sharedMaterials = new Material[renderer.sharedMaterials.Length];
				}
				
				var skinnedMesh = renderer as SkinnedMeshRenderer;
				if (skinnedMesh)
				{
					skinnedMesh.updateWhenOffscreen = false;
					skinnedMesh.skinnedMotionVectors = false;
					skinnedMesh.motionVectorGenerationMode = MotionVectorGenerationMode.ForceNoMotion;	
				}
			}
		}
		#endregion
		
		#region SetAnimator
		private void SetupAnimatorSetting(GameObject model)
		{
			Animator[] animators = model.GetComponentsInChildren<Animator>(true);
			for (int i = 0; i < animators.Length; ++i)
			{
				animators[i].avatar = null;
				animators[i].updateMode = AnimatorUpdateMode.Normal;
				animators[i].applyRootMotion = false;
				animators[i].cullingMode = AnimatorCullingMode.AlwaysAnimate;
			}
		}
		#endregion
		
		#region SetMeshUVAndColor
		
		private void ClearMeshUVAndColorChannel(GameObject model)
        {
            List<Vector2> rNewUV = null;
            // List<Color32> rNewColor = null;
            var rFilters= model.GetComponentsInChildren<MeshFilter>();
            for (int filter_index = 0; filter_index < rFilters.Length; filter_index++)
            {
                //	rFilters[filter_index].sharedMesh.SetColors(rNewColor);
                //	rFilters[filter_index].sharedMesh.SetUVs(1, rNewUV);
                //	rFilters[filter_index].sharedMesh.SetUVs(2, rNewUV);
                // rFilters[filter_index].sharedMesh.SetUVs(3, rNewUV);
                rFilters[filter_index].sharedMesh.SetUVs(4, rNewUV);
                rFilters[filter_index].sharedMesh.SetUVs(5, rNewUV);
                rFilters[filter_index].sharedMesh.SetUVs(6, rNewUV);
                rFilters[filter_index].sharedMesh.SetUVs(7, rNewUV);
            }
			
            var rFilters2= model.GetComponentsInChildren<SkinnedMeshRenderer>();
            for (int filter_index = 0; filter_index < rFilters2.Length; filter_index++)
            {
                //	rFilters2[filter_index].sharedMesh.SetColors(rNewColor);
                //	rFilters[filter_index].sharedMesh.SetUVs(1, rNewUV);
                rFilters2[filter_index].sharedMesh.SetUVs(2, rNewUV);
                rFilters2[filter_index].sharedMesh.SetUVs(3, rNewUV);
                rFilters2[filter_index].sharedMesh.SetUVs(4, rNewUV);
                rFilters2[filter_index].sharedMesh.SetUVs(5, rNewUV);
                rFilters2[filter_index].sharedMesh.SetUVs(6, rNewUV);
                rFilters2[filter_index].sharedMesh.SetUVs(7, rNewUV);
            }
        }
		#endregion
    }
}
