using UnityEngine;
using System.IO;

#if UNITY_EDITOR
using UnityEditor;
#endif

public static unsafe class U2DUtils
{
	public static void CalculateRectCorners(Rect rect, Vector3* corners)
	{
		var min = rect.min;
		var max = rect.max;

		corners[0] = min;
		corners[1] = new Vector3(min.x, max.y);
		corners[2] = max;
		corners[3] = new Vector3(max.x, min.y);
	}

	public static void TransformCorners(Vector3* corners, Matrix4x4 transform)
	{
		corners[0] = transform.MultiplyPoint(corners[0]);
		corners[1] = transform.MultiplyPoint(corners[1]);
		corners[2] = transform.MultiplyPoint(corners[2]);
		corners[3] = transform.MultiplyPoint(corners[3]);
	}

	public static void LineRectIntersection(Ray ray, Rect rect, out Vector3 result)
	{
		result = default;

		var planes = stackalloc Plane[4];
		planes[0] = new Plane(new Vector3(rect.xMax - rect.xMin, 0), new Vector3(rect.xMin, rect.yMin));
		planes[1] = new Plane(new Vector3(rect.xMin - rect.xMax, 0), new Vector3(rect.xMax, rect.yMax));
		planes[2] = new Plane(new Vector3(0, rect.yMax - rect.yMin), new Vector3(rect.xMin, rect.yMin));
		planes[3] = new Plane(new Vector3(0, rect.yMin - rect.yMax), new Vector3(rect.xMax, rect.yMax));

		var minDist = float.MaxValue;
		for (var i = 0; i < 4; i++)
		{
			ref var plane = ref planes[i];
			if (!plane.Raycast(ray, out var dist))
			{
				continue;
			}

			if (dist > minDist)
			{
				continue;
			}

			minDist = dist;
			result = ray.GetPoint(dist);
		}
	}

	public static int GetSortingLayer(this U2DWidgetMesh widgetMesh)
	{
		var renderer = widgetMesh.GetComponent<MeshRenderer>();
		return renderer ? SortingLayer.GetLayerValueFromID(renderer.sortingLayerID) : 0;
	}

	public static int GetSortingOrder(this U2DWidgetMesh widgetMesh)
	{
		var renderer = widgetMesh.GetComponent<MeshRenderer>();
		return renderer ? renderer.sortingOrder : 0;
	}

	public static T FindAsset<T>(string name, string filter) where T : Object
	{
#if UNITY_EDITOR
		var guids = AssetDatabase.FindAssets($"{name} t:{filter}");
		if (guids is { Length: > 0 })
		{
			foreach (var guid in guids)
			{
				var path = AssetDatabase.GUIDToAssetPath(guid);
				var assetName = Path.GetFileNameWithoutExtension(path);
				if (assetName == name)
				{
					return AssetDatabase.LoadAssetAtPath<T>(path);
				}
			}
		}
#endif
		return null;
	}
}