using System;
using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace Utilities
{
	public static class CommonInstancingBaker
	{
		public static void Bake(Transform root, IEnumerable<Transform> toBakes, IDictionary<InstancingBrushInfo.Key, InstancingBrushInfo> brushes)
		{
			if (!root) return;
			brushes ??= new Dictionary<InstancingBrushInfo.Key, InstancingBrushInfo>();
			var rootRot = root.rotation;
			var rootScale = root.lossyScale;
			var inverseRootRot = Quaternion.Inverse(rootRot);
			using var handle = UnityEngine.Rendering.ListPool<MeshFilter>.Get(out var components);
			foreach (var bake in toBakes)
			{
				components.Clear();
				bake.GetComponentsInChildren(components);
				foreach (var meshFilter in components)
				{
					var r = meshFilter.GetComponent<Renderer>();
					if (!r) continue;
					var mat = r.sharedMaterial;
					var mesh = meshFilter.sharedMesh;
					if (!mat || ! mesh) continue;
					var key = new InstancingBrushInfo.Key(mat.GetInstanceID(), mesh.GetInstanceID());
					if (!brushes.TryGetValue(key, out var brush))
					{
						brush = new InstancingBrushInfo(key, mat, mesh);
						brushes.Add(brush.BrushKey, brush);
					}
					var tran = meshFilter.transform;
					var relativePos = root.InverseTransformPoint(tran.position);
					var relativeRot = inverseRootRot * tran.rotation;
					var lossyScale = tran.lossyScale;
					var relativeScale = new Vector3(lossyScale.x / rootScale.x, lossyScale.y / rootScale.y,
						lossyScale.z / rootScale.z);
					brush.matrix.Add(Matrix4x4.TRS(relativePos, relativeRot, relativeScale));
				}
			}
		}
		
		public static void Bake2(Transform root, IEnumerable<Transform> toBakes, IDictionary<InstancingBrushInfo2.Key, InstancingBrushInfo2> brushes)
		{
			if (!root) return;
			brushes ??= new Dictionary<InstancingBrushInfo2.Key, InstancingBrushInfo2>();
			var rootRot = root.rotation;
			var rootScale = root.lossyScale;
			var inverseRootRot = Quaternion.Inverse(rootRot);
			using var handle = UnityEngine.Rendering.ListPool<MeshFilter>.Get(out var components);
			foreach (var bake in toBakes)
			{
				components.Clear();
				bake.GetComponentsInChildren(components);
				foreach (var meshFilter in components)
				{
					var r = meshFilter.GetComponent<Renderer>();
					if (!r) continue;
					var mat = r.sharedMaterials;
					var mesh = meshFilter.sharedMesh;
					if (mat.Length <= 0 || ! mesh) continue;
					var key = new InstancingBrushInfo2.Key(mesh, mat);
					if (!brushes.TryGetValue(key, out var brush))
					{
						brush = new InstancingBrushInfo2(key, mat, mesh);
						brushes.Add(brush.BrushKey, brush);
					}
					var tran = meshFilter.transform;
					var relativePos = root.InverseTransformPoint(tran.position);
					var relativeRot = inverseRootRot * tran.rotation;
					var lossyScale = tran.lossyScale;
					var relativeScale = new Vector3(lossyScale.x / rootScale.x, lossyScale.y / rootScale.y,
						lossyScale.z / rootScale.z);
					brush.matrix.Add(Matrix4x4.TRS(relativePos, relativeRot, relativeScale));
				}
			}
		}
	}

	[Serializable]
	public class InstancingBrushInfo
	{
		public struct Key : IEquatable<Key>
		{
			private readonly int _matInstanceId;
			private readonly int _meshInstanceId;
	
			public Key(int matInstanceId, int meshInstanceId)
			{
				_matInstanceId = matInstanceId;
				_meshInstanceId = meshInstanceId;
			}
	
			public bool Equals(Key other)
			{
				return _matInstanceId == other._matInstanceId && _meshInstanceId == other._meshInstanceId;
			}
	
			public override bool Equals(object obj)
			{
				return obj is Key other && Equals(other);
			}
	
			public override int GetHashCode()
			{
				return HashCode.Combine(_matInstanceId, _meshInstanceId);
			}
		}
	
		public readonly Key BrushKey;
		public Material mat;
		public Mesh mesh;
		public List<Matrix4x4> matrix;
	
		public InstancingBrushInfo(Key key, Material mat, Mesh mesh)
		{
			BrushKey = key;
			this.mat = mat;
			this.mesh = mesh;
			matrix = new List<Matrix4x4>();
		}
	}
	
	[Serializable]
	public class InstancingBrushInfo2
	{
		public struct Key : IEquatable<Key>
		{
			private readonly int _meshInstanceId;
			private readonly int[] _matInstanceIds;

			public Key(Mesh mesh, Material[] materials)
			{
				_meshInstanceId = mesh.GetInstanceID();
				_matInstanceIds = new int[materials.Length];
				for (var i = 0; i < materials.Length; i++)
				{
					if (materials[i])
						_matInstanceIds[i] = materials[i].GetInstanceID();
					else
						_matInstanceIds[i] = 0;
				}
				Array.Sort(_matInstanceIds);
			}

			public bool Equals(Key other)
			{
				if (_meshInstanceId != other._meshInstanceId) return false;
				if (_matInstanceIds.Length != other._matInstanceIds.Length) return false;
				for (var i = 0; i < _matInstanceIds.Length; i++)
				{
					if (_matInstanceIds[i] != other._matInstanceIds[i]) return false;
				}
				return true;
			}

			public override bool Equals(object obj)
			{
				return obj is Key other && Equals(other);
			}

			public override int GetHashCode()
			{
				if (null == _matInstanceIds) return 0;
				unchecked
				{
					var hc = _matInstanceIds.Length;
					foreach (var val in _matInstanceIds)
					{
						hc = unchecked(hc * 314159 + val);
					}
					return hc;
				}
			}
		}

		public readonly Key BrushKey;
		public Material[] mat;
		public Mesh mesh;
		public int subMeshCount;
		public List<Matrix4x4> matrix;

		public InstancingBrushInfo2(Key key, Material[] mat, Mesh mesh)
		{
			BrushKey = key;
			subMeshCount = Math.Max(1, Math.Min(mesh.subMeshCount, mat.Length));
			this.mat = new Material[subMeshCount];
			for (int i = 0; i < this.mat.Length; i++)
			{
				this.mat[i] = mat[i];
			}
			this.mesh = mesh;
			matrix = new List<Matrix4x4>();
		}
	}
}