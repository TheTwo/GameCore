using System;
using DragonReborn.AssetTool;
using XLua;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public sealed class LuaSpriteSetNotify : LuaBehaviour, ISpriteSetNotify
	{
		private Action<LuaTable, bool, string> _onSpriteManagerSetSprite;

		protected override void OnBeforeLuaAwake()
		{
			base.OnBeforeLuaAwake();
			InternalGetLuaInstance?.Get(nameof(OnSpriteManagerSetSprite), out _onSpriteManagerSetSprite);
		}

		public void OnSpriteManagerSetSprite(bool isSuccess, string spriteName)
		{
			if (null == Instance) return;
			_onSpriteManagerSetSprite?.Invoke(Instance, isSuccess, spriteName);
		}
	}
}
