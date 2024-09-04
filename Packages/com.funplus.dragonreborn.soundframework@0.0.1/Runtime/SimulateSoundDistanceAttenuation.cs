using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Jobs;

// ReSharper disable once CheckNamespace
namespace DragonReborn.Sound
{
    public class SimulateSoundDistanceAttenuation : MonoBehaviour
    {
        private static IFrameworkSoundManager _mgr;
        private static Vector3? _listenerPosition;
        private static float _maxDistance = -1f;
        private static readonly List<SimulateSoundDistanceAttenuation> NeedTickList = new(12);

        public static void Setup(IFrameworkSoundManager mgr, float maxDistance)
        {
            _mgr = mgr;
            _maxDistance = maxDistance;
        }

        public static void UpdateMaxDistance(float maxDistance)
        {
            _maxDistance = maxDistance;
        }

        public static void ShutDown()
        {
            NeedTickList.Clear();
            _listenerPosition = null;
            _mgr = null;
            _maxDistance = -1f;
        }

        private bool _set;
        private string _eventName;
        private uint _playingId;
        private float _minValue;
        private float _maxValue;

        public void Init(string eventName, uint playingId, Vector2 range)
        {
            _eventName = eventName;
            _playingId = playingId;
            _minValue = range.x;
            _maxValue = range.y;
            _set = true;
        }

        public void Clear()
        {
            if (!_set) return;
            _set = false;
            _eventName = string.Empty;
            _playingId = 0;
            _minValue = 0f;
            _maxValue = 0f;
            NeedTickList.Remove(this);
        }

        private void OnEnable()
        {
            if (!_set) return;
            NeedTickList.Add(this);
        }

        private void OnDisable()
        {
            NeedTickList.Remove(this);
            if (!_set) return;
            _mgr.SetCustomRTPCOnGameObj(_eventName, gameObject, _maxValue);
        }

        public static void SetListenerPos(Vector3? pos)
        {
            _listenerPosition = pos;
            if (_listenerPosition.HasValue) return;
            foreach (var d in NeedTickList)
            {
                _mgr.SetCustomRTPCOnGameObj(d._eventName, d.gameObject, d._maxValue);
            }
        }

        public static void Tick()
        {
            if (!_listenerPosition.HasValue) return;
            var needProcessCount = NeedTickList.Count;
            if (needProcessCount <= 0) return;
            if (_mgr == null) return;
            if (_maxDistance <= 0) return;
            TransformAccessArray.Allocate(needProcessCount, -1, out var transformAccessArray);
            var minArray = new NativeArray<float>(needProcessCount, Allocator.TempJob,
                NativeArrayOptions.UninitializedMemory);
            var maxArray = new NativeArray<float>(needProcessCount, Allocator.TempJob,
                NativeArrayOptions.UninitializedMemory);
            using var result = new NativeArray<float>(needProcessCount, Allocator.TempJob,
                NativeArrayOptions.UninitializedMemory);
            for (var index = 0; index < NeedTickList.Count; index++)
            {
                var d = NeedTickList[index];
                transformAccessArray.Add(d.transform);
                minArray[index] = d._minValue;
                maxArray[index] = d._maxValue;
            }
            using (transformAccessArray)
            {
                using (minArray)
                {
                    using (maxArray)
                    {
                        var job = new UpdateAttenuation()
                        {
                            Target = _listenerPosition.Value,
                            MaxDistance = _maxDistance,
                            MinValues = minArray,
                            MaxValues = maxArray,
                            Result = result,
                        };
                        job.ScheduleReadOnly(transformAccessArray, 8).Complete();
                    }
                }
            }
            for (var index = 0; index < NeedTickList.Count; index++)
            {
                var d = NeedTickList[index];
                var r = result[index];
                _mgr.SetCustomRTPCOnGameObj(d._eventName, d.gameObject, r);
            }
        }

        private struct UpdateAttenuation : IJobParallelForTransform
        {
            public Vector3 Target;
            public float MaxDistance;
            [ReadOnly] public NativeArray<float> MinValues;
            [ReadOnly] public NativeArray<float> MaxValues;
            [WriteOnly] public NativeArray<float> Result;
            
            public void Execute(int index, TransformAccess transform)
            {
                var minValue = MinValues[index];
                var maxValue = MaxValues[index];
                var distance = (transform.position - Target).magnitude;
                var r = Mathf.InverseLerp(0, MaxDistance, distance);
                Result[index] = Mathf.Lerp(minValue, maxValue, r);
            }
        }
    }
}