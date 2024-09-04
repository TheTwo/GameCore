using System;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Jobs;

public static class BytePtrHelper
{
	[BurstCompile]
	private unsafe struct BytePtrAndJob : IJobParallelForBatch
	{
		[NativeDisableUnsafePtrRestriction, ReadOnly]
		public byte* source1;
		[NativeDisableUnsafePtrRestriction, ReadOnly]
		public byte* source2;
		[NativeDisableUnsafePtrRestriction, WriteOnly]
		public byte* target;

		public void Execute(int startIndex, int count)
		{
			for (int i = 0; i < count; i++)
			{
				target[startIndex + i] = (byte)(source1[startIndex + i] & source2[startIndex + i]);
			}
		}
	}
	
	public static unsafe void And(IntPtr source1, IntPtr source2, IntPtr target, int length)
	{
		var src1 = (byte*)source1.ToPointer();
		var src2 = (byte*)source2.ToPointer();
		var tar = (byte*)target.ToPointer();
		var job = new BytePtrAndJob
		{
			source1 = src1,
			source2 = src2,
			target = tar,
		};
		var coreCount = Environment.ProcessorCount;
		job.ScheduleBatch(length, Math.Max(16, length / coreCount)).Complete();
	}
}
