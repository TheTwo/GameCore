using System.Collections.Generic;
using Unity.Collections.LowLevel.Unsafe;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public unsafe class U2DTextMesh : U2DWidgetMesh
{
	public enum Effect
	{
		None,
		Outline,
		Shadow,
	}

	////////////////////////////////////////////////////////////
	[SerializeField] Font m_Font;
	[SerializeField] FontStyle m_FontStyle = FontStyle.Normal;
	[SerializeField] int m_FontSize = 16;
	[SerializeField] float m_FontScale = 1f;
	[SerializeField] float m_LineSpacing = 1;
	[SerializeField] TextAnchor m_Anchor = TextAnchor.MiddleCenter;
	[SerializeField] HorizontalWrapMode m_HorizontalWrapMode = HorizontalWrapMode.Overflow;
	[SerializeField] VerticalWrapMode m_VerticalWrapMode = VerticalWrapMode.Overflow;
	[SerializeField] float m_MaxWidth = 100;
	[SerializeField] float m_MaxHeight = 100;
	[SerializeField] string m_Text = string.Empty;
	[SerializeField] Effect m_Effect = Effect.None;
	[SerializeField] Color m_OutlineColor = Color.black;
	[SerializeField] float m_OutlineSize = 1;
	[SerializeField] Vector2 m_ShadowOffset = new Vector2(1, -1);
	[SerializeField] Color m_ShadowColor = Color.black;
	[SerializeField] bool m_RichText = true;
	[SerializeField] bool m_Gradient = false;
	[SerializeField] public Color m_GradientColor1 = Color.black;
	[SerializeField] public Color m_GradientColor2 = Color.black;
	//是否垂直方向
	[SerializeField] public bool m_IsGradientVertical = true;
	//是否叠加原有颜色
	[SerializeField] public bool m_IsGradientMultiplyTextColor = false;
	////////////////////////////////////////////////////////////

	private static readonly int MainTexId = Shader.PropertyToID("_MainTex");

	private TextGenerator m_TextCache;
	private Mesh m_Mesh;
	private MeshFilter m_MeshFilter;
	private MeshRenderer m_MeshRenderer;
	private MaterialPropertyBlock m_RenderPropBlock;

	protected override void Awake()
	{
		base.Awake();
		
		InitOnce();
		SetDirty();
	}

	private void OnDestroy()
	{
		if (m_Mesh != null)
		{
			if (Application.isPlaying)
			{
				Destroy(m_Mesh);
			}
			else
			{
				DestroyImmediate(m_Mesh);
			}
			m_Mesh = null;
		}
	}

	protected override void OnEnable()
	{
		U2DFontUpdateTracker.TrackText(this);
		base.OnEnable();
	}

	protected override void OnDisable()
	{
		U2DFontUpdateTracker.UntrackText(this);
		base.OnDisable();
	}

	public void FontTextureChanged()
	{
		SetDirty();
	}

	public Effect effect
	{
		get => m_Effect;

		set
		{
			if (m_Effect != value)
			{
				m_Effect = value;
				SetDirty();
			}
		}
	}

	public Color outlineColor
	{
		get => m_OutlineColor;

		set
		{
			if (m_OutlineColor != value)
			{
				m_OutlineColor = value;
				SetDirty();
			}
		}
	}

	public float maxWidth
	{
		get => m_MaxWidth;

		set
		{
			if (m_MaxWidth != value)
			{
				m_MaxWidth = value;
				SetDirty();
			}
		}
	}

	public float maxHeight
	{
		get => m_MaxHeight;

		set
		{
			if (m_MaxHeight != value)
			{
				m_MaxHeight = value;
				SetDirty();
			}
		}
	}

	public float outlineSize
	{
		get => m_OutlineSize;

		set
		{
			if (m_OutlineSize != value)
			{
				m_OutlineSize = value;
				SetDirty();
			}
		}
	}

	public Color shadowColor
	{
		get => m_ShadowColor;

		set
		{
			if (m_ShadowColor != value)
			{
				m_ShadowColor = value;
				SetDirty();
			}
		}
	}

	public Vector2 shadowOffset
	{
		get => m_ShadowOffset;

		set
		{
			if (m_ShadowOffset != value)
			{
				m_ShadowOffset = value;
				SetDirty();
			}
		}
	}

	public bool richText
	{
		get => m_RichText;
		set
		{
			if (m_RichText != value)
			{
				m_RichText = value;
				SetDirty();
			}
		}
	}

	public Font font
	{
		get => m_Font;

		set
		{
			if (m_Font != value)
			{
				U2DFontUpdateTracker.UntrackText(this);
				m_Font = value;
				U2DFontUpdateTracker.TrackText(this);
				SetDirty();
			}
		}
	}

	public FontStyle fontStyle
	{
		set
		{
			if (m_FontStyle != value)
			{
				m_FontStyle = value;
				SetDirty();
			}
		}

		get => m_FontStyle;
	}

	public int fontSize
	{
		set
		{
			if (m_FontSize != value)
			{
				m_FontSize = value;
				SetDirty();
			}
		}

		get => m_FontSize;
	}

	public float lineSpacing
	{
		set
		{
			if (m_LineSpacing != value)
			{
				m_LineSpacing = value;
				SetDirty();
			}
		}

		get => m_LineSpacing;
	}

	public TextAnchor anchor
	{
		set
		{
			if (m_Anchor != value)
			{
				m_Anchor = value;
				SetDirty();
			}
		}

		get => m_Anchor;
	}

	public HorizontalWrapMode horizontalWrapMode
	{
		set
		{
			if (m_HorizontalWrapMode != value)
			{
				m_HorizontalWrapMode = value;
				SetDirty();
			}
		}

		get => m_HorizontalWrapMode;
	}

	public VerticalWrapMode verticalWrapMode
	{
		set
		{
			if (m_VerticalWrapMode != value)
			{
				m_VerticalWrapMode = value;
				SetDirty();
			}
		}

		get => m_VerticalWrapMode;
	}

	public string text
	{
		set
		{
			if (m_Text != value)
			{
				m_Text = value;
				SetDirty();
			}
		}

		get => m_Text;
	}

	public float fontScale
	{
		set
		{
			if (m_FontScale != value)
			{
				m_FontScale = value;
				SetDirty();
			}
		}

		get => m_FontScale;
	}

	public bool UseGradient { 
		get => m_Gradient;
		set
		{
			if (m_Gradient != value)
			{
				m_Gradient = value;
				SetDirty();
			}
		}
	}

	public Color GradientColor1
	{
		get => m_GradientColor1;
		set
		{
			if (m_GradientColor1 != value)
			{
				m_GradientColor1 = value;
				SetDirty();
			}
		}
	}

	public Color GradientColor2
	{
		get => m_GradientColor2;
		set
		{
			if (m_GradientColor2 != value)
			{
				m_GradientColor2 = value;
				SetDirty();
			}
		}
	}

	public bool IsGradientVertical
	{
		get => m_IsGradientVertical;
		set
		{
			if (m_IsGradientVertical != value)
			{
				m_IsGradientVertical = value;
				SetDirty();
			}
		}
	}

	public bool IsGradientMultiplyTextColor
	{
		get => m_IsGradientMultiplyTextColor;
		set
		{
			if (m_IsGradientMultiplyTextColor != value)
			{
				m_IsGradientMultiplyTextColor = value;
				SetDirty();
			}
		}
	}

	private void InitOnce()
	{
		Debug.Assert(Awoke, "Call InitOnce() of U2DTextMesh before Awake() called.", this);

		if (m_MeshFilter == null)
		{
			m_MeshFilter = GetComponentInChildren<MeshFilter>(true);
		}

		if (m_MeshRenderer == null)
		{
			m_MeshRenderer = GetComponentInChildren<MeshRenderer>(true);
		}

		if (m_Mesh == null)
		{
			m_Mesh = new Mesh
			{
				name = "Mesh-" + gameObject.name
			};
			m_Mesh.MarkDynamic();
		}
	}

	protected override void OnGenerateMesh()
	{
		InitOnce();
		
		if (!m_Font || string.IsNullOrEmpty(m_Text))
		{
			m_Mesh.Clear();
			m_MeshFilter.mesh = m_Mesh;
			return;
		}

		var textCache = CachedTextGen;
		textCache.Invalidate();

		var settings = GetGenerationSettings();
		var extents = new Vector2(width, height);

		if (m_HorizontalWrapMode == HorizontalWrapMode.Overflow)
		{
			extents.x = 1;
			settings.generationExtents = extents;
			var testWidth = textCache.GetPreferredWidth(m_Text, settings);
			if (testWidth > maxWidth)
			{
				extents.x = maxWidth;
				settings.generationExtents = extents;
				settings.updateBounds = true;
				settings.horizontalOverflow = HorizontalWrapMode.Wrap;
			}
		}

		if (m_VerticalWrapMode == VerticalWrapMode.Overflow)
		{
			extents.y = 1;
			settings.generationExtents = extents;
			var testHeight = textCache.GetPreferredHeight(m_Text, settings);
			if (testHeight > maxHeight)
			{
				extents.y = maxHeight;
				settings.generationExtents = extents;
				settings.updateBounds = true;
				settings.verticalOverflow = VerticalWrapMode.Truncate;
			}
		}

		textCache.Populate(m_Text, settings);

		if (m_HorizontalWrapMode == HorizontalWrapMode.Overflow)
		{
			width = textCache.rectExtents.width;
		}

		if (m_VerticalWrapMode == VerticalWrapMode.Overflow)
		{
			height = textCache.rectExtents.height;
		}

		// Apply the offset to the vertices
		var uiVertices = textCache.verts;
		var unitsPerPixel = pixelSize;

		var vertCount = uiVertices.Count == 0 ? 0 : uiVertices.Count;
		var vertBufferSize = CalculateVertBufferSize(vertCount);

		var meshDataArray = Mesh.AllocateWritableMeshData(1);
		var meshData = meshDataArray[0];

		meshData.SetVertexBufferParams(vertBufferSize, U2DVertexData.VertexAttributeDescriptors);
		meshData.SetIndexBufferParams(vertBufferSize / 4 * 6, IndexFormat.UInt16);

		var vertices = (U2DVertexData*)meshData.GetVertexData<U2DVertexData>().GetUnsafePtr();
		var indices = (ushort*)meshData.GetIndexData<ushort>().GetUnsafePtr();

		var offsetForPivot = new Vector3(width * (0.5f - pivot.x), height * (0.5f - pivot.y));

		// Begin fill vertices
		var quadIndex = 0;

		//
		if (m_Effect == Effect.Outline)
		{
			var tint = QualitySettings.activeColorSpace == ColorSpace.Linear ? m_OutlineColor.linear : m_OutlineColor;
			ApplyOutline(uiVertices, vertices, indices, vertCount, offsetForPivot, tint, ref quadIndex);
		}
		else if (m_Effect == Effect.Shadow)
		{
			var tint = QualitySettings.activeColorSpace == ColorSpace.Linear ? m_ShadowColor.linear : m_ShadowColor;
			var offset = offsetForPivot + new Vector3(m_ShadowOffset.x, m_ShadowOffset.y);
			ApplyShadow(uiVertices, vertices, indices, vertCount, offset, tint, ref quadIndex);
		}

		var quad = stackalloc UIVertex[4];

		var gradientColor1 = QualitySettings.activeColorSpace == ColorSpace.Linear ? m_GradientColor1.linear : m_GradientColor1;
		var gradientColor2 = QualitySettings.activeColorSpace == ColorSpace.Linear ? m_GradientColor2.linear : m_GradientColor2;

		for (var i = 0; i < vertCount; ++i)
		{
			var idx = i & 3;
			quad[idx] = uiVertices[i];
			quad[idx].position += offsetForPivot;
			quad[idx].position *= unitsPerPixel;
			quad[idx].uv1 = Vector4.zero;
			quad[idx].uv2 = Vector4.zero;

			if (idx == 3)
			{
				if (m_Gradient)
				{
					if (m_IsGradientVertical)
					{
						quad[0].color = m_IsGradientMultiplyTextColor ? quad[0].color * gradientColor1 : gradientColor1;
						quad[1].color = m_IsGradientMultiplyTextColor ? quad[1].color * gradientColor1 : gradientColor1;
						quad[2].color = m_IsGradientMultiplyTextColor ? quad[2].color * gradientColor2 : gradientColor2;
						quad[3].color = m_IsGradientMultiplyTextColor ? quad[3].color * gradientColor2 : gradientColor2;
					}
					else
					{
						quad[0].color = m_IsGradientMultiplyTextColor ? quad[0].color * gradientColor1 : gradientColor1;
						quad[1].color = m_IsGradientMultiplyTextColor ? quad[1].color * gradientColor2 : gradientColor2;
						quad[2].color = m_IsGradientMultiplyTextColor ? quad[2].color * gradientColor2 : gradientColor2;
						quad[3].color = m_IsGradientMultiplyTextColor ? quad[3].color * gradientColor1 : gradientColor1;
					}
				}
				AddUIVertexQuad(vertices, indices, quad, ref quadIndex);
			}
		}

		GenerateMesh(meshDataArray);
		m_Mesh.UploadMeshData(false);
	}

	protected override void OnUpdateMaterial()
	{
		m_MeshRenderer.material = material ? material : m_Font.material;
		
		m_RenderPropBlock ??= new MaterialPropertyBlock();
		m_MeshRenderer.GetPropertyBlock(m_RenderPropBlock);
		m_RenderPropBlock.SetTexture(MainTexId, m_Font.material.mainTexture);
		m_MeshRenderer.SetPropertyBlock(m_RenderPropBlock);
	}

	private int CalculateVertBufferSize(int vertCount)
	{
		switch (m_Effect)
		{
			case Effect.Outline:
			case Effect.Shadow:
				return vertCount * 2;
		}

		return vertCount;
	}

	private void ApplyOutline(IList<UIVertex> uiVertices, U2DVertexData* vertices, ushort* indices, int vertCount,
		Vector3 offset, Color tint, ref int quadIndex)
	{
		var vTop = SystemInfo.graphicsUVStartsAtTop ? -1f : 1f;
		var texture = GetTexture();
		var du = 1f / texture.width;
		var dv = vTop / texture.height;
		
		var unitsPerPixel = pixelSize;
		var quad = stackalloc UIVertex[4];
		var quadCount = vertCount / 4;
		for (var i = 0; i < quadCount; i++)
		{
			/*
			 
			 0----1
			 |    |
			 3----2			 
			 
			 */
			quad[0] = uiVertices[i * 4 + 0];
			quad[1] = uiVertices[i * 4 + 1];
			quad[2] = uiVertices[i * 4 + 2];
			quad[3] = uiVertices[i * 4 + 3];

			var uvRect = CalculateRect(quad, 4);
			var uvCenter = new Vector2(0.5f * (uvRect.x + uvRect.z), 0.5f * (uvRect.y + uvRect.w));
			
			quad[0].position += new Vector3(-m_OutlineSize, m_OutlineSize);
			quad[0].uv0 = CalculateOutlineUV(quad[0].uv0, uvCenter, du, dv, vTop, m_OutlineSize);
			quad[0].uv1 = new Vector4((int)m_Effect, m_OutlineSize);
			quad[0].uv2 = uvRect;

			quad[1].position += new Vector3(m_OutlineSize, m_OutlineSize);
			quad[1].uv0 = CalculateOutlineUV(quad[1].uv0, uvCenter, du, dv, vTop, m_OutlineSize);
			quad[1].uv1 = new Vector4((int)m_Effect, m_OutlineSize);
			quad[1].uv2 = uvRect;

			quad[2].position += new Vector3(m_OutlineSize, -m_OutlineSize);
			quad[2].uv0 = CalculateOutlineUV(quad[2].uv0, uvCenter, du, dv, vTop, m_OutlineSize);
			quad[2].uv1 = new Vector4((int)m_Effect, m_OutlineSize);
			quad[2].uv2 = uvRect;

			quad[3].position += new Vector3(-m_OutlineSize, -m_OutlineSize);
			quad[3].uv0 = CalculateOutlineUV(quad[3].uv0, uvCenter, du, dv, vTop, m_OutlineSize);
			quad[3].uv1 = new Vector4((int)m_Effect, m_OutlineSize);
			quad[3].uv2 = uvRect;

			for (var j = 0; j < 4; j++)
			{
				quad[j].position += offset;
				quad[j].position *= unitsPerPixel;

				var vertColor = tint;
				vertColor.a = tint.a * quad[j].color.a / 255f;
				quad[j].color = vertColor;
			}

			AddUIVertexQuad(vertices, indices, quad, ref quadIndex);
		}
	}

	public static Vector2 CalculateOutlineUV(Vector2 uv, Vector2 center, float du, float dv, float vTop, float outlineSize)
	{
		//Unity在生成Font贴图的时候，会将某些字符旋转90度，来节省贴图空间，因此需要通过计算UV到UV框中心的偏移来确定UV的变化量
		var offset = uv - center;
		var uSign = Mathf.Sign(offset.x);
		var vSign = Mathf.Sign(offset.y);
		var delta = new Vector2(uSign * du * outlineSize, vTop * vSign * dv * outlineSize);
		return uv + delta;
	}

	public static Vector4 CalculateRect(UIVertex* quad, int count)
	{
		var rect = new Vector4(float.MaxValue, float.MaxValue, float.MinValue, float.MinValue);
		for (var i = 0; i < count; i++)
		{
			var uv = quad[i].uv0;
			if (uv.x < rect.x)
			{
				rect.x = uv.x;
			}

			if (uv.y < rect.y)
			{
				rect.y = uv.y;
			}
			
			if (uv.x > rect.z)
			{
				rect.z = uv.x;
			}

			if (uv.y > rect.w)
			{
				rect.w = uv.y;
			}
		}

		return rect;
	}

	private void ApplyShadow(IList<UIVertex> uiVertices, U2DVertexData* vertices, ushort* indices, int vertCount,
		Vector3 offset, Color tint, ref int quadIndex)
	{
		var unitsPerPixel = pixelSize;
		var quad = stackalloc UIVertex[4];
		for (var i = 0; i < vertCount; ++i)
		{
			var idx = i & 3;
			quad[idx] = uiVertices[i];
			quad[idx].position += offset;
			quad[idx].position *= unitsPerPixel;

			var vertColor = tint;
			vertColor.a = tint.a * quad[idx].color.a / 255f;
			quad[idx].color = vertColor;

			if (idx == 3)
			{
				AddUIVertexQuad(vertices, indices, quad, ref quadIndex);
			}
		}
	}

	private static void AddUIVertexQuad(U2DVertexData* vertices, ushort* indices, UIVertex* quad, ref int quadIndex)
	{
		var startVertIndex = quadIndex * 4;
		for (var i = 0; i < 4; ++i)
		{
			var uiVert = quad[i];
			var vertIdx = startVertIndex + i;

			ref var vertex = ref vertices[vertIdx];
			vertex.Position = uiVert.position;
			vertex.Color = uiVert.color;
			vertex.TexCoord0 = uiVert.uv0;
			vertex.TexCoord1 = uiVert.uv1;
			vertex.TexCoord2 = uiVert.uv2;
		}

		var startTriangleIndex = quadIndex * 6;
		var v0 = startVertIndex + 0;
		var v1 = startVertIndex + 1;
		var v2 = startVertIndex + 2;
		var v3 = startVertIndex + 3;

		indices[startTriangleIndex + 0] = (ushort)v0;
		indices[startTriangleIndex + 1] = (ushort)v1;
		indices[startTriangleIndex + 2] = (ushort)v2;
		indices[startTriangleIndex + 3] = (ushort)v0;
		indices[startTriangleIndex + 4] = (ushort)v2;
		indices[startTriangleIndex + 5] = (ushort)v3;

		++quadIndex;
	}

	private void GenerateMesh(Mesh.MeshDataArray meshDataArray)
	{
		m_Mesh.Clear();

		var meshData = meshDataArray[0];
		var indices = meshData.GetIndexData<ushort>();
		meshData.subMeshCount = 1;
		meshData.SetSubMesh(0, new SubMeshDescriptor(0, indices.Length));

		Mesh.ApplyAndDisposeWritableMeshData(meshDataArray, m_Mesh);
		m_Mesh.RecalculateBounds();

		m_MeshFilter.mesh = m_Mesh;
		OnUpdateMaterial();
	}

	private TextGenerator CachedTextGen =>
		m_TextCache ??= m_Text.Length != 0 ? new TextGenerator(m_Text.Length) : new TextGenerator();

	private TextGenerationSettings GetGenerationSettings()
	{
		var settings = new TextGenerationSettings();
		if (font != null && font.dynamic)
		{
			settings.fontSize = m_FontSize; // 字体像素大小
		}

		var isLinear = QualitySettings.activeColorSpace == ColorSpace.Linear;

		settings.textAnchor = m_Anchor;
		settings.scaleFactor = m_FontScale;
		settings.color = isLinear ? color.linear : color;
		settings.font = font;
		settings.pivot = new Vector2(0.5f, 0.5f);
		settings.richText = m_RichText;
		settings.lineSpacing = m_LineSpacing;
		settings.fontStyle = m_FontStyle;
		settings.resizeTextForBestFit = false;
		settings.updateBounds = m_HorizontalWrapMode == HorizontalWrapMode.Overflow ||
		                        m_VerticalWrapMode == VerticalWrapMode.Overflow;
		settings.horizontalOverflow = m_HorizontalWrapMode;
		settings.verticalOverflow = m_VerticalWrapMode;
		return settings;
	}

	public Texture GetTexture()
	{
		if (m_Font)
		{
			return m_Font.material.mainTexture;
		}
		
		return null; 
	}
}
