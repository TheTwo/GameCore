using System;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public abstract unsafe class U2DWidgetMesh : U2DComponent
{
	[SerializeField] private Material m_Material;
	[SerializeField] private Color m_Color = Color.white;
	[SerializeField] private float m_Width = 100;
	[SerializeField] private float m_Height = 100;
	[SerializeField] private Vector2 m_Pivot = new(0.5f, 0.5f);
	[SerializeField] private float m_PixelSize = 1f;

	private bool m_Dirty;

	private bool m_MaterialDirty;

	protected bool Awoke { private set; get; }

	protected abstract void OnGenerateMesh();

	protected abstract void OnUpdateMaterial();

	protected virtual void Awake()
	{
		Awoke = true;
	}

	protected virtual void OnDidApplyAnimationProperties()
	{
		SetDirty();
	}

	public void SetDirty()
	{
		m_Dirty = true;
	}

	public void SetMaterialDirty()
	{
		m_MaterialDirty = true;
	}

	public Material material
	{
		get => m_Material;

		set
		{
			if (m_Material != value)
			{
				m_Material = value;
				SetMaterialDirty();
			}
		}
	}

	public Color color
	{
		get => m_Color;

		set
		{
			if (m_Color != value)
			{
				m_Color = value;
				SetDirty();
			}
		}
	}

	public float width
	{
		get => m_Width;

		set
		{
			if (m_Width != value)
			{
				m_Width = value;
				SetDirty();
			}
		}
	}

	public float height
	{
		get => m_Height;

		set
		{
			if (m_Height != value)
			{
				m_Height = value;
				SetDirty();
			}
		}
	}

	public Vector2 pivot
	{
		get => m_Pivot;

		set
		{
			if (m_Pivot != value)
			{
				m_Pivot = value;
				SetDirty();
			}
		}
	}

	public float pixelSize
	{
		get => m_PixelSize;

		set
		{
			if (m_PixelSize != value)
			{
				m_PixelSize = value;
				SetDirty();
			}
		}
	}

	public Rect rect
	{
		get
		{
			var position = new Vector2(-m_Width * m_Pivot.x, -m_Height * m_Pivot.y);
			var size = new Vector2(m_Width, m_Height);
			position *= m_PixelSize;
			size *= m_PixelSize;
			return new Rect(position, size);
		}
	}
#if UNITY_EDITOR
	private void Update()
	{
		if(!Application.isPlaying)
			UpdateImmediate();
	}
#endif

	public override void DoUpdate()
	{
		UpdateImmediate();
	}

	public override void DoLateUpdate()
	{
		
	}
	
	public void UpdateImmediate()
	{
		if (!Awoke)
		{
			return;
		}
		
		if (m_Dirty)
		{
			OnGenerateMesh();
			m_Dirty = false;
		}

		if (m_MaterialDirty)
		{
			OnUpdateMaterial();
			m_MaterialDirty = false;
		}
	}

#if UNITY_EDITOR
	private void OnDrawGizmos()
	{
		var corners = stackalloc Vector3[4];
		U2DUtils.CalculateRectCorners(rect, corners);
		U2DUtils.TransformCorners(corners, transform.localToWorldMatrix);
		var v0 = corners[0];
		var v1 = corners[1];
		var v2 = corners[2];
		var v3 = corners[3];

		var color = Color.white;
		Debug.DrawLine(v0, v1, color);
		Debug.DrawLine(v1, v2, color);
		Debug.DrawLine(v2, v3, color);
		Debug.DrawLine(v3, v0, color);
	}
#endif

	protected override void OnEnable()
	{
		base.OnEnable();
		SetDirty();
	}
}
