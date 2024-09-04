using UnityEngine.Scripting;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool
{
	[RequireImplementors]
	public interface ISpriteSetNotify
	{
		void OnSpriteManagerSetSprite(bool isSuccess, string spriteName);
	}
}
