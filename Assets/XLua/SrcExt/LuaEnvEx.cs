using DragonReborn;
using DragonReborn.UI;

// ReSharper disable once CheckNamespace
namespace XLua
{
    public partial class LuaEnv
    {
	    public LuaTable CreateLuaClassInstance(ILuaComponent luaComponent)
        {
	        return CreateLuaClassInstance(luaComponent.LuaScriptPath());
        }
        
        public LuaTable CreateLuaClassInstance(LuaBehaviour luaBehaviour)
        {
	        return CreateLuaClassInstance(luaBehaviour.scriptName);
        }
        
        public object[] CreateLuaSchema(LuaBehaviour luaBehaviour)
        {
	        var schemaName = luaBehaviour.schemaName;
	        return DoString($"return require('{schemaName}')");
        }
        
        public LuaTable CreateLuaClassInstance(string clsName)
        {
	        var trunk = LoadString($"local cls = require(\"{clsName}\").new; return cls");
	        var clsNew = trunk.Func<LuaFunction>();
	        return clsNew.Func<LuaTable>();
        }

        // 尽量避免使用此函数
        public LuaTable CreateLuaClassInstance(ILuaComponent luaComponent, params object[] p)
        {
            var trunk = LoadString($"local cls = require(\"{luaComponent.LuaScriptPath()}\").new; return cls");
            var clsNew = trunk.Func<LuaFunction>();
            return clsNew.Call(p)[0] as LuaTable;
        }
    }
}