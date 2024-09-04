local State = require("State")
---@class ReconnectReloginRetryState:State
local ReconnectReloginRetryState = class("ReconnectReloginRetryState", State)
local EventConst = require("EventConst")
local LoginParameter = require("LoginParameter")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local UIHelper = require("UIHelper")
local SdkCrashlytics = require("SdkCrashlytics")

function ReconnectReloginRetryState:Enter()
    SdkCrashlytics.RecordCrashlyticsLog("ReconnectReloginRetryState:Enter")
    self.retryTimes = 5
    self.timeoutSeconds = 10
    self.waitResponse = true
    self:TryReconnectImp()

    g_Game.ServiceManager:AddResponseCallback(LoginParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnReloginCallback))
    -- UIHelper.AddFullScreenLock(60, Delegate.GetOrCreate(self, self.LockScreenOverMinite))
end

function ReconnectReloginRetryState:Exit()
    -- UIHelper.RemoveFullScreenLock()
    g_Game.ServiceManager:RemoveResponseCallback(LoginParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnReloginCallback))
end

function ReconnectReloginRetryState:Tick(deltaTime)
    if self.nextRetry then
        self.nextRetry = self.nextRetry - 1
        if self.nextRetry <= 0 then
            self.nextRetry = nil
            self:TryReconnectImp()
        end
    end

    if not self.waitResponse then return end
    
    self.timeoutSeconds = self.timeoutSeconds - math.min(0.033, deltaTime)
    if self.timeoutSeconds <= 0 then
        self:OnReconnectFailed()
    end
end

function ReconnectReloginRetryState:TryReconnectImp()
    local login = LoginParameter.new()
    local ConfigBranch, ConfigRevision = g_Game.ConfigManager:GetRemoteConfigVersion()
    login.args.Param.account = g_Game.ServiceManager.accountId
    login.args.Param.token = self:GetToken()
    login.args.Param.fingerPrint = g_Game.ServiceManager.connect:GetFingerPrint()
    login.args.Param.clientVersion = ModuleRefer.AppInfoModule:VersionName()
    login.args.Param.gpuname = CS.UnityEngine.Device.SystemInfo.graphicsDeviceName
    login.args.Param.version.ProtocolCommitHash = require("protocol_version").CommitHash
    login.args.Param.version.ConfigBranch = ConfigBranch
    login.args.Param.version.ConfigRevision = checknumber(ConfigRevision)

    -- 跳过新手
    if ModuleRefer.AppInfoModule:SkipNewbie() then
        login.args.Param.funcMask = 1 << wrpc.LoginFuncType.LoginFuncTypeIgnoreNewbie
    end

    login.args.Param.funcMask = login.args.Param.funcMask | (1 << wrpc.LoginFuncType.LoginFuncTypeReconnect)

    if g_Game.debugSupportOn then
        login.args.Param.internalAuth = wrpc.InternalRealNameAuth()

        local hasSafeId, safeId = RuntimeDebugSettings:GetString('safe_id')
        if hasSafeId then
            login.args.Param.internalAuth.UserName = safeId
        end

        local hasSafePassword, safePassword = RuntimeDebugSettings:GetString('safe_password')
        if hasSafePassword then
            login.args.Param.internalAuth.Password = CS.Md5Utils.GetMd5ByString(safePassword)
        end
    end
    
    g_Logger.LogChannel("ReloginModule", "Reconnnecting..., retry times : %d", self.retryTimes)
    
    login:Send(nil, login.args.Param.version.ProtocolCommitHash, true, Delegate.GetOrCreate(self, self.OnReconnectFailed))
end

function ReconnectReloginRetryState:OnReconnectFailed(msgId, code, simpleError)
    if self.retryTimes > 0 then
        g_Logger.LogChannel("ReloginModule", "Re-login Failed, will retry soon")
        self.waitResponse = false
        self.retryTimes = self.retryTimes - 1
        self.nextRetry = 3
        self.timeoutSeconds = 30
    else
        g_Logger.LogChannel("ReloginModule", "Re-login Failed, failure times exceed limit, will restart game soon")
        self.waitResponse = false
        g_Game.EventManager:TriggerEvent(EventConst.RELOGIN_FAILURE)
        g_Game.ServiceManager:RestartForOnDisconnected()
        g_Game.ModuleManager:RemoveModule('ReloginModule')
    end
end


function ReconnectReloginRetryState:OnReloginCallback(isSuccess, reply, abstractRpc)
    if isSuccess then
        g_Logger.LogChannel("ReloginModule", "Re-login Successfully")
        self.waitResponse = false
        self.stateMachine:ChangeState("ReconnectSuccessState")
    else
        self:OnReconnectFailed()
    end
end

function ReconnectReloginRetryState:GetToken()
    if g_Game.debugSupportOn then
        local has, customToken = RuntimeDebugSettings:GetOverrideToken()
        if has and not string.IsNullOrEmpty(customToken) then
            RuntimeDebugSettings:ClearOverrideToken()
            return customToken
        end
    end
    return g_Game.ServiceManager.token
end

function ReconnectReloginRetryState:LockScreenOverMinite()
    UIHelper.RemoveFullScreenLock()
    g_Game.ServiceManager:RestartForOnDisconnected()
end

return ReconnectReloginRetryState