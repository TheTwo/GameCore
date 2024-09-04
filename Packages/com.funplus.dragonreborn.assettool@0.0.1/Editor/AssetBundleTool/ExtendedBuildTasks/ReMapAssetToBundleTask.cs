using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Pipeline.Tasks;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 基于规则 将指定的资源分配到特定的bundle, 减少依赖复制
	/// 目前用于：
	/// 将所有的shader(包括内置shader) 整理到指定bundle，
	/// 将引用到的Unity内置资源收集到独立bundle 
	/// </summary>
	public class ReMapAssetToBundleTask : IBuildTask
	{
		int IBuildTask.Version => 1;
		
		// ReSharper disable InconsistentNaming
		// ReSharper disable ArrangeTypeMemberModifiers
		[InjectContext(ContextUsage.In)] IDependencyData m_DependencyData;
		[InjectContext(ContextUsage.InOut, true)] IBundleExplictObjectLayout m_Layout;
		// ReSharper restore ArrangeTypeMemberModifiers
		// ReSharper restore InconsistentNaming

		private readonly IReadOnlyList<MatchRuleFunc> _reMapRule;
		private readonly ISet<GUID> _ignoreGuids;

		public delegate bool MatchRuleFunc(Type usedType, in ObjectIdentifier objectIdentifier, out string bundleName);

		public static bool AddToBuildTasks(IList<IBuildTask> buildTasks, IReadOnlyList<MatchRuleFunc> rule, ISet<GUID> ignoreGuids)
		{
			if (null == buildTasks) return false;
			if (null == rule || rule.Count <= 0) return false;
		    
			return BuildTaskHelper.AttachBuildTask<ReMapAssetToBundleTask, PostDependencyCallback>(buildTasks,
				() => new ReMapAssetToBundleTask(rule, ignoreGuids), true);
		}
	    
		private ReMapAssetToBundleTask(IReadOnlyList<MatchRuleFunc> rule, ISet<GUID> ignoreGuids)
		{
			_reMapRule = rule;
			_ignoreGuids = ignoreGuids;
		}
	    
		ReturnCode IBuildTask.Run()
		{
			var buildInObjects = new HashSet<ObjectIdentifier>();
			foreach (var dependencyInfo in m_DependencyData.AssetInfo.Values)
				buildInObjects.UnionWith(dependencyInfo.referencedObjects.Where(x=>!_ignoreGuids.Contains(x.guid)));
			foreach (var dependencyInfo in m_DependencyData.SceneInfo.Values)
				buildInObjects.UnionWith(dependencyInfo.referencedObjects.Where(x=>!_ignoreGuids.Contains(x.guid)));
			var usedSet = buildInObjects.ToArray();
			var usedTypes = BuildTaskHelper.GetMainTypeForObjects(usedSet);
			m_Layout ??= new BundleExplictObjectLayout();
			for (var i = 0; i < usedTypes.Length; i++)
			{
				var usedType = usedTypes[i];
				foreach (var rule in _reMapRule)
				{
					if (rule.Invoke(usedType, in usedSet[i], out var bundleName))
					{
						m_Layout.ExplicitObjectLocation.Add(usedSet[i], bundleName);
						break;
					}
				}
			}
			if (m_Layout.ExplicitObjectLocation.Count <= 0)
				m_Layout = null;
			return ReturnCode.Success;
		}
	}
}
