using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering.Universal;

// ReSharper disable once CheckNamespace
public static class CameraRenderFeaturesUtilsForLua
	{
		private delegate List<ScriptableRendererFeature> RendererFeaturesGetterType(ScriptableRenderer renderer);
		private static readonly RendererFeaturesGetterType RendererFeaturesGetter;
		
		static CameraRenderFeaturesUtilsForLua()
		{
			var rendererFeaturesGetter = typeof(ScriptableRenderer).GetProperty("rendererFeatures",
				BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
			if (null != rendererFeaturesGetter)
			{
				RendererFeaturesGetter = (RendererFeaturesGetterType)Delegate.CreateDelegate(typeof(RendererFeaturesGetterType),
					rendererFeaturesGetter.GetMethod);
			}
			else
			{
				RendererFeaturesGetter = _ => null;
			}
		}
		
		public static ScriptableRendererFeature GetCameraRendererFeature(this Camera camera, Type renderType)
		{
			if (!camera) return default;
			var data = camera.GetUniversalAdditionalCameraData();
			if (!data) return default;
			var render = data.scriptableRenderer;
			if (null == render) return default;
			var features = RendererFeaturesGetter.Invoke(render);
			if (null == features) return default;
			foreach (var feature in features)
			{
				if (feature.GetType() != renderType) continue;
				return feature;
			}
			return default;
		}

		public static ScriptableRendererFeature GetCameraRendererFeature(this Camera camera, Type renderType,
			string name)
		{
			if (!camera) return default;
			var data = camera.GetUniversalAdditionalCameraData();
			if (!data) return default;
			var render = data.scriptableRenderer;
			if (null == render) return default;
			var features = RendererFeaturesGetter.Invoke(render);
			if (null == features) return default;
			foreach (var feature in features)
			{
				if (feature.GetType() != renderType || string.CompareOrdinal(feature.name, name) != 0) continue;
				return feature;
			}
			return default;
		}
	}
