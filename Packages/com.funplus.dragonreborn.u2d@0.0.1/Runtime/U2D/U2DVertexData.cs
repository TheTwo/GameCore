using UnityEngine;
using UnityEngine.Rendering;

public struct U2DVertexData
{
	public Vector3 Position;
	public Color32 Color;
	public Vector2 TexCoord0;
	public Vector2 TexCoord1;
	public Vector4 TexCoord2;
	
	public static readonly VertexAttributeDescriptor[] VertexAttributeDescriptors =
	{
		new(VertexAttribute.Position),
		new(VertexAttribute.Color, VertexAttributeFormat.UNorm8, 4),
		new(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2),
		new(VertexAttribute.TexCoord1, VertexAttributeFormat.Float32, 2),
		new(VertexAttribute.TexCoord2, VertexAttributeFormat.Float32, 4),
	};
}