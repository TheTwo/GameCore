local State = require("State")
---@class ReconnectResetConnectState:State
local ReconnectResetConnectState = class("ReconnectResetConnectState", State)
local Delegate = require("Delegate")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local SdkCrashlytics = require("SdkCrashlytics")

function ReconnectResetConnectState:Enter()
    SdkCrashlytics.RecordCrashlyticsLog("ReconnectResetConnectState:Enter")
    g_Game.EventManager:TriggerEvent(EventConst.RELOGIN_START)
    if g_Game.ServiceManager.connect then
        g_Game.ServiceManager.connect:Dispose()
        g_Game.ServiceManager.connect = nil
    end
    g_Game.ServiceManager:AddConnectCallback(Delegate.GetOrCreate(self, self.OnConnect))

    self.retryTimes = 5
    self.retryDelay = 5
    self.waitConnecting = true

    local summary = g_Game.ServiceManager.statusSummary
    self.addr, self.port, self.svrName, self.clientType = summary.Addr, summary.Port, summary.SvrName, summary.ClientType
    g_Game.ServiceManager:Connect(self.addr, self.port, self.svrName, self.clientType)
    g_Logger.TraceChannel("ReloginModule", "重新连接WatcherConnection")
end

function ReconnectResetConnectState:Exit()
    -- UIHelper.RemoveFullScreenLock()
    self.waitConnecting = false
    g_Game.ServiceManager:RemoveConnectCallback(Delegate.GetOrCreate(self, self.OnConnect))
end

function ReconnectResetConnectState:Tick(deltaTime)
    if not self.waitConnecting then return end

    self.retryDelay = self.retryDelay - math.min(0.033, deltaTime)
    if self.retryDelay <= 0 then
        self:Retry()
    end
end

function ReconnectResetConnectState:OnConnect()
    g_Game.DatabaseManager:ClearEntities()
    g_Logger.TraceChannel("ReloginModule", "WatcherConnection Handshake Success")
    self.stateMachine:ChangeState("ReconnectSelectServerState")
end

function ReconnectResetConnectState:Retry()
    if self.retryTimes > 0 then
        g_Logger.LogChannel("ReloginModule", "Re-connect Failed, will retry soon")
        self.retryTimes = self.retryTimes - 1
        self.retryDelay = 5
        g_Game.ServiceManager.connect:Dispose()
        g_Game.ServiceManager.connect = nil
        g_Game.ServiceManager:Connect(self.addr, self.port, self.svrName, self.clientType)
    else
        g_Logger.LogChannel("ReloginModule", "Re-connect Failed, failure times exceed limit, will restart game soon")
        g_Game.EventManager:TriggerEvent(EventConst.RELOGIN_FAILURE)
        g_Game.ServiceManager:RestartForOnDisconnected()
        g_Game.ModuleManager:RemoveModule('ReloginModule')
    end
end

function ReconnectResetConnectState:LockScreenOverMinite()
    UIHelper.RemoveFullScreenLock()
    g_Game.ServiceManager:RestartForOnDisconnected()
end

return ReconnectResetConnectState