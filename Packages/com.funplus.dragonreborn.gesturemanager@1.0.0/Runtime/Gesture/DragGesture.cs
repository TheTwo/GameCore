using UnityEngine;

namespace DragonReborn
{
	public struct DragGesture
	{
		public GesturePhase phase;
		public Vector3 position;
		public Vector3 lastPosition;
		public Vector3 delta;
	}
}