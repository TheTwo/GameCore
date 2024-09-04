using UnityEngine;

[ExecuteInEditMode]
public unsafe class U2DAnchor : U2DComponent
{
	public enum Side
	{
		BottomLeft,
		Left,
		TopLeft,
		Top,
		TopRight,
		Right,
		BottomRight,
		Bottom,
		Center,
	}

	[SerializeField] private U2DWidgetMesh m_Source;
	[SerializeField] private Side m_Side = Side.Center;

	public U2DWidgetMesh source => m_Source;
	public Side side => m_Side;

	public bool Enabled => enabled;
	
#if UNITY_EDITOR
	private void LateUpdate()
	{
		if (Application.isPlaying)
		{
			return;
		}

		DoLateUpdate();
	}
#endif

	public override void DoUpdate()
	{
		
	}

	public override void DoLateUpdate()
	{
		if (!m_Source)
		{
			return;
		}

		var corners = stackalloc Vector3[4];

		var sourceRect = m_Source.rect;
		U2DUtils.CalculateRectCorners(sourceRect, corners);

		var sourceTransform = m_Source.transform;
		U2DUtils.TransformCorners(corners, sourceTransform.localToWorldMatrix);

		var targetTransform = transform;
		var localPosition = targetTransform.localPosition;
		var z = localPosition.z;
		targetTransform.rotation = sourceTransform.rotation;

		switch (m_Side)
		{
			case Side.BottomLeft:
				targetTransform.position = corners[0];
				break;

			case Side.Left:
				targetTransform.position = 0.5f * (corners[0] + corners[1]);
				break;

			case Side.TopLeft:
				targetTransform.position = corners[1];
				break;

			case Side.Top:
				targetTransform.position = 0.5f * (corners[1] + corners[2]);
				break;

			case Side.TopRight:
				targetTransform.position = corners[2];
				break;

			case Side.Right:
				targetTransform.position = 0.5f * (corners[2] + corners[3]);
				break;

			case Side.BottomRight:
				targetTransform.position = corners[3];
				break;

			case Side.Bottom:
				targetTransform.position = 0.5f * (corners[0] + corners[3]);
				break;

			case Side.Center:
				targetTransform.position = 0.5f * (corners[0] + corners[2]);
				break;
		}

		localPosition = targetTransform.localPosition;
		localPosition.z = z;
		targetTransform.localPosition = localPosition;
	}
}
