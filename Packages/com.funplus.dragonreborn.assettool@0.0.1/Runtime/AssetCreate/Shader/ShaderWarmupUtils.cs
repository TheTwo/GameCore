using System;
using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn.AssetTool
{
	public class ShaderWarmupUtils
	{
		private static readonly Dictionary<string, ShaderWarmupJob> WarmUpCollection = new();

		public static void Reset()
		{
			foreach (var job in WarmUpCollection)
			{
				job.Value.Dispose();
			}
			WarmUpCollection.Clear();
		}

		public static bool IsWarmedUp(string shaderVariant)
		{
			return WarmUpCollection.TryGetValue(shaderVariant, out var job) &&
			       job.JobStatus == ShaderWarmupJob.Status.WarmUpEnd;
		}

		public static bool IsInWarmUpping(string shaderVariant)
		{
			return WarmUpCollection.TryGetValue(shaderVariant, out var job) &&
			       job.JobStatus < ShaderWarmupJob.Status.WarmUpEnd;
		}

		public static bool Unload(string shaderVariant)
		{
			if (!WarmUpCollection.Remove(shaderVariant, out var job)) return false;
			job.Dispose();
			return true;
		}

		public static void WarmUpShaderVariants(string shaderVariant)
		{
			if (WarmUpCollection.TryGetValue(shaderVariant, out var job))
			{
				switch (job.JobStatus)
				{
					case ShaderWarmupJob.Status.WarmUpping:
						job.FinishWarmUpNow();
						return;
					case ShaderWarmupJob.Status.WarmUpEnd:
						return;
				}
				WarmUpCollection.Remove(shaderVariant);
				job.Dispose();
			}
			job = ShaderWarmupJob.SyncWarmup(shaderVariant);
			if (job == null) return;
			WarmUpCollection.Add(shaderVariant, job);
		}

		public static void WarmUpShaderVariantsAsync(string shaderVariant, int variantCountPreFrame)
		{
			if (WarmUpCollection.TryGetValue(shaderVariant, out var job))
			{
				job.UpdateVariantCountPreFrame(variantCountPreFrame);
				return;
			}
			job = ShaderWarmupJob.AsyncWarmup(shaderVariant, variantCountPreFrame);
			if (job == null) return;
			WarmUpCollection.Add(shaderVariant, job);
		}

		public static void Tick()
		{
			foreach (var shaderWarmupJob in WarmUpCollection)
			{
				shaderWarmupJob.Value.DoTick();
			}
		}

		private class ShaderWarmupJob
		{
			public enum Status
			{
				None,
				AssetLoading,
				WarmUpping,
				WarmUpEnd,
			}
			
			private AssetHandle _assetHandle;
			private Status _status;
			private int _variantCountPreFrame;
			private ShaderVariantCollection _collection;

			public Status JobStatus => _status;

			private ShaderWarmupJob()
			{ }

			public static ShaderWarmupJob SyncWarmup(string assetName)
			{
				var assetHandle = AssetManager.Instance.LoadAsset(assetName);
				if (assetHandle is not { IsValid: true })
				{
					AssetManager.Instance.UnloadAsset(assetHandle);
					return null;
				}
				var ret = new ShaderWarmupJob()
				{
					_assetHandle = assetHandle,
					_status = Status.AssetLoading,
				};
				ret.OnShaderLoaded(assetHandle.Asset is ShaderVariantCollection, assetHandle);
				ret.FinishWarmUpNow();
				return ret;
			}

			public static ShaderWarmupJob AsyncWarmup(string assetName, int variantCountPreFrame)
			{
				var ret = new ShaderWarmupJob
				{
					_status = Status.AssetLoading,
				};
				ret.UpdateVariantCountPreFrame(variantCountPreFrame);
				var assetHandle = AssetManager.Instance.LoadAssetAsync(assetName, ret.OnShaderLoaded);
				if (assetHandle is not { IsValid: true })
				{
					AssetManager.Instance.UnloadAsset(assetHandle);
					return null;
				}
				ret._assetHandle = assetHandle;
				return ret;
			}

			public void UpdateVariantCountPreFrame(int variantCountPreFrame)
			{
				_variantCountPreFrame = Math.Max(variantCountPreFrame, 1);
			}
			
			public void DoTick()
			{
				switch (_status)
				{
					case Status.WarmUpping:
						DoStepWarmUp();
						break;
				}
			}

			private void OnShaderLoaded(bool success, AssetHandle assetHandle)
			{
				_status = Status.WarmUpping;
				_collection = assetHandle.Asset as ShaderVariantCollection;
			}

			private void DoStepWarmUp()
			{
				if (_collection)
				{
					var leftCount = _collection.variantCount - _collection.warmedUpVariantCount;
					if (leftCount > 0)
					{
						var stepCount = Math.Min(leftCount, _variantCountPreFrame);
						_collection.WarmUpProgressively(stepCount);
						return;
					}
				}
				_status = Status.WarmUpEnd;
			}

			public void FinishWarmUpNow()
			{
				if (_collection)
				{
					var leftCount = _collection.variantCount - _collection.warmedUpVariantCount;
					if (leftCount > 0)
					{
						_collection.WarmUpProgressively(leftCount);
					}
				}
				_status = Status.WarmUpEnd;
			}

			public void Dispose()
			{
				switch (_status)
				{
					case Status.None:
						break;
					case Status.AssetLoading:
					case Status.WarmUpping:
					case Status.WarmUpEnd:
						if (_assetHandle is { IsValid: true })
						{
							AssetManager.Instance.UnloadAsset(_assetHandle);
							_collection = null;
							_assetHandle = null;
						}
						break;
				}
			}
		}
	}
}
