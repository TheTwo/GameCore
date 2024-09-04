using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEngine.Build.Pipeline;
using GenerateBundleCommands = UnityEditor.Build.Pipeline.Tasks.GenerateBundleCommands;
using UpdateBundleObjectLayout = UnityEditor.Build.Pipeline.Tasks.UpdateBundleObjectLayout;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public static class BuildTaskHelper
	{
		private static Type _buildCacheUtility;
		private static Func<IEnumerable<ObjectIdentifier>, Type[]> _getMainTypeForObjectsFunc;
		private static Func<ObjectIdentifier, Type[]> _getCachedTypesForObjectFunc;
		private static Func<List<GUID>, HashSet<GUID>, bool> _validAssetBundle;
		private static Func<List<GUID>, bool> _validSceneBundle;
		// ReSharper disable once InconsistentNaming
		private static Func<GUID, long, Type> _getTypeFromVisibleGUIDAndLocalFileIdentifier;
		// ReSharper disable InconsistentNaming
		private static Func<GUID, ObjectIdentifier[],
			BuildTarget, UnityEditor.Build.Player.TypeDB, HashSet<GUID>, ObjectIdentifier[]> _filterReferencedObjectIDs;
		private static GUID? UnityBuiltInExtraGuid;
		private static GUID? UnityDefaultResourceGuid;
		private static GUID? UnityEditorResourceGuid;
		// ReSharper restore InconsistentNaming

		private static void CheckFunc()
		{
			if (null == _buildCacheUtility)
			{
				var assembly = typeof(UnityEditor.Build.Pipeline.Utilities.BuildCache).Assembly;
				_buildCacheUtility = assembly.GetType("BuildCacheUtility");
			}
			_getMainTypeForObjectsFunc ??= (Func<IEnumerable<ObjectIdentifier>, Type[]>)Delegate.CreateDelegate(
				typeof(Func<IEnumerable<ObjectIdentifier>, Type[]>),
				_buildCacheUtility.GetMethod("GetMainTypeForObjects") ?? throw new InvalidOperationException());
			_getCachedTypesForObjectFunc ??= (Func<ObjectIdentifier, Type[]>)Delegate.CreateDelegate(
				typeof(Func<ObjectIdentifier, Type[]>), _buildCacheUtility.GetMethod("GetCachedTypesForObject",
					                                        BindingFlags.Static | BindingFlags.NonPublic)
				                                        ?? throw new InvalidOperationException());
			if (!UnityBuiltInExtraGuid.HasValue)
			{
				var fieldInfo = typeof(UnityEditor.Build.Utilities.CommonStrings).GetField(nameof(UnityBuiltInExtraGuid),
					BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
				if (null != fieldInfo)
				{
					UnityBuiltInExtraGuid = new GUID((string)fieldInfo.GetValue(null));
				}
			}
			if (!UnityDefaultResourceGuid.HasValue)
			{
				var fieldInfo = typeof(UnityEditor.Build.Utilities.CommonStrings).GetField(nameof(UnityDefaultResourceGuid),
					BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
				if (null != fieldInfo)
				{
					UnityDefaultResourceGuid = new GUID((string)fieldInfo.GetValue(null));
				}
			}
			if (!UnityEditorResourceGuid.HasValue)
			{
				var fieldInfo = typeof(UnityEditor.Build.Utilities.CommonStrings).GetField(nameof(UnityEditorResourceGuid),
					BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
				if (null != fieldInfo)
				{
					UnityEditorResourceGuid = new GUID((string)fieldInfo.GetValue(null));
				}
			}

			if (null == _validAssetBundle)
			{
				var m = typeof(UnityEditor.Build.Pipeline.Tasks.GenerateBundlePacking).GetMethod(
					nameof(ValidAssetBundle), BindingFlags.Static | BindingFlags.NonPublic);
				_validAssetBundle =
					(Func<List<GUID>, HashSet<GUID>, bool>)Delegate.CreateDelegate(
						typeof(Func<List<GUID>, HashSet<GUID>, bool>), m ?? throw new InvalidOperationException());
			}
			if (null == _validSceneBundle)
			{
				var assembly = typeof(UnityEditor.Build.Pipeline.Utilities.BuildCache).Assembly;
				var t = assembly.GetType("UnityEditor.Build.Pipeline.Utilities.ValidationMethods");
				var m = t.GetMethod(
					nameof(ValidSceneBundle), BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
				_validSceneBundle =
					(Func<List<GUID>, bool>)Delegate.CreateDelegate(
						typeof(Func<List<GUID>, bool>), m ?? throw new InvalidOperationException());
			}

			if (null == _getTypeFromVisibleGUIDAndLocalFileIdentifier)
			{
				var m = typeof(AssetDatabase).GetMethod(nameof(GetTypeFromVisibleGUIDAndLocalFileIdentifier),
					BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
				_getTypeFromVisibleGUIDAndLocalFileIdentifier =
					(Func<GUID, long, Type>)Delegate.CreateDelegate(
						typeof(Func<GUID, long, Type>), m ?? throw new InvalidOperationException());
			}

			if (null == _filterReferencedObjectIDs)
			{
				var assembly = typeof(UnityEditor.Build.Pipeline.Utilities.BuildCache).Assembly;
				var t = assembly.GetType("UnityEditor.Build.Pipeline.Utilities.ExtensionMethods");
				var m = t.GetMethod(
					nameof(FilterReferencedObjectIDs), BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
				_filterReferencedObjectIDs = (Func<GUID, ObjectIdentifier[],
						BuildTarget, UnityEditor.Build.Player.TypeDB, HashSet<GUID>, ObjectIdentifier[]>)
					Delegate.CreateDelegate(typeof(Func<GUID, ObjectIdentifier[],
							BuildTarget, UnityEditor.Build.Player.TypeDB, HashSet<GUID>, ObjectIdentifier[]>),
						m ?? throw new InvalidOperationException());
			}
		}
		
		public static Type[] GetMainTypeForObjects(IEnumerable<ObjectIdentifier> objectIdentifiers)
		{
			CheckFunc();
			return _getMainTypeForObjectsFunc.Invoke(objectIdentifiers);
		}

		public static Type[] GetCachedTypesForObject(in ObjectIdentifier objectIdentifier)
		{
			CheckFunc();
			return _getCachedTypesForObjectFunc.Invoke(objectIdentifier);
		}

		public static GUID GetUnityBuiltInExtraGuid()
		{
			CheckFunc();
			// ReSharper disable once PossibleInvalidOperationException
			return UnityBuiltInExtraGuid.Value;
		}

		public static GUID GetUnityDefaultResourceGuid()
		{
			CheckFunc();
			// ReSharper disable once PossibleInvalidOperationException
			return UnityDefaultResourceGuid.Value;
		}

		public static GUID GetUnityEditorResourceGuid()
		{
			CheckFunc();
			// ReSharper disable once PossibleInvalidOperationException
			return UnityEditorResourceGuid.Value;
		}

		public static bool ValidAssetBundle(List<GUID> assets, HashSet<GUID> customAssets)
		{
			CheckFunc();
			return _validAssetBundle.Invoke(assets, customAssets);
		}

		public static bool ValidSceneBundle(List<GUID> assets)
		{
			CheckFunc();
			return _validSceneBundle.Invoke(assets);
		}
		
		// ReSharper disable once InconsistentNaming
		public static Type GetTypeFromVisibleGUIDAndLocalFileIdentifier(GUID guid, long localFileIdentifier)
        {
            CheckFunc();
            return _getTypeFromVisibleGUIDAndLocalFileIdentifier.Invoke(guid, localFileIdentifier);
        }
		
		public static Type[] GetSortedUniqueTypesForObject(ObjectIdentifier objectId)
		{
			Type[] types = GetCachedTypesForObject(objectId);
			Array.Sort(types, (x, y) => string.Compare(x.AssemblyQualifiedName, y.AssemblyQualifiedName, StringComparison.Ordinal));
			return types;
		}

		public static ObjectIdentifier[] FilterReferencedObjectIDs(GUID asset, ObjectIdentifier[] references,
			BuildTarget target, UnityEditor.Build.Player.TypeDB typeDB, HashSet<GUID> dependencies)
		{
			CheckFunc();
			return _filterReferencedObjectIDs.Invoke(asset, references, target, typeDB, dependencies);
		}

		public static bool AttachBuildTask<T, TBefore>(IList<IBuildTask> buildTasks, Func<T> taskGetter, bool needUpdateLayout) where T:IBuildTask where TBefore:IBuildTask
		{
			if (null == buildTasks) return false;
			var success = false;
			for (int i = buildTasks.Count - 1; i >= 0; i--)
			{
				var task = buildTasks[i];
				if (task is not T) continue;
				buildTasks.RemoveAt(i);
				break;
			}

			for (var i = buildTasks.Count - 1; i >= 0; i--)
			{
				var task = buildTasks[i];
				if (task is not TBefore) continue;
				buildTasks.Insert(i, taskGetter());
				success = true;
				break;
			}

			if (!needUpdateLayout) return success;
			if (!success) return false;
			success = false;
			var startIndex = -1;
			for (var i = buildTasks.Count - 1; i >= 0; i--)
			{
				var task = buildTasks[i];
				if (task is not GenerateBundleCommands) continue;
				startIndex = i;
				success = true;
				break;
			}
			if (!success) return false;
			var patchIndex = startIndex;
			success = false;
			for (var i = startIndex - 1; i >= 0; i--)
			{
				var task = buildTasks[i];
				if (task is not UpdateBundleObjectLayout) continue;
				success = true;
				break;
			}
			if (!success)
			{
				buildTasks.Insert(patchIndex, new UpdateBundleObjectLayout());
			}
			return true;
		}

		public static void RemoveBuildTaskFromBack(IList<IBuildTask> buildTasks, Func<IBuildTask, int, bool> checkAndModify)
		{
			for (var i = buildTasks.Count - 1; i >= 0; i--)
			{
				var task = checkAndModify(buildTasks[i], i);
				if (!task) break;
			}
		}

		public static void ModifyBuildTaskToDryRun(IList<IBuildTask> buildTasks)
		{
			RemoveBuildTaskFromBack(buildTasks, (task,index) =>
			{
				if (task is UnityEditor.Build.Pipeline.Tasks.WriteSerializedFiles)
				{
					buildTasks.RemoveAt(index);
					return false;
				}
				buildTasks.RemoveAt(index);
				return true;
			});
			buildTasks.Insert(0, new InjectIMarkerTask<IMarkedAsDryRun>(new MarkedAsDryRun()));
		}

		private class MarkedAsDryRun : IMarkedAsDryRun
		{ }
	}

	public interface IUserDefinedBuildContextObject : IContextObject { }

	public interface IMarkedAsDryRun : IUserDefinedBuildContextObject { }

	public interface IDetailManifest : IUserDefinedBuildContextObject
	{
		IReadOnlyDictionary<string, IReadOnlyCollection<string>> Bundle2Dep { get; }
		IReadOnlyDictionary<string, IReadOnlyCollection<string>> Asset2DepBundle { get; }
            
		IReadOnlyDictionary<string, IReadOnlyCollection<string>> Asset2DepAsset { get; }

		Dictionary<string, BundleDetails> PatchForManifest(Dictionary<string, BundleDetails> bundleDetailsMap);
	}

	public interface IImplicitDependenciesAssets : IUserDefinedBuildContextObject
	{
		IReadOnlyDictionary<string, Dictionary<string, Tuple<string, HashSet<Type>>>> ReferencedReason { get; }

		void WriteToFile(string path);
	}

	public interface ISpriteTextureReferenceRecord : IUserDefinedBuildContextObject
	{
		public IReadOnlyDictionary<GUID, Dictionary<GUID, ObjectIdentifierInfo>> Detail { get; }
		
		void WriteToFile(string path);
	}

	public interface IInValidAssetReferenceRecord : IUserDefinedBuildContextObject
	{
		void WriteToFile(string path);
	}

	public interface IInValidAssetCheckRule : IUserDefinedBuildContextObject
	{
		bool IsAssetPathValid(in ObjectIdentifier objectIdentifier, out string assetPath);
		bool FailBuildIfNotPass { get; }
		ISet<GUID> IgnoreGuids { get; }
	}

	public enum BundleProcessRule
	{
		OnlyReferencedAssetGenerateBundleByFolder = 0,						// 目录打包，包括单次引用资源和多次引用资源
		OnlyReferencedAndRefAboveOneAssetGenerateBundleByFolder = 1,		// 目录打包，包含多次引用资源，不包含单次引用资源
		ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset = 2,	// 目录打包，该目录下任意资源被引用 则整个目录都打包
	}

	public class StaticBundleIncludedDetail
	{
		public readonly Dictionary<string, int> ReferencedAssets = new();
		public readonly HashSet<string> NotReferencedAssets = new();
		public readonly HashSet<string> ReferencedByAssets = new();
	}

	public interface IMarkStaticBundleProcessRule : IUserDefinedBuildContextObject
	{
		BundleProcessRule UseRule { get; } 
		Dictionary<string, StaticBundleIncludedDetail> RefDetail { get; }

		void WriteToFile(string jsonOutput, string csvOutput);
	}

	public class InjectIMarkerTask<T> : IBuildTask  where T : IUserDefinedBuildContextObject
    {
	    int IBuildTask.Version => 1;

#pragma warning disable 649
	    // ReSharper disable once NotAccessedField.Local
	    // ReSharper disable once ArrangeTypeMemberModifiers
	    // ReSharper disable once InconsistentNaming
	    [InjectContext(ContextUsage.Out)] T m_InjectContext;
#pragma warning restore 649

	    private readonly T _injectPayload;

	    public InjectIMarkerTask(T injectPayload)
	    {
		    _injectPayload = injectPayload;
	    }

	    ReturnCode IBuildTask.Run()
	    {
		    m_InjectContext = _injectPayload;
		    return ReturnCode.Success;
	    }
    }

    public class GetResultTask<T> : IBuildTask where T : IUserDefinedBuildContextObject
    {
	    int IBuildTask.Version => 1;
	    // ReSharper disable once ArrangeTypeMemberModifiers
	    // ReSharper disable once InconsistentNaming
	    [InjectContext(ContextUsage.In, true)] T m_ContextObject;
	    public T Result => _contextObject;
	    // ReSharper disable once UnusedAutoPropertyAccessor.Global
	    // ReSharper disable once MemberCanBePrivate.Global
	    public bool RunEnd { get; private set; }
	    
	    private T _contextObject;
	    private readonly bool _errorIfNull;

	    public static GetResultTask<T> AddToBuildTasks(IList<IBuildTask> buildTasks, T defaultValue = default, bool errorIfNull = true)
	    {
		    var ret = new GetResultTask<T>(defaultValue, errorIfNull);
		    BuildTaskHelper.AttachBuildTask<GetResultTask<T>, UnityEditor.Build.Pipeline.Tasks.WriteSerializedFiles>(buildTasks,
			    () => ret, false);
		    return ret;
	    }

	    private GetResultTask(T defaultValue, bool errorIfNull)
	    {
		    _errorIfNull = errorIfNull;
		    _contextObject = defaultValue;
	    }

	    ReturnCode IBuildTask.Run()
	    {
		    if (null != m_ContextObject)
		    {
			    _contextObject = m_ContextObject;
		    }

		    RunEnd = true;
		    if (_errorIfNull && null == m_ContextObject) return ReturnCode.MissingRequiredObjects;
		    return ReturnCode.Success;
	    }
    }
}
