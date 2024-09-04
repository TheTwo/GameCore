using System.Runtime.CompilerServices;
using UnityEngine;

// ReSharper disable once CheckNamespace
public static class RuntimeTextureFactory
{
	public static Texture2D CreateTexture2D(int width, int height, TextureFormat format, bool useChain,
		[CallerFilePath] string name = null, [CallerLineNumber] int line = 0)
	{
		return new Texture2D(width, height, format, useChain).ApplyName(name, line);
	}
	
	public static Texture2D CreateTexture2D(int width, int height, TextureFormat format, bool useChain, TextureWrapMode wrapMode,
		[CallerFilePath] string name = null, [CallerLineNumber] int line = 0)
	{
		return new Texture2D(width, height, format, useChain)
		{
			wrapMode = wrapMode,
		}.ApplyName(name, line);
	}
	
	public static Texture2D CreateTexture2D(int width, int height, TextureFormat format, bool useChain, TextureWrapMode wrapMode, FilterMode filterMode,
		[CallerFilePath] string name = null, [CallerLineNumber] int line = 0)
	{
		return new Texture2D(width, height, format, useChain)
		{
			wrapMode = wrapMode,
			filterMode = filterMode,
		}.ApplyName(name, line);
	}

	public static RenderTexture CreateRenderTexture(int width, int height, int depth,
		[CallerFilePath] string name = null, [CallerLineNumber] int line = 0)
	{
		return new RenderTexture(width, height, depth).ApplyName(name, line);
	}

	public static void DestroyRenderTexture(RenderTexture renderTexture)
	{
		if (renderTexture == null)
		{
			return;
		}
		
		if (renderTexture.IsCreated())
		{
			renderTexture.Release();
		}
			
		Object.Destroy(renderTexture);
	}

	private static T ApplyName<T>(this T texture, string name, int line) where T : Texture
	{
#if UNITY_EDITOR || UNITY_DEBUG
		texture.name = $"{name}:{line}";
#endif
		return texture;
	}
}
