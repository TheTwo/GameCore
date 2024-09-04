using UnityEngine;

namespace DragonReborn.AssetTool
{
	internal struct GameObjectPoolDelayRecycle
	{
		public GameObjectCache Cache;
		public GameObject Instance;
		public float Remaining;

		public void Destroy()
		{
			if (!Instance)
			{
				return;
			}

#if UNITY_EDITOR
			if (Application.isPlaying)
			{
				Object.Destroy(Instance);
			}
			else
			{
				Object.DestroyImmediate(Instance);
			}
#else
			Object.Destroy(Instance);
#endif
		}
	}

}
