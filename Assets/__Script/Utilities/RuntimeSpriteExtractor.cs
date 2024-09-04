using System;
using UnityEngine;

namespace __Script.Utilities
{
	public static class RuntimeSpriteExtractor
	{
		public static Sprite Extract(this Sprite srcSprite)
		{
			if (!srcSprite || !srcSprite.texture || (srcSprite.packed && srcSprite.packingMode != SpritePackingMode.Rectangle))
				return null;
			var baseTexture = ExtractFromSprite(srcSprite.texture, srcSprite.textureRect , false);
			var rect = srcSprite.rect;
			var originPivot = srcSprite.pivot;
			var pivot = new Vector2(originPivot.x / rect.width, originPivot.y / rect.height);
			var spriteRect = new Rect(0, 0, Mathf.Min(rect.width, baseTexture.width), Mathf.Min(rect.height, baseTexture.height));
			return Sprite.Create(baseTexture, spriteRect, pivot, srcSprite.pixelsPerUnit, 0, SpriteMeshType.FullRect);
		}

		public static Texture2D ExtractFromSprite(Texture2D srcAtlas, Rect spriteRect, bool isReadable)
		{
			var retTexture = new Texture2D(Mathf.FloorToInt(spriteRect.width + 0.5f), Mathf.FloorToInt(spriteRect.height + 0.5f), TextureFormat.RGBA32, false, false);
			var tempRenderTexture = RenderTexture.GetTemporary(srcAtlas.width, srcAtlas.height, 0,
				RenderTextureFormat.Default, RenderTextureReadWrite.Default, 1,
				RenderTextureMemoryless.Color,
				VRTextureUsage.None, false);
			var currentRenderTexture = RenderTexture.active;
			try
			{
				Graphics.Blit(srcAtlas, tempRenderTexture);
				RenderTexture.active = tempRenderTexture;
				if (SystemInfo.graphicsUVStartsAtTop)
				{
					spriteRect.y = srcAtlas.height - spriteRect.y - spriteRect.height;
				}
				retTexture.ReadPixels(spriteRect, 0,0, false);
			}
			catch (Exception e)
			{
				Debug.LogException(e);
			}
			finally
			{
				RenderTexture.active = currentRenderTexture;
				RenderTexture.ReleaseTemporary(tempRenderTexture);
			}
			retTexture.Apply(false, !isReadable);
			return retTexture;
		}
	}
}
