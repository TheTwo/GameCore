using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using U2D;
using UnityEngine;
using UnityEngine.Pool;

[ExecuteInEditMode]
[DisallowMultipleComponent]
public sealed class U2DHorizontalLayoutGroup : MonoBehaviour
{
	[Flags]
	public enum RebuildFunc
	{
		Manual = 0,
		Start = 1,
		Update = 1 << 1,
		LateUpdate = 1 << 2,
	}
	
	[SerializeField] private RebuildFunc rebuildFunc = RebuildFunc.Start | RebuildFunc.Update;
	[SerializeField] private U2DAnchor.Side pivot = U2DAnchor.Side.Top;
	[SerializeField] private U2DWidgetMesh stretchBackground;
	
	[FoldoutGroup("Padding"), SerializeField] private float paddingLeft;
	[FoldoutGroup("Padding"), SerializeField] private float paddingRight;
	[FoldoutGroup("Padding"), SerializeField] private float paddingBottom;
	[FoldoutGroup("Padding"), SerializeField] private float paddingTop;
	[SerializeField] private float pixelSize = 1f;

	private List<U2DLayoutElement> _children;
	private float _width;
	private float _height;
	private readonly List<float> _offset = new();

	public Rect Rect
	{
		get
		{
			var pivotValue = GetPivotOffset(pivot);
			var position = new Vector2(-_width * pivotValue.x, -_height * pivotValue.y);
			var size = new Vector2(_width, _height);
			position *= pixelSize;
			size *= pixelSize;
			return new Rect(position, size);
		}
	}
	
	private IReadOnlyList<U2DLayoutElement> GetChildList()
	{
		_children ??= new List<U2DLayoutElement>();
		var myTrans = transform;
		_children.Clear();

		for (var i = 0; i < myTrans.childCount; ++i)
		{
			var t = myTrans.GetChild(i);
			if (t.gameObject.activeSelf && t.gameObject.GetComponent<U2DLayoutElement>())
				_children.Add(t.gameObject.GetComponent<U2DLayoutElement>());
		}

		return _children;
	}

	private void Start()
	{
		if ((rebuildFunc & RebuildFunc.Start) == 0) return;
		RepositionNow();
		enabled = false;
	}

	private void Update()
	{
		if ((rebuildFunc & RebuildFunc.Update) == 0) return;
		RepositionNow();
		enabled = false;
	}

	private void LateUpdate()
	{
		if ((rebuildFunc & RebuildFunc.LateUpdate) == 0) return;
		RepositionNow();
		enabled = false;
	}

	[ContextMenu("RepositionNow")]
	public void RepositionNow()
	{
		var list = GetChildList();
		ResetPosition(list);
	}
	
	private void ResetPosition(IReadOnlyList<U2DLayoutElement> list)
    {
    	_width = 0f;
    	_height = 0f;
        _offset.Clear();
    	if (list.Count <= 0)
    	{
    		DoStretchBackground();
    		return;
    	}
    	using (ListPool<Vector3>.Get(out var localPosList))
    	{
    		for (var index = 0; index < list.Count; index++)
    		{
    			var t = list[index];
    			var pos = t.transform.localPosition;
    			var depth = pos.z;

                pos = new Vector3(_width + t.width / 2, 0, depth);
    			localPosList.Add(pos);
    			t.transform.localPosition = pos;
                
                _width += t.width;
                _height = Mathf.Max(_height, t.height);
            }
    		DoStretchBackground();
    		var po = GetPivotOffset(pivot);
            var fx = Mathf.Lerp(0f, _width, po.x);
    		for (var i = 0; i < list.Count; ++i)
    		{
    			var t = list[i];
    			var pos = localPosList[i];
    			pos.x -= fx;
                pos.y -= Mathf.Lerp(-0.5f, 0.5f, po.y) * t.height;
    			t.transform.localPosition = pos;
    		}
    	}
    }
	
	private float GetElementOffset(U2DAnchor.Side pv)
    {
        var v = 0f;
        v = pv switch
        {
            U2DAnchor.Side.Top or U2DAnchor.Side.Center or U2DAnchor.Side.Bottom => 0.5f,
            U2DAnchor.Side.TopRight or U2DAnchor.Side.Right or U2DAnchor.Side.BottomRight => 1f,
            _ => 0f
        };
        return v;
    }
	
	private unsafe void DoStretchBackground()
    {
    	if (!stretchBackground) return;
    	var sourceRect = Rect;

    	var sourceMin = sourceRect.min;
    	var sourceMax = sourceRect.max;
    	var sourceCenter = sourceRect.center;
    	var sourcePixelSize = pixelSize;
    	sourceMin.x -= paddingLeft * sourcePixelSize;
    	sourceMax.x += paddingRight * sourcePixelSize;

    	sourceMin.y -= paddingBottom * sourcePixelSize;
    	sourceMax.y += paddingTop * sourcePixelSize;

    	sourceRect.min = sourceMin;
    	sourceRect.max = sourceMax;

    	var sourceTransform = transform;
    	var targetTransform = stretchBackground.transform;

    	var z = targetTransform.localPosition.z;
    	targetTransform.rotation = sourceTransform.rotation;

    	var corners = stackalloc Vector3[4];
    	U2DUtils.CalculateRectCorners(sourceRect, corners);
    	U2DUtils.TransformCorners(corners, sourceTransform.localToWorldMatrix);
    	targetTransform.position = 0.5f * (corners[0] + corners[2]);

    	U2DUtils.TransformCorners(corners, targetTransform.worldToLocalMatrix);
    	var targetPixelsPerUnit = 1f / stretchBackground.pixelSize;
    	var width = corners[2].x - corners[1].x;
    	var height = corners[1].y - corners[0].y;
    	stretchBackground.width = width * targetPixelsPerUnit;
    	stretchBackground.height = height * targetPixelsPerUnit;
    	var targetPivot = stretchBackground.pivot;
    	var offset = new Vector3(width * (targetPivot.x - 0.5f), height * (targetPivot.y - 0.5f));
    	var localPosition = targetTransform.localPosition + offset;
    	localPosition.z = z;
    	targetTransform.localPosition = localPosition;
    }
	
	private static Vector2 GetPivotOffset(U2DAnchor.Side pv)
	{
		var v = Vector2.zero;
		v.x = pv switch
		{
			U2DAnchor.Side.Top or U2DAnchor.Side.Center or U2DAnchor.Side.Bottom => 0.5f,
			U2DAnchor.Side.TopRight or U2DAnchor.Side.Right or U2DAnchor.Side.BottomRight => 1f,
			_ => 0f
		};
		v.y = pv switch
		{
			U2DAnchor.Side.Left or U2DAnchor.Side.Center or U2DAnchor.Side.Right => 0.5f,
			U2DAnchor.Side.TopLeft or U2DAnchor.Side.Top or U2DAnchor.Side.TopRight => 1f,
			_ => 0f
		};
		return v;
	}
	
	private void OnTransformChildrenChanged()
	{
		if (rebuildFunc == RebuildFunc.Manual) return;
		if (null != _children)
		{
			using (HashSetPool<U2DLayoutElement>.Get(out var tmpSet))
			{
				tmpSet.UnionWith(_children);
				GetChildList();
				if (tmpSet.Count == _children.Count)
				{
					tmpSet.ExceptWith(_children);
					if (tmpSet.Count <= 0)
					{
						return;
					}
				}
			}
		}

		enabled = true;
	}
	
#if UNITY_EDITOR
	private void OnValidate()
	{
		if (Application.isPlaying || rebuildFunc == RebuildFunc.Manual) return;
		RepositionNow();
	}
#endif
}
