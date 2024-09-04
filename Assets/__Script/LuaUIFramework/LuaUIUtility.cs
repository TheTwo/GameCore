using UnityEngine;
#if USE_XLUA
using System;
using XLua;
#endif
namespace DragonReborn.UI
{
    public static class LuaUIUtility
    {
#if USE_XLUA
        public static LuaFunction[] InitAllLuaFunc(LuaTable luaObject, Type funcEnumType)
        {
            if(luaObject==null)
            {
                return null;
            }

            var funcTypes = Enum.GetValues(funcEnumType);
            int funcCount = funcTypes.Length;
            var luaFunctions = new LuaFunction[funcCount];
            int index = 0;
            foreach (var funcType in funcTypes)
            {
                luaObject.Get(funcType.ToString(),out luaFunctions[index]);
                index++;
            }

            return luaFunctions;
        }

        public static LuaTable GetLuaTableForUI<T>(T baseComponent) where T : BaseComponent, ILuaComponent
        {
            LuaEnv luaEnv = ScriptEngine.Instance.LuaInstance;
            var table = luaEnv.CreateLuaClassInstance(baseComponent);
            if (table != null && baseComponent != null)
            {
                baseComponent.LogicObject = table;
                table.Set("CSComponent", baseComponent);
            }
            return table;
        }
        
        public static void InvokeLuaFunc<T0,T1>( LuaTable luaObject, LuaFunction[] functions, int index, T0 param0, T1 param1  )
        {
            if(functions != null && functions.Length > index)
            {
                functions[index]?.Action(luaObject,param0,param1);
            }
        }
        
        public static void InvokeLuaFunc<T>( LuaTable luaObject, LuaFunction[] functions, int index, T data)
        {
            if(functions != null && functions.Length > index)
            {
                functions[index]?.Action(luaObject,data);
            }
        }
        public static void InvokeLuaFunc(LuaTable luaObject, LuaFunction[] functions, int index)
        {
            if(functions != null && functions.Length > index)
            {
                functions[index]?.Action(luaObject);
            }
        }
        
        public static bool InvokeLuaFunc<T>(LuaTable luaObject, LuaFunction[] functions, int index,
	        out T ret)
        {
	        if(functions != null && functions.Length > index)
	        {
		        if (null != functions[index])
		        {
			        ret = functions[index].Func<LuaTable, T>(luaObject);
			        return true;
		        }
	        }
	        ret = default;
	        return false;
        }

        public static bool InvokeLuaFunc<T0, T1>(LuaTable luaObject, LuaFunction[] functions, int index, T0 data,
	        out T1 ret)
        {
	        if(functions != null && functions.Length > index)
	        {
		        if (null != functions[index])
		        {
			        ret = functions[index].Func<LuaTable, T0, T1>(luaObject, data);
			        return true;
		        }
	        }
	        ret = default;
	        return false;
        }
        
        public static bool InvokeLuaFunc<T0, T1, T2>(LuaTable luaObject, LuaFunction[] functions, int index, T0 data, T1 data1,
	        out T2 ret)
        {
	        if(functions != null && functions.Length > index)
	        {
		        if (null != functions[index])
		        {
			        ret = functions[index].Func<LuaTable, T0, T1, T2>(luaObject, data, data1);
			        return true;
		        }
	        }
	        ret = default;
	        return false;
        }

        public static LuaTable AddLuaComponent(string luaPath, GameObject go)
        {
            if(string.IsNullOrEmpty(luaPath) || go == null) return null;
            var comp = go.AddComponent<LuaBaseComponent>();
            comp.SetLuaScriptPath(luaPath);
            comp.ManualTransformParentChanged();
            return comp.Lua;
        }
        
		public static void InvokeLuaFunction(LuaTable luaObject,string functionName)
		{
			LuaFunction luaFunction;
			luaObject.Get(functionName, out luaFunction);
			if(luaFunction != null)
			{
				luaFunction.Action(luaObject);
			}
		}

#endif

    }
}
