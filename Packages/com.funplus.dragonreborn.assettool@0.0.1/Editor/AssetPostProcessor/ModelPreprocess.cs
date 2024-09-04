
using System;
using UnityEditor;

namespace DragonReborn.AssetTool.Editor
{
	public partial class CustomAssetPostprocessor
	{
		private static readonly string[] LimitModelRootPath = 
		{
			"Assets/__UI",
			"Assets/__Art",
			"Assets/__EditorUI"
		};
		
		private bool ModelNeedProcess()
		{
			// if (assetPath.Contains("__DontFixMe")) return false;
			return CheckIsSomePath(assetPath, LimitModelRootPath);
		}
		
		/// <summary>
		/// This lets you control the import settings through code.
		/// </summary>
		void OnPreprocessModel()
		{
			if (!ModelNeedProcess())
				return;
			
			var modelImporter = assetImporter as ModelImporter;
			// 处理Model的设置
			BasicModelSetting(modelImporter);
			// 先默认开启, 后面关闭
			modelImporter.animationType	= ModelImporterAnimationType.Generic;
			modelImporter.importAnimation = true;
		}

		#region Basic
		private bool NeedRW(string assetPath)
		{
			if (assetPath.Contains("/rw/", StringComparison.OrdinalIgnoreCase))
				return true;
			return false;
		}

		private void BasicModelSetting(ModelImporter mImporter)
		{
			mImporter.importBlendShapes = false;        
			mImporter.importVisibility = false;
			mImporter.importCameras = false;
			mImporter.importLights = false;
			mImporter.preserveHierarchy = false;
			mImporter.meshCompression = ModelImporterMeshCompression.Medium;	
			mImporter.isReadable = NeedRW(assetPath);            
			mImporter.optimizeMeshPolygons = true;
			mImporter.optimizeMeshVertices = true;
			mImporter.addCollider = false;
			mImporter.keepQuads = false;
			mImporter.weldVertices = true;
			// mImporter.indexFormat = ModelImporterIndexFormat.UInt16;
			// mImporter.importNormals = ModelImporterNormals.None;        
			// mImporter.importTangents = ModelImporterTangents.None;        
			// mImporter.importBlendShapeNormals = ModelImporterNormals.None;       
			// mImporter.normalSmoothingSource = ModelImporterNormalSmoothingSource.PreferSmoothingGroups;
			mImporter.swapUVChannels = false;
			mImporter.materialImportMode = ModelImporterMaterialImportMode.None;
			// mImporter.animationCompression = ModelImporterAnimationCompression.Optimal;
            
			mImporter.strictVertexDataChecks = false;  // 在导入模型时会对顶点数据执行更严格的检查, 影响导入性能
			mImporter.bakeAxisConversion = false; // 在导入模型时会将模型的坐标系转换为Unity的坐标系
			mImporter.importBlendShapeDeformPercent = false; // 是否导入BlendShape的变形百分比
			mImporter.sortHierarchyByName = true; // 是否按照名称排序层级	
		}

		#endregion
		
		
	}
}
