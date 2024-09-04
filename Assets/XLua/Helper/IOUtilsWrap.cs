using DragonReborn;
using Unity.Collections.LowLevel.Unsafe;
using XLua;
#if USE_UNI_LUA
using LuaAPI = UniLua.Lua;
using RealStatePtr = UniLua.ILuaState;
using LuaCSFunction = UniLua.CSharpFunctionDelegate;
#else
#if CHECK_XLUA_API_CALL_ENABLE
using LuaAPI = XLua.LuaDLL.LuaDLLWrapper;
#else
using LuaAPI = XLua.LuaDLL.Lua;
#endif
using RealStatePtr = System.IntPtr;
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;
#endif

// ReSharper disable once CheckNamespace
public static class IOUtilsWrap
{
	// public static string ReadStreamingAssetAsText(string relativePath, bool decode = false)
	[MonoPInvokeCallback(typeof(LuaCSFunction))]
	public static int ReadStreamingAssetAsText(RealStatePtr L)
	{
		try
		{
			var relativePath = LuaAPI.lua_tostring(L, 1);
			var decode = false;
			var paramCount = LuaAPI.lua_gettop(L);
			if (paramCount == 2 && LuaTypes.LUA_TBOOLEAN == LuaAPI.lua_type(L, 2))
			{
				decode = LuaAPI.lua_toboolean(L, 2);
			}
			var bytes = IOUtils.ReadStreamingAsset(relativePath);
			if (bytes is { Length: > 0 })
			{
				if (decode)
				{
					if (!SafetyUtils.CodeByteBuffer(bytes))
					{
						LuaAPI.lua_pushnil(L);
						return 1;
					}
				}
				LuaAPI.xlua_pushlstring(L, bytes, bytes.Length);
				return 1;
			}
			LuaAPI.lua_pushnil(L);
			return 1;
		}
		catch (LuaStackTraceException e)
		{
			UnityEngine.Debug.LogException(e);
			return LuaAPI.luaL_error(L, "c# exception in " + nameof(ReadStreamingAssetAsText)+ ": " + e);
		}
		catch (System.Exception e)
		{
			return LuaAPI.luaL_error(L, "c# exception in " + nameof(ReadStreamingAssetAsText)+ ": " + e);
		}
	}
	
	// public static string ReadGameAssetAsText(string relativePath, bool decode = false)
	[MonoPInvokeCallback(typeof(LuaCSFunction))]
	public static int ReadGameAssetAsText(RealStatePtr L)
	{
		try
		{
			var relativePath = LuaAPI.lua_tostring(L, 1);
			var decode = false;
			var paramCount = LuaAPI.lua_gettop(L);
			if (paramCount == 2 && LuaTypes.LUA_TBOOLEAN == LuaAPI.lua_type(L, 2))
			{
				decode = LuaAPI.lua_toboolean(L, 2);
			}
			var bytes = IOUtils.ReadGameAsset(relativePath);
			if (bytes is { Length: > 0 })
			{
				if (decode)
				{
					if (!SafetyUtils.CodeByteBuffer(bytes))
					{
						LuaAPI.lua_pushnil(L);
						return 1;
					}
				}
				LuaAPI.xlua_pushlstring(L, bytes, bytes.Length);
				return 1;
			}
			LuaAPI.lua_pushnil(L);
			return 1;
		}
		catch (LuaStackTraceException e)
		{
			UnityEngine.Debug.LogException(e);
			return LuaAPI.luaL_error(L, "c# exception in " + nameof(ReadGameAssetAsText)+ ": " + e);
		}
		catch (System.Exception e)
		{
			return LuaAPI.luaL_error(L, "c# exception in " + nameof(ReadGameAssetAsText)+ ": " + e);
		}
	}

	// public static object ReadGameAssetAsText(AssetManager assetMgr, LuaFunction jsonDecode, string textPath, SyncLoadReason reason = SyncLoadReason.None)
	[MonoPInvokeCallback(typeof(LuaCSFunction))]
	public static int ReadTextAsLuaJsonObject(RealStatePtr L)
	{
		try
		{
			ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
			DragonReborn.AssetTool.AssetManager assetMgr = (DragonReborn.AssetTool.AssetManager)translator.FastGetCSObj(L, 1);
			int paramCount = LuaAPI.lua_gettop(L);
			if (paramCount == 4 
			    && LuaAPI.lua_isfunction(L, 2)
			    && (LuaAPI.lua_isnil(L, 3) || LuaAPI.lua_type(L, 3) == LuaTypes.LUA_TSTRING) 
			    && translator.Assignable<DragonReborn.AssetTool.AssetManager.SyncLoadReason>(L, 4))
			{
				string textPath = LuaAPI.lua_tostring(L, 3);
				translator.Get(L, 3, out DragonReborn.AssetTool.AssetManager.SyncLoadReason reason);
				var handle = assetMgr.LoadAsset(textPath, false, reason);
				if (handle.Asset)
				{
					var textAsset = handle.Asset as UnityEngine.TextAsset;
					if (textAsset == null)
					{
						NLogger.ErrorChannel(DragonReborn.AssetTool.AssetManager.Channel, $"{textPath} is not TextAsset");
						LuaAPI.lua_pushnil(L);
						return 1;
					}
					var textData = textAsset.GetData<byte>();
					int oldTop = LuaAPI.lua_gettop(L);
					int errFunc = LuaAPI.load_error_func(L, translator.luaEnv.errorFuncRef);
					LuaAPI.lua_pushvalue(L, -3);
					unsafe
					{
						LuaAPI.xlua_pushlstringRaw(L, (byte*)textData.GetUnsafeReadOnlyPtr(), textData.Length);
					}
					assetMgr.UnloadAsset(handle);
					int error = LuaAPI.lua_pcall(L, 1, 1, errFunc);
					if (error != 0)
						translator.luaEnv.ThrowExceptionFromError(oldTop);
					return 1;
				}
			}else if (paramCount == 3
			          && LuaAPI.lua_isfunction(L, 2)
			          && (LuaAPI.lua_isnil(L, 3) || LuaAPI.lua_type(L, 3) == LuaTypes.LUA_TSTRING))
			{
				string textPath = LuaAPI.lua_tostring(L, 3);
				var handle = assetMgr.LoadAsset(textPath);
				if (handle.Asset)
				{
					var textAsset = handle.Asset as UnityEngine.TextAsset;
					if (textAsset == null)
					{
						NLogger.ErrorChannel(DragonReborn.AssetTool.AssetManager.Channel, $"{textPath} is not TextAsset");
						LuaAPI.lua_pushnil(L);
						return 1;
					}
					var textData = textAsset.GetData<byte>();
					int oldTop = LuaAPI.lua_gettop(L);
					int errFunc = LuaAPI.load_error_func(L, translator.luaEnv.errorFuncRef);
					LuaAPI.lua_pushvalue(L, -3);
					unsafe
					{
						LuaAPI.xlua_pushlstringRaw(L, (byte*)textData.GetUnsafeReadOnlyPtr(), textData.Length);
					}
					assetMgr.UnloadAsset(handle);
					int error = LuaAPI.lua_pcall(L, 1, 1, errFunc);
					if (error != 0)
						translator.luaEnv.ThrowExceptionFromError(oldTop);
					return 1;
				}
			}
			LuaAPI.lua_pushnil(L);
			return 1;
		}
		catch (LuaStackTraceException e)
		{
			UnityEngine.Debug.LogException(e);
			return LuaAPI.luaL_error(L, "c# exception in " + nameof(ReadTextAsLuaJsonObject)+ ": " + e);
		}
		catch (System.Exception e)
		{
			return LuaAPI.luaL_error(L, "c# exception in " + nameof(ReadTextAsLuaJsonObject)+ ": " + e);
		}
	}
}
