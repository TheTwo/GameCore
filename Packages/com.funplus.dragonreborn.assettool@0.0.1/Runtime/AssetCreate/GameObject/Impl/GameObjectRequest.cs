using UnityEngine;

namespace DragonReborn.AssetTool
{
	public delegate void GameObjectRequestCallback(GameObject go, object userData);
	public delegate void PooledGameObjectRequestCallback(GameObject go, object userData, PooledGameObjectHandle handle);

	internal class GameObjectRequest
	{
		public GameObjectCache Cache;
		public GameObjectRequestCallback Callback;
		public bool Cancel;
		public object UserData;
		public Transform Parent;
		public int Priority;
		public bool SyncCreate;
		public Vector3 Position;
		public Quaternion Rotation;
		public Vector3 Scale;

		public void Reset()
		{
			Cache = null;
			Callback = null;
			Cancel = false;
			UserData = null;
			Parent = null;
			Priority = 0;
			SyncCreate = false;
		}
	}
}