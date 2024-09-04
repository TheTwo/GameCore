using Sirenix.OdinInspector;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(U2DWidgetMesh))]
public unsafe class U2DStretch : MonoBehaviour
{
	[SerializeField] U2DWidgetMesh m_Source;
	[SerializeField] U2DWidgetMesh m_Target;
	[SerializeField] bool m_FitHorizontal;
	[SerializeField, HideIf(nameof(m_FitHorizontal))] float m_FixWidth;
	[SerializeField] bool m_FitVertical;
	[SerializeField, HideIf(nameof(m_FitVertical))] float m_FixHeight;
	[Header("Offsets")]
	[SerializeField] float m_Left;
	[SerializeField] float m_Right;
	[SerializeField] float m_Bottom;
	[SerializeField] float m_Top;

	public U2DWidgetMesh source => m_Source;
	public U2DWidgetMesh target => m_Target;
	public bool fitHorizontal => m_FitHorizontal;
	public float fixWidth => m_FixWidth;
	public bool fitVertical => m_FitVertical;
	public float fixHeight => m_FixHeight;
	public float left => m_Left;
	public float right => m_Right;
	public float bottom => m_Bottom;
	public float top => m_Top;
	
	private void Awake()
	{
		InitOnce();
	}

	private void InitOnce()
	{
		if (m_Target == null)
		{
			m_Target = GetComponentInChildren<U2DWidgetMesh>(true);
		}
	}

	private void LateUpdate()
	{
		if (!m_Source || !m_Target)
		{
			return;
		}

		var sourceRect = m_Source.rect;

		var sourceMin = sourceRect.min;
		var sourceMax = sourceRect.max;
		var sourceCenter = sourceRect.center;
		var sourcePixelSize = m_Source.pixelSize;
		if (m_FitHorizontal)
		{
			sourceMin.x -= m_Left * sourcePixelSize;
			sourceMax.x += m_Right * sourcePixelSize;
		}
		else
		{
			sourceMin.x = sourceCenter.x - m_FixWidth / 2f;
			sourceMax.x = sourceCenter.x + m_FixWidth / 2f;
		}

		if (m_FitVertical)
		{
			sourceMin.y -= m_Bottom * sourcePixelSize;
			sourceMax.y += m_Top * sourcePixelSize;
		}
		else
		{
			sourceMin.y = sourceCenter.y - m_FixHeight / 2f;
			sourceMax.y = sourceCenter.y + m_FixHeight / 2f;
		}

		sourceRect.min = sourceMin;
		sourceRect.max = sourceMax;

		var sourceTransform = m_Source.transform;
		var targetTransform = m_Target.transform;

		var z = targetTransform.localPosition.z;
		targetTransform.rotation = sourceTransform.rotation;

		var corners = stackalloc Vector3[4];
		U2DUtils.CalculateRectCorners(sourceRect, corners);
		U2DUtils.TransformCorners(corners, sourceTransform.localToWorldMatrix);
		targetTransform.position = 0.5f * (corners[0] + corners[2]);

		U2DUtils.TransformCorners(corners, targetTransform.worldToLocalMatrix);
		var targetPixelsPerUnit = 1f / m_Target.pixelSize;
		var width = corners[2].x - corners[1].x;
		var height = corners[1].y - corners[0].y;
		m_Target.width = width * targetPixelsPerUnit;
		m_Target.height = height * targetPixelsPerUnit;

		var pivot = m_Target.pivot;
		var offset = new Vector3(width * (pivot.x - 0.5f), height * (pivot.y - 0.5f));
		var localPosition = targetTransform.localPosition + offset;
		localPosition.z = z;
		targetTransform.localPosition = localPosition;
	}
}
