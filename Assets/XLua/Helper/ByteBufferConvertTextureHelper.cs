using System;
using DragonReborn;
using UnityEngine;

public static class ByteBufferConvertTextureHelper
{
	public static Texture2D Convert(ReadOnlySpan<byte> span, int width, int height, ref Texture2D texture2D)
	{
		var length = width * height;
		if (span.Length != length)
		{
			NLogger.ErrorChannel("ByteBufferConvertTextureHelper", "byte span length doesn't match the size");
			return null;
		}

		if (!texture2D || texture2D.width != width || texture2D.height != height)
		{
			if (texture2D)
				UnityEngine.Object.Destroy(texture2D);
			texture2D = new Texture2D(width, height, TextureFormat.Alpha8, false)
			{
				wrapMode = TextureWrapMode.Clamp,
			};
		}

		var pixels = texture2D.GetPixelData<byte>(0);
		for (int i = 0; i < span.Length; i++)
		{
			pixels[i] = span[i];
		}
		texture2D.Apply();
		return texture2D;
	}
}
