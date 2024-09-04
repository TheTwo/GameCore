using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Pool;

namespace U2D
{
	[ExecuteInEditMode]
	[DisallowMultipleComponent]
	public class U2DGrid : MonoBehaviour
	{
		[Flags]
		public enum RebuildFunc
		{
			Manual = 0,
			Start = 1,
			Update = 1 << 1,
			LateUpdate = 1 << 2,
		}

		public enum Arrangement
		{
			Horizontal,
			Vertical,
		}

		[SerializeField] private RebuildFunc rebuildFunc = RebuildFunc.Start | RebuildFunc.Update;
		[SerializeField] private Arrangement arrangement = Arrangement.Horizontal;
		[SerializeField] private U2DAnchor.Side pivot = U2DAnchor.Side.Top;
		[SerializeField] private U2DWidgetMesh stretchBackground;
		[SerializeField] private bool fitHorizontal;
		[SerializeField, HideIf(nameof(fitHorizontal))] private float fixWidth;
		[SerializeField] private bool fitVertical;
		[SerializeField, HideIf(nameof(fitVertical))] private float fixHeight;
		[Header("Padding")] [SerializeField] private float paddingLeft;
		[SerializeField] private float paddingRight;
		[SerializeField] private float paddingBottom;
		[SerializeField] private float paddingTop;

		[SerializeField] private int maxPerLine;
		[SerializeField] private float cellWidth = 10;
		[SerializeField] private float cellHeight = 10;
		[SerializeField] private float pixelSize = 1f;

		private List<Transform> _children;
		private float _width;
		private float _height;

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

		private IReadOnlyList<Transform> GetChildList()
		{
			_children ??= new List<Transform>();
			var myTrans = transform;
			_children.Clear();

			for (var i = 0; i < myTrans.childCount; ++i)
			{
				var t = myTrans.GetChild(i);
				if (t.gameObject.activeSelf)
					_children.Add(t);
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

		private void ResetPosition(IReadOnlyList<Transform> list)
		{
			var x = 0;
			var y = 0;
			var maxX = 0;
			var maxY = 0;
			_width = 0f;
			_height = 0f;
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
					var pos = t.localPosition;
					var depth = pos.z;

					pos = arrangement switch
					{
						Arrangement.Horizontal => new Vector3(cellWidth * x, -cellHeight * y, depth),
						Arrangement.Vertical => new Vector3(cellWidth * y, -cellHeight * x, depth),
						_ => throw new ArgumentOutOfRangeException()
					};
					localPosList.Add(pos);
					t.localPosition = pos;
					maxX = Mathf.Max(maxX, x);
					maxY = Mathf.Max(maxY, y);
					if (++x < maxPerLine || maxPerLine <= 0) continue;
					x = 0;
					++y;
				}
				_width = (maxX + 1) * cellWidth;
				_height = (maxY + 1) * cellHeight;
				DoStretchBackground();
				var po = GetPivotOffset(pivot);
				float fx, fy;
				if (arrangement == Arrangement.Horizontal)
				{
					fx = Mathf.Lerp(0f, maxX * cellWidth, po.x);
					fy = Mathf.Lerp(-maxY * cellHeight, 0f, po.y);
				}
				else
				{
					fx = Mathf.Lerp(0f, maxY * cellWidth, po.x);
					fy = Mathf.Lerp(-maxX * cellHeight, 0f, po.y);
				}

				fx += cellWidth * Mathf.Lerp(-0.5f, 0.5f, po.x);
				fy += cellHeight * Mathf.Lerp(-0.5f, 0.5f, po.y);
				for (var i = 0; i < list.Count; ++i)
				{
					var t = list[i];
					var pos = localPosList[i];
					pos.x -= fx;
					pos.y -= fy;
					t.localPosition = pos;
				}
			}
		}

		private unsafe void DoStretchBackground()
		{
			if (!stretchBackground) return;
			var sourceRect = Rect;

			var sourceMin = sourceRect.min;
			var sourceMax = sourceRect.max;
			var sourceCenter = sourceRect.center;
			var sourcePixelSize = pixelSize;
			if (fitHorizontal)
			{
				sourceMin.x -= paddingLeft * sourcePixelSize;
				sourceMax.x += paddingRight * sourcePixelSize;
			}
			else
			{
				sourceMin.x = sourceCenter.x - fixWidth * 0.5f;
				sourceMax.x = sourceCenter.x + fixWidth * 0.5f;
			}

			if (fitVertical)
			{
				sourceMin.y -= paddingBottom * sourcePixelSize;
				sourceMax.y += paddingTop * sourcePixelSize;
			}
			else
			{
				sourceMin.y = sourceCenter.y - fixHeight * 0.5f;
				sourceMax.y = sourceCenter.y + fixHeight * 0.5f;
			}

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

		private void OnTransformChildrenChanged()
		{
			if (rebuildFunc == RebuildFunc.Manual) return;
			if (null != _children)
			{
				using (HashSetPool<Transform>.Get(out var tmpSet))
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

#if UNITY_EDITOR
		private void OnValidate()
		{
			if (Application.isPlaying || rebuildFunc == RebuildFunc.Manual) return;
			RepositionNow();
		}
#endif
	}
}
