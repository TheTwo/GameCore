local LoadedMap = {}
for k, v in pairs(package.loaded) do
    LoadedMap[k] = k
end
local DelayUnload = {
    ["LuaDebuggerInit"] = 1,
    ["EmmyLuaDebug"]  = 2,
    ["LuaPanda"] = 3,
}

require "Globals"

--end of Game Stats
---@class Game
---@field new fun():Game
---@field private managers table
---@field private frameTickers fun(delta:number)[]
---@field private ignoreInvervalFrameTickers fun(delta:number)[]
---@field private lateUpdateTickers table
---@field private secondTickers table
local Game = class("Game")

function Game:ctor()
    ---@type Game
    g_Game = self;
    g_Logger = require("Logger")
    
    --场景加载工具类
    self.SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
    
    ---from DebugSupport.cs, may nil,manual register lua bind code
    self.debugSupport = CS.DebugSupport
    self.debugSupportOn = self.debugSupport and self.debugSupport.IsOn or false
    ---@type CS.SdkAdapter.SdkWrapper
    self.sdkWrapper = CS.SdkAdapter.SdkWrapper.Instance
end

---@param env CS.EnvironmentVariable
function Game:Startup(env)
    g_Logger.Log('Game:Startup')
    
    UNITY_EDITOR = env:UNITY_EDITOR()
    UNITY_ANDROID = env:UNITY_ANDROID()
    UNITY_IOS = env:UNITY_IOS()
    UNITY_STANDALONE_OSX = env:UNITY_STANDALONE_OSX()
    UNITY_STANDALONE_WIN = env:UNITY_STANDALONE_WIN()

    USE_BUNDLE_ANDROID = env:USE_BUNDLE_ANDROID()
    USE_BUNDLE_IOS = env:USE_BUNDLE_IOS()
    USE_BUNDLE_OSX = env:USE_BUNDLE_OSX()
    USE_BUNDLE_WIN = env:USE_BUNDLE_WIN()
    
    UNITY_DEBUG = env:UNITY_DEBUG()
    UNITY_RUNTIME_ON_GUI_ENABLED = env:UNITY_RUNTIME_ON_GUI_ENABLED()
	INGAME_CONSOLE_ENABLED = env:INGAME_CONSOLE_ENABLED()
    USE_LOCAL_CONFIG = env:USE_LOCAL_CONFIG()
    USE_PRIVATE_SERVER_LOCAL_CONFIG = env:USE_PRIVATE_SERVER_LOCAL_CONFIG()
    SHADER_CREATE_PROGRAM_TRACKING = env:SHADER_CREATE_PROGRAM_TRACKING()
    
    IS_32_BIT = env:IS_32_BIT()
    USE_FPXSDK = env:USE_FPXSDK()
    USE_CHATSDK = UNITY_EDITOR or UNITY_IOS or UNITY_ANDROID
    USE_UWA = env:USE_UWA()

    if UNITY_DEBUG and ((USE_BUNDLE_ANDROID or USE_BUNDLE_IOS or USE_BUNDLE_OSX or USE_BUNDLE_WIN) or not UNITY_EDITOR) then
        ---@type CS.DragonReborn.IOAccessRecorder
        self.IOAccessRecorder = CS.DragonReborn.IOAccessRecorder
    else
        self.IOAccessRecorder = {
            RecordAsset = function(_) end,
            RecordFile = function(_) end,
            Reset = function() end,
            StartStep = function(_) end,
            WriteDumpFile = function() end,
        }
    end
    
    self.EnableLuaProfiler = (UNITY_EDITOR and UNITY_DEBUG) == true
    CS.ScriptEngine.EnableLuaProfiler(self.EnableLuaProfiler)
    self.EnableProfilerTraceLuaGC = false

    if IS_32_BIT then
        g_Logger.Log('Running on 32 BIT device')
    else
        g_Logger.Log('Running on 64 BIT device')
    end

    if UNITY_EDITOR then
        Game.ConnectDebugger()
    end
    
    self:ExtremeGCStrategy()
    self:BuildAssetCache()
    self:StartGame()
end

function Game:ShutDown()
    g_Logger.Log('Game:ShutDown')
    self._isShuttingDown = true

    self.StateMachine:WriteBlackboard("finishedCallBack", nil, true)
    self.StateMachine:ChangeState(require("ExitState").Name)
    if UNITY_EDITOR then
        Game.ReleaseDebugger()
    end
    g_Logger.GameShutdown()
end

function Game:InitStateMachine()
    --初始化不重启不能热更的状态，其他状态在Initialization.PostSyncAssetBundle()中注册
    self.StateMachine = require("StateMachine").new(true)
    self:AddState(require("BootState").Name, require("BootState").new())
    self:AddState(require("ExitState").Name, require("ExitState").new())

    --启动游戏状态机
    self.StateMachine:ChangeState(require("BootState").Name)
end

function Game:OnLowMemory()
    g_Logger.Log('Game:OnLowMemory')
    for _, v in pairs(self.managers) do
        g_Logger.Log(GetClassName(v) .. " is OnLowMemory")
        v:OnLowMemory()
    end

	local Utils = require("Utils")
	Utils.FullGC()
end

function Game:Reset()
    g_Logger.Log('Game:Reset')

    for _, v in pairs(self.managers) do
        g_Logger.Log(GetClassName(v) .. " is being reseted")
        v:Reset();
    end

    self.managers = {}
    self.StateMachine:ClearAllStates()
    self.StateMachine = nil
    local delayUnloadQueue = {}
    for k, v in pairs(package.loaded) do
        if k == "watcher" then goto continue end
        if not LoadedMap[k] then
            if DelayUnload[k] then
                table.insert(delayUnloadQueue, k)
            else
                package.loaded[k] = nil
            end
        end
        ::continue::
    end
    if #delayUnloadQueue > 1 then
        table.sort(delayUnloadQueue, function(a, b)
            return DelayUnload[a] < DelayUnload[b]
        end)
    end
    for i = 1, #delayUnloadQueue do
        local k = delayUnloadQueue[i]
        local m = package.loaded[k]
        if m and type(m) == 'table' then
            local unloadMethod = rawget(m, "__DoOnUnload")
            if unloadMethod and type(unloadMethod) == 'function' then
                pcall(unloadMethod)
            end
        end
        package.loaded[k] = nil
    end
    table.clear(delayUnloadQueue)
    self:ClearWatcherGlobalFields()
    self.restartUIMark = nil
    if UNITY_DEBUG then
        self:DumpTicker()
    end
    CS.ScriptEngine.OnResetGame()
    -- CS.UnityEngine.Resources.UnloadUnusedAssets()
end

function Game:AddState(stateName, state)
    self.StateMachine:AddState(stateName, state)
end

function Game:StartGame()
    g_Logger.Log('Game:StartGame')
    
    self.focused = true
    self.managers = {}
    self.frameTickers = {}
    self.ignoreInvervalFrameTickers = {}
    self.lateUpdateTickers = {}
    self.secondTickers = {}
    self.systemTickers = {}
    self.logicTickDelta = nil
    self.blockNonSystemTicker = false

    self.Time = require("UnityTimeWrapper").new()
    self.RealTime = require("UnityTimeWrapper").new()
    self.PlayerPrefsEx = require("PlayerPrefsEx").new()
    if UNITY_EDITOR or UNITY_DEBUG then
        self.exceptionHandle = require("DebugExceptionHandle").new()
    else
        self.exceptionHandle = require("ReleaseExceptionHandle").new()
    end
    
    self:InitStateMachine()
end

function Game:RestartGame()
    if self._isShuttingDown then
        g_Logger.Log('Game:RestartGame skip')
        return
    end
    g_Logger.Log('Game:RestartGame')
    
    self.StateMachine:WriteBlackboard("finishedCallBack", function()
        CS.ECSHelper.RestartECSWorld()
        self:StartGame()
    end, true)
    g_Logger.TraceChannel("Game", "Game:RestartGame")
    self.StateMachine:ChangeState(require("ExitState").Name)    
end

function Game:QuitGame()
    if UNITY_EDITOR then
        CS.UnityEditor.EditorApplication.isPlaying = false;
    else
        CS.UnityEngine.Application.Quit()
    end
end

function Game:UpdateFinished()
    ssr.update_finish()
end

---@generic T1 : BaseManager
---@param manager T1
---@return T1
function Game:AddManager(manager)
    table.insert(self.managers, manager)
    return manager
end

local _frameInterval = 2
local _secondTimeStamp = 0

function Game:ShouldTick()
    return self.RealTime.frameCount % _frameInterval == 0
end

function Game:Update(delta)
    if self.GamePause then
        return
    end
    
    self.RealTime:Update(delta)

    for _, v in pairs(self.systemTickers) do
        v(delta)
    end

    if not self.blockNonSystemTicker then
        for _, v in pairs(self.ignoreInvervalFrameTickers) do
            v(delta)
        end
    end

    if not self.logicTickDelta then
        self.logicTickDelta = delta
    else
        self.logicTickDelta = self.logicTickDelta + delta
    end
    
    if self:ShouldTick() then
        local deltaLastTick = self.logicTickDelta
        self.logicTickDelta = 0
        self.Time:Update(deltaLastTick)

        if not self.blockNonSystemTicker then
            for _, v in pairs(self.frameTickers) do
                v(deltaLastTick)
            end
        end
        if self.StateMachine then
            self.StateMachine:Tick(deltaLastTick)
        end
    end

    local timeStamp = self.Time.time
    local secondDelta = timeStamp - _secondTimeStamp
    if (secondDelta >= 1) then
        if not self.blockNonSystemTicker then
            for _, v in pairs(self.secondTickers) do
                v(secondDelta)
            end
        end
        _secondTimeStamp = timeStamp;
    end
end

function Game:LateUpdate(delta)
    if self.blockNonSystemTicker then return end
    for _, v in pairs(self.lateUpdateTickers) do
        v(delta)
    end
end

---@param func fun(delta:number)
function Game:AddSecondTicker(func, pos)
    if type(pos) == "number" and pos > 0 and pos <= #self.secondTickers then
        table.insert(self.secondTickers, pos, func)
    else
        table.insert(self.secondTickers, func)
    end
end

function Game:RemoveSecondTicker(func)
    table.removebyvalue(self.secondTickers, func, true)
end

---@param func fun(delta:number)
function Game:AddFrameTicker(func, pos)
    if type(pos) == "number" and pos > 0 and pos <= #self.frameTickers then
        table.insert(self.frameTickers, pos, func)
    else
        table.insert(self.frameTickers, func)
    end
end

---@param func fun(delta:number)
function Game:RemoveFrameTicker(func)
    table.removebyvalue(self.frameTickers, func, true)
end

---@param func fun(delta:number)
function Game:AddIgnoreInvervalTicker(func, pos)
    if type(pos) == "number" and pos > 0 and pos <= #self.ignoreInvervalFrameTickers then
        table.insert(self.ignoreInvervalFrameTickers, pos, func)
    else
        table.insert(self.ignoreInvervalFrameTickers, func)
    end
end

function Game:RemoveIgnoreInvervalTicker(func)
    table.removebyvalue(self.ignoreInvervalFrameTickers, func, true)
end

---@param func fun(delta:number)
function Game:AddLateFrameTicker(func, pos)
    if type(pos) == "number" and pos > 0 and pos <= #self.lateUpdateTickers then
        table.insert(self.lateUpdateTickers, pos, func)
    else
        table.insert(self.lateUpdateTickers, func)
    end
end

function Game:RemoveLateFrameTicker(func)
    table.removebyvalue(self.lateUpdateTickers, func, true)
end

function Game:AddSystemTicker(func, pos)
    if type(pos) == "number" and pos > 0 and pos <= #self.systemTickers then
        table.insert(self.systemTickers, pos, func)
    else
        table.insert(self.systemTickers, func)
    end
end

function Game:RemoveSystemTicker(func)
    table.removebyvalue(self.systemTickers, func, true)
end

function Game:AddOnGUI(func)
    if self.debugSupportOn then
        self.debugSupport.AddOnGUIEvent(func)
    end
end

function Game:RemoveOnGUI(func)
    if self.debugSupportOn then
        self.debugSupport.RemoveOnGUIEvent(func)
    end
end

function Game:AddOnDrawGizmos(func)
    if self.debugSupportOn then
        self.debugSupport.AddOnDrawGizmosEvent(func)
    end
end

function Game:RemoveOnDrawGizmos(func)
    if self.debugSupportOn then
        self.debugSupport.RemoveOnDrawGizmosEvent(func)
    end
end

function Game:AddOnGUIWindow(func)
    if self.debugSupportOn then
        self.debugSupport.AddOnGuiWindowsEvent(func)
    end
end

function Game:RemoveGUIWindow(func)
    if self.debugSupportOn then
        self.debugSupport.RemoveOnGuiWindowsEvent(func)
    end
end

function Game:UnhandledLuaException(exceptionString)
    g_Logger.Error(exceptionString)
    local ModuleRefer = require("ModuleRefer")
    if ModuleRefer.AppInfoModule:ExceptionRestartEnable() then
        self.exceptionHandle:OnLuaException(exceptionString)
    end
end

function Game:UnhandledCSharpException(exceptionString)
    g_Logger.Error(exceptionString)
    local ModuleRefer = require("ModuleRefer")
    if ModuleRefer.AppInfoModule:ExceptionRestartEnable() then
        self.exceptionHandle:OnCSharpException(exceptionString)
    end
end

function Game:TriggerEvent(eventName, data)
    g_Game.EventManager:TriggerEvent(eventName, data)
end

---@param focus boolean
function Game:OnApplicationFocus(focus)
    self.focused = focus
    if focus then
        if g_Game.PowerManager then
            g_Game.PowerManager:KeepScreenOn()
        end

        if g_Game.EventManager then
            local EventConst = require("EventConst")
            g_Game.EventManager:TriggerEvent(EventConst.APPLICATION_FOCUS, true)
        end
        
        if g_Game.ServiceManager then
            g_Game.ServiceManager:IntoForeground()
        end
        g_Logger.LogChannel("Game", "IntoForeground")
    else
        if g_Game.EventManager then
            local EventConst = require("EventConst")
            g_Game.EventManager:TriggerEvent(EventConst.APPLICATION_FOCUS, false)
        end
    end
end

function Game:OnApplicationPause(pause)
    if pause then
        if g_Game.ServiceManager then
            g_Game.ServiceManager:IntoBackground()
        end

        -- 切后台
        if USE_FPXSDK then
            local ModuleRefer = require('ModuleRefer')
            ModuleRefer.FPXSDKModule:SetLocalNotifications()
        end

        g_Logger.LogChannel("Game", "IntoBackground")
    else
        -- 进入前台
        if USE_FPXSDK then
            local ModuleRefer = require('ModuleRefer')
            ModuleRefer.FPXSDKModule:ClearAllNotification()
        end
    end
end

function Game:ClearAllTickDelegates(clearSystem)
    self.frameTickers = {}
    self.secondTickers = {}
    self.lateUpdateTickers = {}
    self.ignoreInvervalFrameTickers = {}

    if clearSystem then
        self.systemTickers = {}
    end

    if UNITY_EDITOR or UNITY_DEBUG or UNITY_RUNTIME_ON_GUI_ENABLED then
        local EventConst = require("EventConst")
        g_Game.EventManager:TriggerEvent(EventConst.GAME_ERROR_CLEAR_TICK_DELEGATES)
    end
end

function Game:QuitGameManually()
    try_catch(function()
        local UIMediatorNames = require("UIMediatorNames")
        self.UIManager:Open(UIMediatorNames.SystemQuitUIMediator)
    end, g_Logger.Error)
end

function Game:ShouldRestartSkipDialogUI()
    if self.ServiceManager then
        if self.ServiceManager.safeForegroundTime and self.ServiceManager.startForegroundTime then
            local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
            if nowTime - self.ServiceManager.startForegroundTime <= self.ServiceManager.safeForegroundTime then
                return true
            end
        end
        return false
    end
    return true
end

function Game:RestartGameManually(title, content, context, showReportBtn)
    if self:ShouldRestartSkipDialogUI() then
        self:RestartGame()
        return
    end

    --- 触发重启时关掉全屏UI锁
    local UIHelper = require("UIHelper")
    UIHelper.RemoveFullScreenLock()

    if self.restartUIMark then return end

    local I18N = require("I18N")
    local btnText = I18N.Get("error_feedback_btn")

    local UIMediatorNames = require("UIMediatorNames")
    self:ClearAllTickDelegates()
    try_catch(function()
        ---@type SystemRestartUIMediatorParameter
        local param = {
            title = title,
            content = content,
            btnText = btnText,
            context = context,
            showReportBtn = showReportBtn,
        }
        self.UIManager:Open(UIMediatorNames.SystemRestartUIMediator, param, function(mediator)
            self:ClearAllTickDelegates(true)
        end)
    end, g_Logger.Error)
    self.restartUIMark = true
end

function Game:RestartGameWithCode(code)
    local I18N = require("I18N")
    self:RestartGameManually(("[SYS]%s"):format(I18N.Get("error_feedback_title")), ("%s.\n errCode : %d"):format(self:GetErrMsgWithCode(code), code))
end

---@private
function Game:RestartFromCSharpLogic(titleKey, contentKey, showReportBtn)
    local I18N = require("I18N")
    self:RestartGameManually(("[SYS]%s"):format(I18N.Get(titleKey)), I18N.Get(contentKey), nil, showReportBtn)
end

function Game:GetErrMsgWithCode(code)
    local cfg = self:GetErrCodeI18NCfg(code)
    local I18N = require("I18N")
    local ConfigRefer = require("ConfigRefer")
    if cfg and not string.IsNullOrEmpty(cfg:LanguageKey()) then
        return I18N.Get(cfg:LanguageKey())
    elseif not string.IsNullOrEmpty(ConfigRefer.ConstMain:ErrCodeFallbackI18N()) then
        return I18N.Get(ConfigRefer.ConstMain:ErrCodeFallbackI18N())
    else
        return "Unknown Error"
    end
end

function Game:GetErrCodeI18NCfg(code)
    local ConfigRefer = require("ConfigRefer")
    local cfg = ConfigRefer.ErrCodeI18N:Find(code)
    if not cfg then
        cfg = ConfigRefer.ErrCodeI18N:Find(ConfigRefer.ConstMain:ErrCodeFallbackId())
    end
    return cfg
end

function Game:SetProtocolVersionInfo(clientHash, serverHash)
    self.clientHash = clientHash
    self.serverHash = serverHash

    if string.IsNullOrEmpty(self.serverHash) then
        g_Logger.Warn("服务器未返回协议版本号, 跳过检查")
    elseif self.clientHash ~= self.serverHash then
        g_Logger.Error("客户端与服务器协议不一致[client:%s, server:%s]，需更新", self.clientHash, self.serverHash)
    end
end

function Game:BuildAssetCache()
    CS.DragonReborn.IOUtils.ProcessBundleAssetList("")
end

function Game.ConnectDebugger()
    local debugger = require("LuaDebuggerInit")
    debugger.ConnectDebugger()
end

function Game.ReleaseDebugger()
    local debugger = require("LuaDebuggerInit")
    debugger.ReleaseDebugger()
end

function Game:OnReconnect()
    local currentState = self.StateMachine:GetCurrentState()
    if currentState == nil then
        return self:RestartGame()
    end

    if not currentState.OnReconnect then
        return self:RestartGame()
    end

    if currentState:OnReconnect() then
        return self:RestartGame()
    end
end

function Game:DumpTicker()
    g_Logger.Log("dump lateUpdateTickers length: " .. #self.lateUpdateTickers)
    for k, v in pairs(self.lateUpdateTickers) do
        self:DumpDelegate(v)
    end

    g_Logger.Log("dump secondTickers length: " .. #self.secondTickers)
    for k, v in pairs(self.secondTickers) do
        self:DumpDelegate(v)
    end

    g_Logger.Log("dump frameTickers length: " .. #self.frameTickers)
    for k, v in pairs(self.frameTickers) do
        self:DumpDelegate(v)
    end

    g_Logger.Log("dump ignoreInvervalFrameTickers length : " .. #self.ignoreInvervalFrameTickers)
    for k, v in pairs(self.ignoreInvervalFrameTickers) do
        self:DumpDelegate(v)
    end
end

function Game:DumpDelegate(closure)
    local info = debug.getinfo(closure, "f")
	local funcName, func = debug.getupvalue(info.func, 1)
	local funcInfo = debug.getinfo(func, "S");
	g_Logger.Log(string.format("%s:%d", funcInfo.short_src, funcInfo.linedefined));
end

function Game:ClearWatcherGlobalFields()
    google = nil
    __OnChanged = nil
    __OnChangedAddRemove = nil
    __GetComponent = nil
    __OnNewViewEveryTime = nil
    __OnNewView = nil
    __OnDestroyViewEveryTime = nil
    __OnDestroyView = nil
    RepeatedField = nil
    MapField = nil
    wds = nil
    wrpc = nil
    rpc = nil
end

function Game:ExtremeGCStrategy()
    local stepMul = collectgarbage("setstepmul", 1000)
    g_Logger.TraceChannel("GCSetting", "Last GC StepMul: %d", stepMul)
    local puase = collectgarbage("setpause", 100)
    g_Logger.TraceChannel("GCSetting", "Last GC Pause: %d", puase)
end

function Game:RelaxedGCStrategy()
    local stepMul = collectgarbage("setstepmul", 200)
    g_Logger.TraceChannel("GCSetting", "Last GC StepMul: %d", stepMul)
    local puase = collectgarbage("setpause", 200)
    g_Logger.TraceChannel("GCSetting", "Last GC Pause: %d", puase)
end

function Game.AddToLoadedMap(k, v)
    if LoadedMap[k] then
        return
    end
    LoadedMap[k] = v
end

return Game.new()
