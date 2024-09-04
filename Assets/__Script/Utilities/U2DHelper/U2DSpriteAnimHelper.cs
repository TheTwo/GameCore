using UnityEngine;

[RequireComponent(typeof(U2DSpriteMesh))]
[ExecuteAlways]
public class U2DSpriteAnimHelper : MonoBehaviour
{
	public float m_Width;
	public float m_Height;
	public Color m_Color = Color.white;
	public Vector2 m_Pivot = new Vector2(0.5f, 0.5f);
	public float m_PixelSize = 1f;

	public U2DSpriteMesh.FillType m_FillType = U2DSpriteMesh.FillType.Simple;
	public U2DSpriteMesh.AspectRatioSource m_AspectRatioSource;
	[Range(0, 1)] public float m_FillAmount;
	
	public U2DSpriteMesh.MaskType m_MaskType = U2DSpriteMesh.MaskType.None;
	[Header("矩形区的左下角或圆的圆心")]
	public Vector2 m_MaskParam1 = Vector2.zero;
	[Header("矩形区的右上角或圆的半径(x)")]
	public Vector2 m_MaskParam2 = Vector2.zero;

	private U2DSpriteMesh m_Mesh = null;

	
	private void OnEnable()
	{
		if(m_Mesh == null)
		{
			m_Mesh = GetComponent<U2DSpriteMesh>();
			InitData();
		}
	}

	// Update is called once per frame
	void Update()
    {
		ApplyData();
    }

	void InitData()
	{
		if (m_Mesh == null) return;
		m_FillType			 = m_Mesh.fillType		;
		m_AspectRatioSource	 = m_Mesh.aspectRatio	;
		m_FillAmount		 = m_Mesh.fillAmount	;
		m_MaskType			 = m_Mesh.maskType		;
		m_MaskParam1		 = m_Mesh.maskParam1	;
		m_MaskParam2		 = m_Mesh.maskParam2	;
		m_Color				 = m_Mesh.color		    ;
		m_Height = m_Mesh.height;
		m_Width = m_Mesh.width ;
		m_Pivot = m_Mesh.pivot;
		m_PixelSize = m_Mesh.pixelSize;
	}

	void ApplyData()
	{
		if (m_Mesh == null) return;
		m_Mesh.fillType = m_FillType;
		m_Mesh.aspectRatio = m_AspectRatioSource;
		m_Mesh.fillAmount = m_FillAmount;

		m_Mesh.maskType = m_MaskType;
		m_Mesh.maskParam1 = m_MaskParam1;
		m_Mesh.maskParam2 = m_MaskParam2;

		m_Mesh.color = m_Color;
		m_Mesh.width = m_Width;
		m_Mesh.height = m_Height;
		m_Mesh.pivot = m_Pivot;
		m_Mesh.pixelSize = m_PixelSize;
	}
}
