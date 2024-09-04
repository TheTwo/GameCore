using Unity.Collections.LowLevel.Unsafe;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public unsafe class U2DSpriteMesh : U2DWidgetMesh
{
	public enum FillType
	{
		Simple,
		Sliced,
		Radial,
	}

	public enum AspectRatioSource
	{
		Free,
		BasedOnWidth,
		BasedOnHeight,
	}

	public enum MaskType
	{
		None,
		Rect,
		Circle,
	}

	private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
	private static readonly int AlphaTexId = Shader.PropertyToID("_AlphaTex");
	private static readonly int EnableExternalAlphaId = Shader.PropertyToID("_EnableExternalAlpha");
	private static readonly int GreyModeId = Shader.PropertyToID("_GreyMode");

	private const int SlicedVertexCount = 16;
	private const int SlicedIndexCount = 54;
	private const int SimpleVertexCount = 4;
	private const int SimpleIndexCount = 6;
	private const int RadialVertexCount = 10;
	private const int RadialFaceCount = 8;
	private const int RadialIndexCount = 24;

	////////////////////////////////////////////////////////////
	[SerializeField] private Sprite m_Sprite; // sprite needs to be full rect
	[SerializeField] private FillType m_FillType = FillType.Simple;
	[SerializeField] private AspectRatioSource m_AspectRatioSource;
	[SerializeField] private float m_FillAmount = 1;
	[SerializeField] private bool m_Degenerate = true;
	[SerializeField] private MaskType m_MaskType = MaskType.None;
	[SerializeField] private Vector2 m_MaskParam1 = Vector2.zero;
	[SerializeField] private Vector2 m_MaskParam2 = Vector2.zero;
	[SerializeField] private bool m_Clockwise;
	////////////////////////////////////////////////////////////

	private Mesh m_Mesh;
	private MeshFilter m_MeshFilter;
	private MeshRenderer m_MeshRenderer;
	private MaterialPropertyBlock m_RenderPropBlock;
	private bool m_IsGrey;

	private Vector2 OffsetForPivot => new(width * pivot.x, height * pivot.y);

	public bool IsGreyMode
	{
		get => m_IsGrey;
		set
		{
			if (m_IsGrey == value)
			{
				return;
			}

			m_IsGrey = value;
			if (null == m_RenderPropBlock || !m_MeshRenderer)
			{
				return;
			}

			m_MeshRenderer.GetPropertyBlock(m_RenderPropBlock);
			m_RenderPropBlock.SetFloat(GreyModeId, m_IsGrey ? 1f : 0f);
			m_MeshRenderer.SetPropertyBlock(m_RenderPropBlock);
		}
	}

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

	private void InitOnce()
	{
		Debug.Assert(Awoke, "Call InitOnce() of U2DSpriteMesh before Awake() called.", this);

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

	public bool degenerate
	{
		get => m_Degenerate;

		set
		{
			if (m_Degenerate != value)
			{
				m_Degenerate = value;
				SetDirty();
			}
		}
	}

	public FillType fillType
	{
		get => m_FillType;

		set
		{
			if (m_FillType != value)
			{
				m_FillType = value;
				SetDirty();
			}
		}
	}

	public float fillAmount
	{
		get => m_FillAmount;

		set
		{
			if (m_FillAmount != value)
			{
				m_FillAmount = Mathf.Clamp01(value);
				SetDirty();
			}
		}
	}

	public Sprite sprite
	{
		get => m_Sprite;

		set
		{
			if (m_Sprite != value)
			{
				m_Sprite = value;
				SetDirty();
			}
		}
	}

	public Texture GetTexture()
	{
		if (m_Sprite != null)
		{
			return m_Sprite.texture;
		}

		return null;
	}

	public Rect GetSpriteRect()
	{
		return m_Sprite != null ? m_Sprite.rect : new Rect();
	}

	public Vector4 GetBorder()
	{
		return m_Sprite != null ? m_Sprite.border : Vector4.zero;
	}

	public Rect GetTextureRect()
	{
		return m_Sprite != null ? m_Sprite.textureRect : new Rect();
	}

	public MaskType maskType
	{
		get => m_MaskType;

		set
		{
			if (m_MaskType != value)
			{
				m_MaskType = value;
				SetDirty();
			}
		}
	}

	public Vector2 maskParam1
	{
		get => m_MaskParam1;

		set
		{
			if (m_MaskParam1 != value)
			{
				m_MaskParam1 = value;
				SetDirty();
			}
		}
	}

	public Vector2 maskParam2
	{
		get => m_MaskParam2;

		set
		{
			if (m_MaskParam2 != value)
			{
				m_MaskParam2 = value;
				SetDirty();
			}
		}
	}

	public bool clockwise
	{
		get => m_Clockwise;

		set
		{
			if (m_Clockwise != value)
			{
				m_Clockwise = value;
				SetDirty();
			}
		}
	}

	protected override void OnGenerateMesh()
	{
		InitOnce();

		if (m_Sprite == null)
		{
			m_Mesh.Clear();
			return;
		}

		var texture = GetTexture();
		if (texture == null)
		{
			return;
		}

		var outerUV = GetTextureRect();
		var innerUV = outerUV;

		var border = GetBorder();
		innerUV.xMin += border.x;
		innerUV.yMin += border.y;
		innerUV.xMax -= border.z;
		innerUV.yMax -= border.w;

		var w = 1f / texture.width;
		var h = 1f / texture.height;

		outerUV.xMin *= w;
		outerUV.xMax *= w;
		outerUV.yMin *= h;
		outerUV.yMax *= h;

		innerUV.xMin *= w;
		innerUV.xMax *= w;
		innerUV.yMin *= h;
		innerUV.yMax *= h;

		if (m_FillType == FillType.Simple)
		{
			SimpleFill(outerUV);
		}
		else if (m_FillType == FillType.Sliced)
		{
			SlicedFill(outerUV, innerUV);
		}
		else if (m_FillType == FillType.Radial)
		{
			RadialFill(outerUV);
		}

		m_Mesh.UploadMeshData(false);
	}

	protected override void OnUpdateMaterial()
	{
		m_MeshRenderer.material = material;

		if (m_Sprite != null)
		{
			m_RenderPropBlock ??= new MaterialPropertyBlock();
			m_MeshRenderer.GetPropertyBlock(m_RenderPropBlock);
			m_RenderPropBlock.SetTexture(MainTexId, m_Sprite.texture);
			m_RenderPropBlock.SetFloat(GreyModeId, m_IsGrey ? 1f : 0f);
			if (m_Sprite.associatedAlphaSplitTexture != null)
			{
				m_RenderPropBlock.SetTexture(AlphaTexId, m_Sprite.associatedAlphaSplitTexture);
				m_RenderPropBlock.SetFloat(EnableExternalAlphaId, 1f);
			}
			else
			{
				m_RenderPropBlock.SetFloat(EnableExternalAlphaId, 0f);
			}

			m_MeshRenderer.SetPropertyBlock(m_RenderPropBlock);
		}
	}

	public AspectRatioSource aspectRatio
	{
		get => m_AspectRatioSource;

		set
		{
			if (m_AspectRatioSource != value)
			{
				m_AspectRatioSource = value;
				SetDirty();
			}
		}
	}
	
	/*

	2--------1(9)-----8
	|        |        |
	|        |        | 
	|        |        |
	3--------0--------7
	|        |        |
	|        |        |
	|        |        |
	4--------5--------6

	*/

	private void RadialFill(Rect outerUV)
	{
		var meshDataArray = Mesh.AllocateWritableMeshData(1);
		var meshData = meshDataArray[0];

		meshData.SetVertexBufferParams(RadialVertexCount, U2DVertexData.VertexAttributeDescriptors);
		meshData.SetIndexBufferParams(RadialIndexCount, IndexFormat.UInt16);

		AdjustSize();
		
		var halfSizeX = 0.5f * width;
		var halfSizeY = 0.5f * height;

		var vertices = (U2DVertexData*)meshData.GetVertexData<U2DVertexData>().GetUnsafePtr();

		vertices[2].Position.Set(-halfSizeX, halfSizeY, 0f);
		vertices[4].Position.Set(-halfSizeX, -halfSizeY, 0f);
		vertices[6].Position.Set(halfSizeX, -halfSizeY, 0f);
		vertices[8].Position.Set(halfSizeX, halfSizeY, 0f);

		vertices[1].Position = 0.5f * (vertices[2].Position + vertices[8].Position);
		vertices[3].Position = 0.5f * (vertices[2].Position + vertices[4].Position);
		vertices[5].Position = 0.5f * (vertices[4].Position + vertices[6].Position);
		vertices[7].Position = 0.5f * (vertices[6].Position + vertices[8].Position);
		
		vertices[0].Position = 0.5f * (vertices[2].Position + vertices[6].Position);
		vertices[9].Position = vertices[1].Position;

		var vertColor = QualitySettings.activeColorSpace == ColorSpace.Linear ? color.linear : color;
		for (var i = 0; i < RadialVertexCount; i++)
		{
			vertices[i].Color = vertColor;
		}

		vertices[2].TexCoord0.Set(outerUV.xMin, outerUV.yMax);
		vertices[4].TexCoord0.Set(outerUV.xMin, outerUV.yMin);
		vertices[6].TexCoord0.Set(outerUV.xMax, outerUV.yMin);
		vertices[8].TexCoord0.Set(outerUV.xMax, outerUV.yMax);	

		vertices[1].TexCoord0 = 0.5f * (vertices[2].TexCoord0 + vertices[8].TexCoord0);
		vertices[3].TexCoord0 = 0.5f * (vertices[2].TexCoord0 + vertices[4].TexCoord0);
		vertices[5].TexCoord0 = 0.5f * (vertices[4].TexCoord0 + vertices[6].TexCoord0);
		vertices[7].TexCoord0 = 0.5f * (vertices[6].TexCoord0 + vertices[8].TexCoord0);
		
		vertices[0].TexCoord0 = 0.5f * (vertices[2].TexCoord0 + vertices[6].TexCoord0);
		vertices[9].TexCoord0 = vertices[1].TexCoord0;

		var arc = m_FillAmount * 360;
		if (arc <= 0)
		{
			for (var i = 1; i < RadialVertexCount; i++)
			{
				vertices[i] = vertices[0];
			}
		}
		else if(arc < 360)
		{
			//从Y轴正方向开始逆时针转动
			const float startArc = 90;
			
			//当前弧度对应的点
			arc += startArc;
			var pi = arc * Mathf.Deg2Rad;
			var spriteRect = Rect.MinMaxRect(-halfSizeX, -halfSizeY, halfSizeX, halfSizeY);
			var origin = vertices[0].Position;
			var sign = m_Clockwise ? -1 : 1;
			var direction = new Vector3(sign * Mathf.Cos(pi), Mathf.Sin(pi));
			var ray = new Ray(origin, direction);
			U2DUtils.LineRectIntersection(ray, spriteRect, out var curArcPoint);

			var dis = curArcPoint - vertices[4].Position;
			var uv = new Vector2(Mathf.Lerp(outerUV.xMin, outerUV.xMax, dis.x / width),
				Mathf.Lerp(outerUV.yMin, outerUV.yMax, dis.y / height));
		
			var delta = stackalloc float[2];
			delta[0] = Mathf.Rad2Deg * Mathf.Atan2(height, width);
			delta[1] = 90 - delta[0];
			var degree = startArc;
			var index = 0;
			var stop = false;

			for (var i = 1; i < RadialVertexCount; i++)
			{
				if (stop)
				{
					var vertIdx = m_Clockwise ? 10 - i : i;
					vertices[vertIdx] = vertices[0];
				}
				else
				{
					index = 1 - index;
					degree += delta[index];
					stop = arc < degree;
					if (stop)
					{
						++i;
						var vertIdx = m_Clockwise ? 10 - i : i;
						vertices[vertIdx].Position = curArcPoint;
						vertices[vertIdx].TexCoord0 = uv;
					}
				}
			}
		}

		var offsetForPivot = new Vector3(width * (0.5f - pivot.x), height * (0.5f - pivot.y));
		var vertPixelSize = pixelSize;

		var calcMaskParam = CalcMaskParam(outerUV);
		for (var i = 0; i < RadialVertexCount; ++i)
		{
			vertices[i].Position = (vertices[i].Position + offsetForPivot) * vertPixelSize;
			vertices[i].TexCoord1 = new Vector2((int)m_MaskType, 0);
			vertices[i].TexCoord2 = calcMaskParam;
		}

		var indices = (ushort*)meshData.GetIndexData<ushort>().GetUnsafePtr();

		for (var i = 0; i < RadialFaceCount; i++)
		{
			indices[i * 3 + 0] = 0;
			indices[i * 3 + 1] = (ushort)(i + 2);
			indices[i * 3 + 2] = (ushort)(i + 1);
		}
		
		GenerateMesh(meshDataArray);
	}

	/*

		0--------1--------2--------3
		|        |        |        |
		|        |        |        |
		|        |        |        |
		4--------5--------6--------7
		|        |        |        |
		|        |        |        |
		|        |        |        |
		8--------9--------A--------B
		|        |        |        |
		|        |        |        |
		|        |        |        |
		C--------D--------E--------F

	 */

	private void SlicedFill(Rect outerUV, Rect innerUV)
	{
		var border = GetBorder();

		var meshDataArray = Mesh.AllocateWritableMeshData(1);
		var meshData = meshDataArray[0];

		meshData.SetVertexBufferParams(SlicedVertexCount, U2DVertexData.VertexAttributeDescriptors);
		meshData.SetIndexBufferParams(SlicedIndexCount, IndexFormat.UInt16);

		var vertices = (U2DVertexData*)meshData.GetVertexData<U2DVertexData>().GetUnsafePtr();
		var indices = (ushort*)meshData.GetIndexData<ushort>().GetUnsafePtr();

		AdjustSize();
		var offsetForPivot = OffsetForPivot;

		var xMin = -offsetForPivot.x;
		var xMax = xMin + width;
		var yMin = -offsetForPivot.y;
		var yMax = yMin + height;

		if (m_Degenerate)
		{
			// 进度条等控件如果是使用缩放Sprite尺寸实现的，在进度很小的时候需要退化成Simple
			if (xMin + border.x > xMax - border.z)
			{
				border.x = border.z = 0;
				innerUV.xMin = outerUV.xMin;
				innerUV.xMax = outerUV.xMax;
			}

			if (yMin + border.y > yMax - border.w)
			{
				border.y = border.w = 0;
				innerUV.yMin = outerUV.yMin;
				innerUV.yMax = outerUV.yMax;
			}
		}

		vertices[0x0].Position.Set(xMin, yMax, 0f);
		vertices[0x1].Position.Set(xMin + border.x, yMax, 0f);
		vertices[0x2].Position.Set(xMax - border.z, yMax, 0f);
		vertices[0x3].Position.Set(xMax, yMax, 0f);
		vertices[0x4].Position.Set(xMin, yMax - border.w, 0f);
		vertices[0x5].Position.Set(xMin + border.x, yMax - border.w, 0f);
		vertices[0x6].Position.Set(xMax - border.z, yMax - border.w, 0f);
		vertices[0x7].Position.Set(xMax, yMax - border.w, 0f);
		vertices[0x8].Position.Set(xMin, yMin + border.y, 0f);
		vertices[0x9].Position.Set(xMin + border.x, yMin + border.y, 0f);
		vertices[0xA].Position.Set(xMax - border.z, yMin + border.y, 0f);
		vertices[0xB].Position.Set(xMax, yMin + border.y, 0f);
		vertices[0xC].Position.Set(xMin, yMin, 0f);
		vertices[0xD].Position.Set(xMin + border.x, yMin, 0f);
		vertices[0xE].Position.Set(xMax - border.z, yMin, 0f);
		vertices[0xF].Position.Set(xMax, yMin, 0f);

		var vertPixelSize = pixelSize;
		var vertColor = QualitySettings.activeColorSpace == ColorSpace.Linear ? color.linear : color;
		var calcMaskParam = CalcMaskParam(outerUV);
		for (var i = 0; i < SlicedVertexCount; ++i)
		{
			vertices[i].Position = vertPixelSize * vertices[i].Position;
			vertices[i].Color = vertColor;
			vertices[i].TexCoord1 = new Vector2((int)m_MaskType, 0);
			vertices[i].TexCoord2 = calcMaskParam;
		}

		vertices[0x0].TexCoord0.Set(outerUV.xMin, outerUV.yMax);
		vertices[0x1].TexCoord0.Set(innerUV.xMin, outerUV.yMax);
		vertices[0x2].TexCoord0.Set(innerUV.xMax, outerUV.yMax);
		vertices[0x3].TexCoord0.Set(outerUV.xMax, outerUV.yMax);
		vertices[0x4].TexCoord0.Set(outerUV.xMin, innerUV.yMax);
		vertices[0x5].TexCoord0.Set(innerUV.xMin, innerUV.yMax);
		vertices[0x6].TexCoord0.Set(innerUV.xMax, innerUV.yMax);
		vertices[0x7].TexCoord0.Set(outerUV.xMax, innerUV.yMax);
		vertices[0x8].TexCoord0.Set(outerUV.xMin, innerUV.yMin);
		vertices[0x9].TexCoord0.Set(innerUV.xMin, innerUV.yMin);
		vertices[0xA].TexCoord0.Set(innerUV.xMax, innerUV.yMin);
		vertices[0xB].TexCoord0.Set(outerUV.xMax, innerUV.yMin);
		vertices[0xC].TexCoord0.Set(outerUV.xMin, outerUV.yMin);
		vertices[0xD].TexCoord0.Set(innerUV.xMin, outerUV.yMin);
		vertices[0xE].TexCoord0.Set(innerUV.xMax, outerUV.yMin);
		vertices[0xF].TexCoord0.Set(outerUV.xMax, outerUV.yMin);

		indices[0] = 4;
		indices[1] = 0;
		indices[2] = 1;
		indices[3] = 4;
		indices[4] = 1;
		indices[5] = 5;

		indices[6] = 5;
		indices[7] = 1;
		indices[8] = 2;
		indices[9] = 5;
		indices[10] = 2;
		indices[11] = 6;

		indices[12] = 6;
		indices[13] = 2;
		indices[14] = 3;
		indices[15] = 6;
		indices[16] = 3;
		indices[17] = 7;

		indices[18] = 8;
		indices[19] = 4;
		indices[20] = 5;
		indices[21] = 8;
		indices[22] = 5;
		indices[23] = 9;

		indices[24] = 9;
		indices[25] = 5;
		indices[26] = 6;
		indices[27] = 9;
		indices[28] = 6;
		indices[29] = 0xA;

		indices[30] = 0xA;
		indices[31] = 6;
		indices[32] = 7;
		indices[33] = 0xA;
		indices[34] = 7;
		indices[35] = 0xB;

		indices[36] = 0xC;
		indices[37] = 8;
		indices[38] = 9;
		indices[39] = 0xC;
		indices[40] = 9;
		indices[41] = 0xD;

		indices[42] = 0xD;
		indices[43] = 9;
		indices[44] = 0xA;
		indices[45] = 0xD;
		indices[46] = 0xA;
		indices[47] = 0xE;

		indices[48] = 0xE;
		indices[49] = 0xA;
		indices[50] = 0xB;
		indices[51] = 0xE;
		indices[52] = 0xB;
		indices[53] = 0xF;

		GenerateMesh(meshDataArray);
	}

	/*

		1--------2
		|        |
		|        |
		|        |
		0--------3

	 */
	private void SimpleFill(Rect outerUV)
	{
		var meshDataArray = Mesh.AllocateWritableMeshData(1);
		var meshData = meshDataArray[0];

		meshData.SetVertexBufferParams(SimpleVertexCount, U2DVertexData.VertexAttributeDescriptors);
		meshData.SetIndexBufferParams(SimpleIndexCount, IndexFormat.UInt16);

		var vertices = (U2DVertexData*)meshData.GetVertexData<U2DVertexData>().GetUnsafePtr();
		var indices = (ushort*)meshData.GetIndexData<ushort>().GetUnsafePtr();

		AdjustSize();
		var offsetForPivot = OffsetForPivot;

		var xMin = -offsetForPivot.x;
		var xMax = xMin + width * m_FillAmount;
		var yMin = -offsetForPivot.y;
		var yMax = yMin + height;

		vertices[0].Position.Set(xMin, yMin, 0f);
		vertices[1].Position.Set(xMin, yMax, 0f);
		vertices[2].Position.Set(xMax, yMax, 0f);
		vertices[3].Position.Set(xMax, yMin, 0f);

		var vertPixelSize = pixelSize;
		var vertColor = QualitySettings.activeColorSpace == ColorSpace.Linear ? color.linear : color;
		var calcMaskParam = CalcMaskParam(outerUV);
		for (var i = 0; i < SimpleVertexCount; ++i)
		{
			vertices[i].Position = vertPixelSize * vertices[i].Position;
			vertices[i].Color = vertColor;
			vertices[i].TexCoord1 = new Vector2((int)m_MaskType, 0);
			vertices[i].TexCoord2 = calcMaskParam;
		}

		var length = outerUV.xMin + (outerUV.xMax - outerUV.xMin) * m_FillAmount;
		vertices[0].TexCoord0.Set(outerUV.xMin, outerUV.yMin);
		vertices[1].TexCoord0.Set(outerUV.xMin, outerUV.yMax);
		vertices[2].TexCoord0.Set(length, outerUV.yMax);
		vertices[3].TexCoord0.Set(length, outerUV.yMin);

		indices[0] = 0;
		indices[1] = 1;
		indices[2] = 2;
		indices[3] = 0;
		indices[4] = 2;
		indices[5] = 3;

		GenerateMesh(meshDataArray);
	}

	private void AdjustSize()
	{
		if (m_Sprite == null)
		{
			return;
		}

		var spriteRect = GetSpriteRect();
		var spriteSize = new Vector2(spriteRect.width, spriteRect.height);
		if (spriteSize is { x: > 0, y: > 0 })
		{
			var spriteRatio = spriteSize.x / spriteSize.y;

			switch (m_AspectRatioSource)
			{
				case AspectRatioSource.BasedOnWidth:
					height = width / spriteRatio;
					break;

				case AspectRatioSource.BasedOnHeight:
					width = height * spriteRatio;
					break;
			}
		}
	}

	private void GenerateMesh(Mesh.MeshDataArray meshDataArray)
	{
		var meshData = meshDataArray[0];
		var indices = meshData.GetIndexData<ushort>();
		meshData.subMeshCount = 1;
		meshData.SetSubMesh(0, new SubMeshDescriptor(0, indices.Length));

		Mesh.ApplyAndDisposeWritableMeshData(meshDataArray, m_Mesh);
		m_Mesh.RecalculateBounds();

		m_MeshFilter.mesh = m_Mesh;
		OnUpdateMaterial();
	}

	private Vector4 CalcMaskParam(Rect uvRect)
	{
		var calcMaskParam = Vector4.zero;
		switch (m_MaskType)
		{
			case MaskType.Rect:
			{
				calcMaskParam = CalcRectMask(uvRect);
				break;
			}

			case MaskType.Circle:
			{
				calcMaskParam = CalcCircleMask(uvRect);
				break;
			}
		}

		return calcMaskParam;
	}

	private Vector4 CalcRectMask(Rect uvRect)
	{
		//m_MaskParam1 is MinXY
		//m_MaskParam2 is MaxXY
		var uvXSize = uvRect.width;
		var uvYSize = uvRect.height;
		var min = uvRect.min;
		return new Vector4
		{
			x = min.x + Mathf.Clamp01(m_MaskParam1.x / width) * uvXSize,
			y = min.y + Mathf.Clamp01(m_MaskParam1.y / height) * uvYSize,
			z = min.x + Mathf.Clamp01(m_MaskParam2.x / width) * uvXSize,
			w = min.y + Mathf.Clamp01(m_MaskParam2.y / height) * uvYSize
		};
	}

	private Vector4 CalcCircleMask(Rect uvRect)
	{
		//m_MaskParam1 is Center 
		//m_MaskParam2.x is Radius
		var texture = GetTexture();
		var uvXSize = uvRect.width;
		var uvYSize = uvRect.height;
		var min = uvRect.min;
		var centerX = min.x + Mathf.Clamp01(m_MaskParam1.x / width + 0.5f) * uvXSize;
		var centerY = min.y + Mathf.Clamp01(m_MaskParam1.y / height + 0.5f) * uvYSize;
		var radiusX = m_MaskParam2.x / width * uvXSize;
		return new Vector4
		{
			x = centerX,
			y = centerY,
			z = radiusX * radiusX,
			w = texture.height / (float)texture.width
		};
	}
}
