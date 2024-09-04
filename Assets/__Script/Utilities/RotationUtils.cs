using UnityEngine;

public static class RotationUtils
{
	public static Quaternion LookAtRotation(Transform from, Transform to, bool inPlane = true, float yAxisAdjust = 0f)
	{
		var fromPosition = from.position;
		var toPosition = to.position;
		return LookAtRotation(fromPosition, toPosition, inPlane, yAxisAdjust);
	}

	public static Quaternion LookAtRotation(Vector3 from, Vector3 to, bool inPlane = true, float yAxisAdjust = 0f)
	{
		var fromPosFinal = inPlane ? new Vector3(from.x, 0, from.z) : from;
		var toPosFinal = inPlane ? new Vector3(to.x, 0, to.z) : to;
		var basic = Quaternion.LookRotation((toPosFinal - fromPosFinal).normalized);
		return basic * Quaternion.AngleAxis(yAxisAdjust, Vector3.up);
	}
}
