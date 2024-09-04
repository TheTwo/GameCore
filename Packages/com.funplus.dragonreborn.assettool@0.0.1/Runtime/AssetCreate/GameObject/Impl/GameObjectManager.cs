using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
using AOT;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Jobs;
using UnityEngine;
using Object = UnityEngine.Object;

namespace DragonReborn.AssetTool
{
	[BurstCompile]
	public unsafe struct CheckObjectExistJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<int> InstanceIds;
		    
		public NativeParallelHashSet<int>.ParallelWriter ToBeRemoved;
		    
		[NativeDisableUnsafePtrRestriction]
		public IntPtr CheckObjectIDExistPtr;
		    
		public void Execute(int index)
		{
			var instanceId = InstanceIds[index];
			    
			var callback = (delegate* unmanaged[Cdecl]<int, bool>)CheckObjectIDExistPtr;
			if (callback(instanceId))
			{
				return;
			}
			    
			ToBeRemoved.Add(instanceId);
		}
	}
	
    public class GameObjectManager : Singleton<GameObjectManager>, IManager, ISecondTicker
    {
	    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
	    private delegate bool ObjectExistDelegate(int instanceId);

	    private readonly Dictionary<int, AssetHandle> _allObjectInfos = new();
        private NativeParallelHashSet<int> _allInstanceIds;
        private static readonly Func<int, bool> CheckObjectIDExistCallback;
        private static readonly IntPtr CheckObjectIDExistPtr;

        static GameObjectManager()
        {
	        var type = typeof(Object);
	        var methodInfo = type.GetMethod("DoesObjectWithInstanceIDExist", BindingFlags.Static | BindingFlags.NonPublic);
	        CheckObjectIDExistCallback = methodInfo?.CreateDelegate(typeof(Func<int, bool>)) as Func<int, bool>;
	        CheckObjectIDExistPtr = Marshal.GetFunctionPointerForDelegate(new ObjectExistDelegate(CheckObjectIDExist));
        }

        [MonoPInvokeCallback(typeof(ObjectExistDelegate))]
        private static bool CheckObjectIDExist(int instanceId)
        {
	        return CheckObjectIDExistCallback(instanceId);
        }
        
        public void OnGameInitialize(object configParam)
        {
	        _allInstanceIds = new NativeParallelHashSet<int>(1024, Allocator.Persistent);
        }

        public void Reset()
        {
            Clear();
        }

        public void Clear()
        {
            _allObjectInfos.Clear();

            if (_allInstanceIds.IsCreated)
            {
	            _allInstanceIds.Dispose();
	            _allInstanceIds = default;
            }
        }

        public void Tick(float delta)
        {
            using var instanceIds = _allInstanceIds.ToNativeArray(Allocator.TempJob);
            using var toBeRemoved = new NativeParallelHashSet<int>(1024, Allocator.TempJob);
            var checkExistJob = new CheckObjectExistJob
            {
	            InstanceIds = instanceIds,
	            ToBeRemoved = toBeRemoved.AsParallelWriter(),
	            CheckObjectIDExistPtr = CheckObjectIDExistPtr
            };

            var checkExistJobHandle = checkExistJob.Schedule(instanceIds.Length, 128);
            checkExistJobHandle.Complete();
            
            foreach (var instanceId in toBeRemoved)
            {
	            var handle = _allObjectInfos[instanceId];
	            AssetManager.Instance.UnloadAsset(handle);
	            
	            _allObjectInfos.Remove(instanceId);
	            _allInstanceIds.Remove(instanceId);
            }
        }

        public void AddCreatedGameObject(AssetHandle handle, GameObject go)
        {
	        var instanceId = go.GetInstanceID();
	        _allObjectInfos.Add(instanceId, handle);
	        _allInstanceIds.Add(instanceId);
        }

		public void OnLowMemory()
		{

		}
	}
}
