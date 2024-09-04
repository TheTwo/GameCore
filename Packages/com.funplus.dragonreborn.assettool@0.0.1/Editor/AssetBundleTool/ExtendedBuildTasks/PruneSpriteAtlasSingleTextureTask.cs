using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Pipeline.Tasks;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 在构建过程中 将图集的sprite 自身的texture引入剥离，使生成的bundle 仅包含sprite 及其atlas图集texture， 减少冗余资源
	/// </summary>
	public class PruneSpriteAtlasSingleTextureTask : IBuildTask
	{
		int IBuildTask.Version => 1;

		private readonly IReadOnlyDictionary<GUID, string> _spriteAssignedWithBundle;
	    
		// ReSharper disable ArrangeTypeMemberModifiers
		// ReSharper disable InconsistentNaming
		// ReSharper disable RedundantArgumentDefaultValue
		[InjectContext(ContextUsage.InOut)] IDependencyData m_DependencyData;
		[InjectContext(ContextUsage.InOut)] IBuildExtendedAssetData m_ExtendedAssetData;
		// ReSharper restore RedundantArgumentDefaultValue
		// ReSharper restore InconsistentNaming
		// ReSharper restore ArrangeTypeMemberModifiers

		private PruneSpriteAtlasSingleTextureTask(IReadOnlyDictionary<GUID, string> spriteAssignedWithBundle)
		{
			_spriteAssignedWithBundle = spriteAssignedWithBundle;
		}

		ReturnCode IBuildTask.Run()
		{
			if (_spriteAssignedWithBundle.Count <= 0) return ReturnCode.SuccessNotRun;
			var needRemoveTextureInBundle = new HashSet<GUID>(_spriteAssignedWithBundle.Keys);
			var checkTextureTypeUsage = typeof(UnityEngine.Texture2D);
			foreach (var guid in needRemoveTextureInBundle)
			{
				if (!m_DependencyData.AssetInfo.TryGetValue(guid, out var assetLoadInfo)) continue;
				if (assetLoadInfo.includedObjects.Count <= 0) continue;
				var firstObj = assetLoadInfo.includedObjects[0];
				if (firstObj.guid != guid) continue;
				if (BuildTaskHelper.GetCachedTypesForObject(in firstObj)[0] != checkTextureTypeUsage) continue;
				assetLoadInfo.includedObjects.RemoveAt(0);
				assetLoadInfo.referencedObjects.RemoveAll(identifier => identifier.guid != guid && needRemoveTextureInBundle.Contains(identifier.guid));
				if (m_ExtendedAssetData?.ExtendedData == null 
				    || !m_ExtendedAssetData.ExtendedData.TryGetValue(guid, out var extendedAssetData)) continue;
				extendedAssetData.Representations.Remove(firstObj);
				if (extendedAssetData.Representations.Count <= 1)
				{
					m_ExtendedAssetData.ExtendedData.Remove(guid);
				}
			}
			return ReturnCode.Success;
		}
	    
		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks,
			IReadOnlyDictionary<GUID, string> spriteToBundleName)
		{
			return BuildTaskHelper.AttachBuildTask<PruneSpriteAtlasSingleTextureTask, PostDependencyCallback>(buildTasks,
				() => new PruneSpriteAtlasSingleTextureTask(new Dictionary<GUID, string>(spriteToBundleName)), false);
		}
	}
}
