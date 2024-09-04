using System;
using UnityEngine;

[RequireComponent(typeof(U2DWidgetMesh))]
// ReSharper disable once CheckNamespace
public class U2DAnimHelper : MonoBehaviour
{
	// ReSharper disable InconsistentNaming
	public float m_Width;
	public float m_Height;
	public Color m_Color = Color.white;
	public Vector2 m_Pivot = new Vector2(0.5f, 0.5f);
	public float m_PixelSize = 1f;

	private float? m_WidthLast;
	private float? m_HeightLast;
	private Color? m_ColorLast;
	private Vector2? m_PivotLast;
	private float? m_PixelSizeLast;

	private U2DWidgetMesh m_Mesh;
	// ReSharper restore InconsistentNaming

	private void InitData()
	{
		if (m_Mesh == null) return;
		m_WidthLast = m_Mesh.width;
		m_HeightLast = m_Mesh.height;
		m_ColorLast = m_Mesh.color;
		m_PivotLast = m_Mesh.pivot;
		m_PixelSizeLast = m_Mesh.pixelSize;
	}

	private void InitOnce()
	{
		if (m_Mesh) return;
		m_Mesh = GetComponent<U2DWidgetMesh>();
		InitData();
	}

	private static bool ColorEquals(Color32 a, Color32 b)
	{
		return a.a == b.a 
			&& a.r == b.r 
			&& a.g == b.g 
			&& a.b == b.b;
	}

	private void OnDidApplyAnimationProperties()
	{
		if (!isActiveAndEnabled) return;
		InitOnce();
		if (m_Mesh == null) return;
		if (!m_WidthLast.HasValue || Math.Abs(m_WidthLast.Value - m_Width) > 0.00001f)
		{
			m_WidthLast = m_Width;
			m_Mesh.width = m_Width;
		}
		if (!m_HeightLast.HasValue || Math.Abs(m_HeightLast.Value - m_Height) > 0.00001f)
		{
			m_HeightLast = m_Height;
			m_Mesh.height = m_Height;
		}
		if (!m_ColorLast.HasValue || !ColorEquals(m_ColorLast.Value, m_Color))
		{
			m_ColorLast = m_Color;
			m_Mesh.color = m_Color;
		}
		if (!m_PivotLast.HasValue || !m_PivotLast.Value.Equals(m_Pivot))
		{
			m_PivotLast = m_Pivot;
			m_Mesh.pivot = m_Pivot;
		}
		if (!m_PixelSizeLast.HasValue || Math.Abs(m_PixelSizeLast.Value - m_PixelSize) > 00001f)
		{
			m_PixelSizeLast = m_PixelSize;
			m_Mesh.pixelSize = m_PixelSize;
		}
	}
}
