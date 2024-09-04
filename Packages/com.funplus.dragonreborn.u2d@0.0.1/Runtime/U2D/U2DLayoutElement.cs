using System;
using UnityEngine;

public class U2DLayoutElement : MonoBehaviour
{
	public float width;
	public float height;

	private unsafe void OnDrawGizmosSelected()
	{
		var bottomLeft = new Vector2(transform.position.x - width / 2, transform.position.y - height / 2);
		var rect = new Rect(bottomLeft, new Vector2(width, height));
        var corners = stackalloc Vector3[4];
        U2DUtils.CalculateRectCorners(rect, corners);
        U2DUtils.TransformCorners(corners, transform.localToWorldMatrix);
        Gizmos.color = Color.green;
        Gizmos.DrawLine(corners[0], corners[1]);
        Gizmos.DrawLine(corners[1], corners[2]);
        Gizmos.DrawLine(corners[2], corners[3]);
        Gizmos.DrawLine(corners[3], corners[0]);
	}
}
