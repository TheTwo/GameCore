local State = require("State")
---@class ReconnectSelectServerState:State
---@field new fun():ReconnectSelectServerState
local ReconnectSelectServerState = class("ReconnectSelectServerState", State)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local DeviceUtil = require("DeviceUtil")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local SdkCrashlytics = require("SdkCrashlytics")

function ReconnectSelectServerState:Enter()
    SdkCrashlytics.RecordCrashlyticsLog("ReconnectSelectServerState:Enter")
    g_Game.EventManager:AddListener(EventConst.LOGIN_SELECT_SERVER_REQUEST, Delegate.GetOrCreate(self, self.OnSelectServerResponse))
    self:SelectServer()
    -- UIHelper.AddFullScreenLock(60, Delegate.GetOrCreate(self, self.LockScreenOverMinite))
    g_Logger.TraceChannel("ReloginModule", "Start Select Server")
end

function ReconnectSelectServerState:Exit()
    -- UIHelper.RemoveFullScreenLock()
    g_Game.EventManager:RemoveListener(EventConst.LOGIN_SELECT_SERVER_REQUEST, Delegate.GetOrCreate(self, self.OnSelectServerResponse))
end

function ReconnectSelectServerState:SelectServer()
    local requestJsonTable = {
        Account = tostring(g_Game.ServiceManager.accountId),
        Platform = DeviceUtil.GetCurrentPlatform(),
        Version = ModuleRefer.AppInfoModule:VersionName(),
    }
    local rapidJson = require("rapidjson")
    local requestJson = rapidJson.encode(requestJsonTable)
    g_Game.ServiceManager:SelectServerRequest(requestJson)
    g_Logger.TraceChannel("ServiceManager", "Send SelectServerRequest")
end

function ReconnectSelectServerState:OnSelectServerResponse()
    self.stateMachine:ChangeState("ReconnectReloginRetryState")
    g_Logger.TraceChannel("ReloginModule", "Select Server Success")
end

return ReconnectSelectServerState