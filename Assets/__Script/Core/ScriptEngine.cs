#define USE_BUFFER_LOADER
#if UNITY_EDITOR || UNITY_DEBUG
#define ASSET_DEBUG
#endif

using System;
using DragonReborn;
using DragonReborn.AssetTool;
// using DragonReborn.UI;
#if UNITY_EDITOR
using DragonReborn.AssetTool.Editor;
#endif
using UnityEngine;
using XLua;
using XLua.LuaDLL;
#if USE_UNI_LUA
using LuaCSFunction = UniLua.CSharpFunctionDelegate;
#else
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;
#endif

public class ScriptEngine : Singleton<ScriptEngine>
{
	public static event Action OnShutdown;
	
	private LuaFunction _onApplicationFocus;
    private LuaFunction _onApplicationPause;
    private LuaFunction _startUp;
    private LuaFunction _shutDown;
    private LuaFunction _onUpdate;
    private LuaFunction _onLateUpdate;
    private LuaFunction _onLuaException;
    private LuaFunction _onCSharpException;
    private LuaFunction _onTriggerEvent;
    private LuaFunction _restart;
	private LuaFunction _onLowMemory;

    public const string USE_PACK_MODE = "USE_PACK_MODE";
    public const string USE_LOCAL_CONFIG = "USE_LOCAL_CONFIG";
    public const string USE_PRIVATE_SERVER_LOCAL_CONFIG = "USE_PRIVATE_SERVER_LOCAL_CONFIG";
    
    public LuaEnv LuaInstance { get; private set; }

    private LuaTable _entry;

    public static bool Initialized;
    public static bool Updated;
    private float? _nextStartupTime;
    private bool? _applicationFocus;

    public void Startup(EnvironmentVariable env = null)
    {
	    LuaInstance = new LuaEnv();
		AddLuaLoader();
        
        // add for watcher
        // LuaInstance.AddBuildin("watcher", Lua.LoadWatcher);
        // LuaInstance.AddBuildin("lz4", Lua.LoadLz4);
        // LuaInstance.AddBuildin("xxhash", Lua.LoadXXHash);
        // Lua.InitWatcher();

        Lua.luaopen_ssrbitarray(LuaInstance.L);
        Lua.luaopen_ssrstreamhandle(LuaInstance.L);
        Lua.luaopen_ssrbytearray(LuaInstance.L);
		Lua.luaopen_ssrmemlib(LuaInstance.L);
		Lua.luaopen_ssrstrex(LuaInstance.L);
		
        LuaInstance.OpenSsrLib_Physics();
        // LuaInstance.OpenSsrLib_Debug();
        LuaInstance.OpenSsrLib_HotReloadMark();
        LuaInstance.OpenSsrLib_IOUtilsReadTextFile();
        // LuaInstance.OpenSsrLib_UnmanagedMemoryHelper();
        
#if UNITY_RUNTIME_ON_GUI_ENABLED || UNITY_EDITOR
        // DebugSupport.RegisterInLua(this);
#endif
        
        var results = LuaInstance.DoString(@"local entry = require(""Game""); return entry");
        if (results == null || results.Length <= 0)
        {
            return;
        }
        
        _entry = results[0] as LuaTable;
        if (_entry == null)
        {
            return;
        }

        _onApplicationFocus = _entry.FastGetFunction("OnApplicationFocus");
        _onApplicationPause = _entry.FastGetFunction("OnApplicationPause");
        
        _onUpdate = _entry.FastGetFunction("Update");
        _onLateUpdate = _entry.FastGetFunction("LateUpdate");
        _shutDown = _entry.FastGetFunction("ShutDown");
        _onLuaException = _entry.FastGetFunction("UnhandledLuaException");
        _onCSharpException = _entry.FastGetFunction("UnhandledCSharpException");
        _onTriggerEvent = _entry.FastGetFunction("TriggerEvent");
        _restart = _entry.FastGetFunction("RestartFromCSharpLogic");
		_onLowMemory = _entry.FastGetFunction("OnLowMemory");
        EventData = LuaInstance.NewTable();
        
        Application.logMessageReceived += OnExceptionMessageReceived;
        AppDomain.CurrentDomain.UnhandledException += OnUnhandledException;
        
        env ??= new EnvironmentVariable();
        _startUp = _entry.FastGetFunction("Startup");
        _startUp?.Call(_entry, env);
        
#if UNITY_RUNTIME_ON_GUI_ENABLED || UNITY_EDITOR
        // DebugSupport.GameStart(this);
#endif

	    Initialized = true;
	    LuaGCMonitor.OnInitialize();
	    // SendUIBehaviourEventHelper.SendUIBehaviourEvent = TriggerEventFromUIBehaviour;
    }

	public void Shutdown()
	{
		// SendUIBehaviourEventHelper.SendUIBehaviourEvent = null;
		Updated = false;
	    Application.logMessageReceived -= OnExceptionMessageReceived;
	    AppDomain.CurrentDomain.UnhandledException -= OnUnhandledException;
	    LuaGCMonitor.OnRelease();
	    
	    LuaBehaviour.OnQuit();
	    Updater.Clear();
	    Initialized = false;
	    
#if UNITY_RUNTIME_ON_GUI_ENABLED || UNITY_EDITOR
	    // DebugSupport.GameShutDown();
#endif
        OnShutdown?.Invoke();

        _onApplicationFocus?.Dispose();
        _onApplicationFocus = null;
        
        _onApplicationPause?.Dispose();
        _onApplicationPause = null;

        _shutDown?.Call(_entry);
        _shutDown?.Dispose();
        _shutDown = null;
        
        _onUpdate?.Dispose();
        _onUpdate = null;
        
        _onTriggerEvent?.Dispose();
        _onTriggerEvent = null;
        
        EventData?.Dispose();
        EventData = null;
        
        _onLateUpdate?.Dispose();
	    _onLateUpdate = null;
	    
	    _entry?.Dispose(); 
	    _entry = null;

		_onLowMemory?.Dispose();
		_onLowMemory = null;
		 
        // Lua.ClearWatcher();

        DisposeLuaEnv();
    }

    private void DisposeLuaEnv()
    {
	#if UNITY_EDITOR || UNITY_DEBUG
	        LuaInstance?.Dispose();
	        LuaInstance = null;
	#endif
    }
 
    public void OnApplicationFocus(bool obj)
    {
	    _onApplicationFocus?.Action(_entry, obj);
    }

    public void OnApplicationPause(bool obj)
    {
	    _onApplicationPause?.Action(_entry, obj);
    }

    public void OnLowMemory()
    {
	    LuaScriptLoader.OnLowMemory();
		_onLowMemory?.Action(_entry);
	}

    public void Update(float deltaTime)
    {
	    if (_nextStartupTime.HasValue && Time.time > _nextStartupTime)
	    {
		    Startup();
		    _nextStartupTime = null;
		    return;
	    }
	    
	    _onUpdate?.Action(_entry, deltaTime);
	    LuaInstance?.Tick();
    }

    public void LateUpdate(float deltaTime)
    {
        _onLateUpdate?.Action(_entry, deltaTime);
    }

    public void TriggerEvent(string eventName, LuaTable data)
    {
	    // _onTriggerEvent?.Action(_entry, eventName, data);
    }

    private void TriggerEventFromUIBehaviour(UnityEngine.EventSystems.UIBehaviour uiBehaviour, string eventName, string eventData)
    {
	    var table = Instance.EventData;
	    table.Set("UIBehaviour", uiBehaviour);
	    table.Set("eventData", eventData);
	    TriggerEvent(eventName, table);
	    table.Clear();
    }

    public LuaTable EventData { get; private set; }

    private void AddLuaLoader()
    {
#if UNITY_EDITOR
		// 真机模式
		if (AssetModeSwitch.IsDeviceMode())
		{
			// read luac pack from GameAssets
#if !USE_BUFFER_LOADER
			LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromPack);
#else
			LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromPack2);
#endif
		}
		else
		{
			// read luac pack from GameAssets
			if (UnityEditor.EditorPrefs.GetBool(USE_PACK_MODE, false))
			{
#if !USE_BUFFER_LOADER
				LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromPack);
#else
				LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromPack2);
#endif
			}

			LuaScriptLoader.ClearCache();
			// read lua from ssr-logic
			if (!UnityEditor.EditorPrefs.GetBool("DISABLE_LUA_DEV_FOLDER", false))
			{
#if !USE_BUFFER_LOADER
				LuaInstance.AddLoader(LuaScriptLoader.LoadFromAssetManagerEditor);
#else
				LuaInstance.AddLoader(LuaScriptLoader.LoadFromAssetManagerEditor2);
#endif
			}
			AssetDatabaseLoader.sFindPathCallback = AssetPathService.GetSavePath;
#if ASSET_DEBUG
			AssetWhiteList.sFindPathCallback = AssetPathService.GetSavePath;
#endif

			// read luac outside Assets Folder
#if !USE_BUFFER_LOADER
			LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromProjFolder);
#else
			LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromProjFolder2);
#endif
		}
#else
#if !USE_BUFFER_LOADER
        // read luac pack from GameAssets
	    LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromPack);
#else
			LuaInstance.AddLoader(LuaScriptLoader.LoadLuacFromPack2);
#endif
#endif
	}

	private void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
    {
	    _onCSharpException?.Action(_entry, e?.ExceptionObject?.ToString());
    }

    private void OnExceptionMessageReceived(string condition, string stacktrace, LogType type)
    {
	    if (type != LogType.Exception) return;
#if !UNITY_EDITOR
	    if (!Updated)
	    {
			NLogger.ErrorChannel("ExceptionHandle", condition + ": c# stacktrace:\n" + stacktrace);
			ClearAndRestartGame();
		    return;
	    }
#endif
	    
	    if (condition.StartsWith(nameof(LuaStackTraceException)))
	    {
		    if (condition.StartsWith(nameof(LuaStackTraceException) + ": c# exception:"))
			    _onCSharpException?.Action(_entry, condition);
		    else
			    _onLuaException?.Action(_entry, condition);
	    }
	    else
	    {
		    _onCSharpException?.Action(_entry, condition + ": c# stacktrace:\n" + stacktrace);
	    }
    }

    public void ReleaseCSharpObject(object o)
    {
	    var translator = LuaInstance?.translator;
	    translator?.ReleaseCSObjInCS(o);
    }

    [MonoPInvokeCallback(typeof(LuaCSFunction))]
    public static int HotReloadFinish(IntPtr l)
    {
	    Updated = true;
	    return 0;
    }

    public static void EnableLuaProfiler(bool flag)
    {
	    Lua.lua_ssr_enable_profiler(Instance.LuaInstance.L, flag ? 1 : 0);
    }

    public static void EnableProfilerTraceLuaGC(bool flag)
    {
	    Lua.luaenable_tracegc(flag ? 1 : 0);
    }

    // ReSharper disable once UnusedMember.Local
    private void ClearAndRestartGame()
    {
	    try
	    {
		    Shutdown();
	    }
	    catch (Exception e)
	    {
		    // SdkCrashlytics.LogCustomException(e);
	    }
	    finally
	    {
		    LuaInstance?.Dispose();
		    LuaInstance = null;
	    }

	    // if (IOUtils.HaveGameAssetInDocument(LuaScriptLoader.LuacPackRelativePath))
	    // {
		   //  IOUtils.DeleteGameAsset(LuaScriptLoader.LuacPackRelativePath);
	    // }
	    IOUtils.DeleteGameAssetByPattern("GameAssets",LuaScriptLoader.LuacPackPreFix + "*.pack", System.IO.SearchOption.TopDirectoryOnly);

	    //LuaScriptLoader.ClearHotfixFolder();
	    LaterStartup(2f);
    }

    private void LaterStartup(float f)
    {
	    _nextStartupTime = Time.time + f;
    }

    public void TriggerLuaRestartGame(string titleKey, string contentKey, bool showReportBtn = false)
    {
	    // _restart?.Action(_entry, titleKey, contentKey, showReportBtn);
    }

	public static void OnResetGame()
	{
		LuaBehaviour.OnQuit();
		Updater.Clear();
		Updated = false;
	}
}
