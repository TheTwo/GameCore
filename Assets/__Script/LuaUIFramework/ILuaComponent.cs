using UnityEngine;
using XLua;

// ReSharper disable once CheckNamespace
namespace DragonReborn.UI
{
	public interface ILuaComponent
    {
        string LuaScriptPath();
		LuaTable Lua { get; set; }
        Transform transform { get; }
#if UNITY_EDITOR
		string LuaScriptFullPath();
		void SetLuaScriptFullPath(string fullPath);
#endif
    }
}
