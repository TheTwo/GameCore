local RuntimeDebugSettings = require("RuntimeDebugSettings")
local RuntimeDebugSettingsKeyDefine = require("RuntimeDebugSettingsKeyDefine")
local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local LogSeverity = CS.DragonReborn.LogSeverity

---@class GMPagePanelSettings:GMPage
local GMPagePanelSettings = class('GMPagePanelSettings', GMPage)

function GMPagePanelSettings:ctor()
    self.scrollPos = CS.UnityEngine.Vector2.zero
end

function GMPagePanelSettings:OnGUI()
    local panelSettings = self.panel.runTimeSettings
    GUILayout.BeginVertical()
    self.scrollPos = GUILayout.BeginScrollView(self.scrollPos)
    GUILayout.BeginHorizontal()
    GUILayout.BeginVertical()

    local h = GUILayout.Toggle(panelSettings.hideHeader, "隐藏屏幕上的性能信息")
    if h ~= panelSettings.hideHeader then
        panelSettings.hideHeader = h
        if h then
            RuntimeDebugSettings:Delete(RuntimeDebugSettingsKeyDefine.DebugGMHeadersVisible)
        else
            RuntimeDebugSettings:SetInt(RuntimeDebugSettingsKeyDefine.DebugGMHeadersVisible, 1)
        end
    end

    GUILayout.BeginVertical(GUILayout.gui_cs.skin.box)
    local headerNames = self.panel.headerNames
    local headers = self.panel.headers
    local headerCount = #headers
    for i = 1, headerCount do
        local name = headerNames[i]
        local header = headers[i]
        header._display = GUILayout.Toggle(header._display, name)
    end
    GUILayout.EndVertical()

    h = GUILayout.Toggle(panelSettings.hideDebugConsole, "隐藏悬浮Console")
    if h ~= panelSettings.hideDebugConsole then
        panelSettings.hideDebugConsole = h
        if h then
            RuntimeDebugSettings:Delete(RuntimeDebugSettingsKeyDefine.DebugGMRuntimeConsoleVisible)
        else
            RuntimeDebugSettings:SetInt(RuntimeDebugSettingsKeyDefine.DebugGMRuntimeConsoleVisible, 1)
        end
    end
    self:ToggleOffLogType();
    h = GUILayout.Toggle(panelSettings:get_enableServiceLog(), "打开ServiceManager Log")
    if h ~= panelSettings:get_enableServiceLog() then
        panelSettings:set_enableServiceLog(h)
    end
    h = GUILayout.Toggle(panelSettings:get_enableDatabaseLog(), "打开DatabaseManager Log")
    if h ~= panelSettings:get_enableDatabaseLog() then
        panelSettings:set_enableDatabaseLog(h)
    end

    h = GUILayout.Toggle(self:get_enableDebugHierachy(), "是否使用 DebugHierachy")
    if h ~= self:get_enableDebugHierachy() then
        self:set_enableDebugHierachy(h)
    end

    h = GUILayout.Toggle(self:get_testPay(), "是否使用白嫖支付")
    if h ~= self:get_testPay() then
        self:set_testPay(h)
    end

    h = GUILayout.Toggle(self:get_enableUWA(), "是否使用 UWA")
    if h ~= self:get_enableUWA() then
        self:set_enableUWA(h)
    end

    h = GUILayout.Toggle(self:get_enableLuaProfiler(), "是否启用LuaProfiler(非Release包有效)")
    if h ~= self:get_enableLuaProfiler() then
        self:set_enableLuaProfiler(h)
    end

    h = GUILayout.Toggle(self:get_enableProfilerTraceLuaGC(), "是否启用Lua内存分配追踪")
    if h ~= self:get_enableProfilerTraceLuaGC() then
        self:set_enableProfilerTraceLuaGC(h)
    end

    h = GUILayout.Toggle(self:get_enableExceptionRestart(), "是否捕获异常后触发重启")
    if h ~= self:get_enableExceptionRestart() then
        self:set_enableExceptionRestart(h)
    end

    h = GUILayout.Toggle(self:get_reloginWhenKickedOut(), "被踢下线是否触发重登录流程")
    if h ~= self:get_reloginWhenKickedOut() then
        self:set_reloginWhenKickedOut(h)
    end

    h = GUILayout.Toggle(self:get_EnableCastleAttrLog(), "启用CastleAttrLog")
    if h ~= self:get_EnableCastleAttrLog() then
        self:set_EnableCastleAttrLog(h)
    end

    GUILayout.EndVertical()

    GUILayout.BeginVertical()
    GUILayout.Label("网络类型")
    h = GUILayout.Toggle(self:get_isTcpConnection(), "TCP")
    if h ~= self:get_isTcpConnection() and h then
        local ServiceManager = require("ServiceManager")
        self:set_watcherConnectionType(ServiceManager.ClientType.Tcp)
    end
    h = GUILayout.Toggle(self:get_isKcpConnection(), "KCP")
    if h ~= self:get_isKcpConnection() and h then
        local ServiceManager = require("ServiceManager")
        self:set_watcherConnectionType(ServiceManager.ClientType.Kcp)
    end
    h = GUILayout.Toggle(self:get_isMcpConnection(), "MCP")
    if h ~= self:get_isMcpConnection() and h then
        local ServiceManager = require("ServiceManager")
        self:set_watcherConnectionType(ServiceManager.ClientType.Mcp)
    end
    h = GUILayout.Toggle(self:get_isMcpPreferTCP(), "MCP_PreferTCP")
    if h ~= self:get_isMcpPreferTCP() then
        self:set_isMcpPreferTCP(h)
    end
    h = GUILayout.Toggle(self:get_KcpLogEnabled(), "KCP_LOG_ENABLE")
    if h ~= self:get_KcpLogEnabled() then
        self:set_KcpLogEnabled(h)
    end
    GUILayout.EndVertical()
    GUILayout.EndHorizontal()

    GUILayout.EndScrollView()
    GUILayout.EndVertical()
end

function GMPagePanelSettings:get_enableDebugHierachy()
    return g_Game.PlayerPrefsEx:GetInt("GMPanelEnableDebugHierachy") == 1
end

function GMPagePanelSettings:get_enableUWA()
    return g_Game.PlayerPrefsEx:GetInt("GMPanelEnableUWA", 1) == 1
end

function GMPagePanelSettings:set_enableUWA(value)
    g_Game.PlayerPrefsEx:SetInt("GMPanelEnableUWA", value and 1 or 0)
end

function GMPagePanelSettings:get_enableLuaProfiler()
    return g_Game.EnableLuaProfiler
end

function GMPagePanelSettings:set_enableLuaProfiler(value)
    g_Game.EnableLuaProfiler = value
    CS.ScriptEngine.EnableLuaProfiler(value)
end

function GMPagePanelSettings:get_enableProfilerTraceLuaGC()
    return g_Game.EnableProfilerTraceLuaGC
end

function GMPagePanelSettings:set_enableProfilerTraceLuaGC(value)
    g_Game.EnableProfilerTraceLuaGC = value
    CS.ScriptEngine.EnableProfilerTraceLuaGC(value)
end

function GMPagePanelSettings:get_testPay()
    return g_Game.PlayerPrefsEx:GetInt("GMTestPay") == 1
end

function GMPagePanelSettings:set_testPay(value)
    g_Game.PlayerPrefsEx:SetInt("GMTestPay", value and 1 or 0)
end

function GMPagePanelSettings:get_enableExceptionRestart()
    return g_Game.PlayerPrefsEx:GetInt("GMPanelEnableExceptionRestart", 1) == 1
end

function GMPagePanelSettings:set_enableExceptionRestart(value)
    g_Game.PlayerPrefsEx:SetInt("GMPanelEnableExceptionRestart", value and 1 or 0)
end

function GMPagePanelSettings:get_reloginWhenKickedOut()
    return g_Game.ServiceManager.reloginWhenKickout
end

function GMPagePanelSettings:set_reloginWhenKickedOut(value)
    g_Game.ServiceManager.reloginWhenKickout = value
end

function GMPagePanelSettings:get_EnableCastleAttrLog()
    local CityWorkFormula = require("CityWorkFormula")
    return CityWorkFormula.EnableLog
end

function GMPagePanelSettings:set_EnableCastleAttrLog(value)
    local CityWorkFormula = require("CityWorkFormula")
    CityWorkFormula.EnableLogSwitch(value)
end

local debugHierachy
function GMPagePanelSettings:set_enableDebugHierachy(value)
    g_Logger.Log("set_enableDebugHierachy " .. tostring(value))

    g_Game.PlayerPrefsEx:SetInt("GMPanelEnableDebugHierachy", value and 1 or 0)

    if debugHierachy then
        debugHierachy:SetActive(value)
    else
        if value then
            local uiRoot = CS.UnityEngine.GameObject.Find("UIRoot")
            debugHierachy = CS.UnityEngine.GameObject.Instantiate(CS.UnityEngine.Resources.Load("DebugOnly/DebugHierachy", typeof(CS.UnityEngine.GameObject)), uiRoot.transform)
            debugHierachy.name = "DebugHierachy"
        end
    end
end

function GMPagePanelSettings:ToggleOffLogType()
    local dirty = false
    local zero = 0
    local s = CS.DragonReborn.NLogger.GetSeverity():GetHashCode()
    local mask = ~s
    local logMask = 3 --LogSeverity.__CastFrom(3) 1|2 (trace and message)
    local warnMask = 4 --LogSeverity.__CastFrom(4) 4 (warn)
    local errorMask = 24 --LogSeverity.__CastFrom(24) 8|16 (error and assert)
    local logOff = (mask & logMask) ~= zero
    local warnOff = (mask & warnMask) ~= zero
    local errorOff = (mask & errorMask) ~= zero
    if CS.DragonReborn.NLogger.SHOW_STACK_TRACE_IN_LUA() then
        local e = GUILayout.Toggle(g_Logger.tracebackEnable, "log记录Lua调用栈")
        if e ~= g_Logger.tracebackEnable then
            g_Logger.tracebackEnable = e
            CS.UnityEngine.PlayerPrefs.SetInt("SHOW_STACK_TRACE_IN_LUA", e and 1 or 0)
        end
    else
        GUILayout.Toggle(g_Logger.tracebackEnable, "log记录Lua调用栈(编译宏已禁用)")
    end
    local v = GUILayout.Toggle(logOff, "禁用Log级别")
    if v ~= logOff then
        logOff = v
        dirty = true
    end
    v = GUILayout.Toggle(warnOff, "禁用Warn级别")
    if v ~= warnOff then
        warnOff = v
        dirty = true
    end
    v = GUILayout.Toggle(errorOff, "禁用Error级别")
    if v ~= errorOff then
        errorOff = v
        dirty = true
    end
    if dirty then
        s = ~zero
        if logOff then
            s = s & (~logMask)
        end
        if warnOff then
            s = s & (~warnMask)
        end
        if errorOff then
            s = s & (~errorMask)
        end
        CS.DragonReborn.NLogger.SetSeverity(LogSeverity.__CastFrom(s))
    end
end

function GMPagePanelSettings:RestartLuaLuaPanda()
    local panda = require("LuaPanda")
    panda.connectSuccess()
    panda.disconnect()
    panda.start("127.0.0.1",8818)
end

function GMPagePanelSettings:Release()
    self:set_enableDebugHierachy(false)
    if debugHierachy then
        CS.UnityEngine.Object.Destroy(debugHierachy) 
        debugHierachy = nil
    end
end

function GMPagePanelSettings:get_isTcpConnection()
    local ServiceManager = require("ServiceManager")
    local flag, typ = RuntimeDebugSettings:GetConnectionType()
    return flag and typ == ServiceManager.ClientType.Tcp
end

function GMPagePanelSettings:get_isKcpConnection()
    local ServiceManager = require("ServiceManager")
    local flag, typ = RuntimeDebugSettings:GetConnectionType()
    return flag and typ == ServiceManager.ClientType.Kcp
end

function GMPagePanelSettings:get_isMcpConnection()
    local ServiceManager = require("ServiceManager")
    local flag, typ = RuntimeDebugSettings:GetConnectionType()
    return flag and typ == ServiceManager.ClientType.Mcp
end

function GMPagePanelSettings:get_isMcpPreferTCP()
    local flag, preferTcp = RuntimeDebugSettings:GetMcpPreferTCP()
    return flag and preferTcp == 1
end

function GMPagePanelSettings:set_isMcpPreferTCP(flag)
    RuntimeDebugSettings:SetMcpPreferTCP(flag)
    g_Game.ServiceManager:MCPPreferTCP(flag)
end

function GMPagePanelSettings:set_watcherConnectionType(clientType)
    RuntimeDebugSettings:SetConnectionType(clientType)
    g_Game:RestartGame()
end

function GMPagePanelSettings:get_KcpLogEnabled()
    local flag, logEnabled = RuntimeDebugSettings:GetKcpLogEnabled()
    return flag and logEnabled == 1
end

function GMPagePanelSettings:set_KcpLogEnabled(flag)
    RuntimeDebugSettings:SetKcpLogEnabled(flag)
    g_Game.ServiceManager:SetKcpLogEnabled(flag)
end

return GMPagePanelSettings
