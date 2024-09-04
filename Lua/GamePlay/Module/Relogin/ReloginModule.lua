local BaseModule = require ('BaseModule')
local Delegate = require('Delegate')
local StateMachine = require("StateMachine")

---@class ReloginModule:BaseModule
local ReloginModule = class('ReloginModule', BaseModule)
local ReconnectResetConnectState = require("ReconnectResetConnectState")
local ReconnectSelectServerState = require("ReconnectSelectServerState")
local ReconnectReloginRetryState = require("ReconnectReloginRetryState")
local ReconnectSuccessState = require("ReconnectSuccessState")

function ReloginModule:OnRegister()
    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState("ReconnectResetConnectState", ReconnectResetConnectState.new())
    self.stateMachine:AddState("ReconnectSelectServerState", ReconnectSelectServerState.new())
    self.stateMachine:AddState("ReconnectReloginRetryState", ReconnectReloginRetryState.new())
    self.stateMachine:AddState("ReconnectSuccessState", ReconnectSuccessState.new())
    self.allowRelogin = true
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    self.runtimeId = g_Game.UIManager:Open("LightRestartBlockUIMediator")
end

function ReloginModule:OnRemove()
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    self.stateMachine:ClearAllStates()
    g_Game.UIManager:Close(self.runtimeId)
    self.runtimeId = nil
end

function ReloginModule:TryReconnect()
    if not self.allowRelogin then
        g_Game.ServiceManager:RestartForOnDisconnected()
        return
    end

    local currentName = self.stateMachine:GetCurrentStateName()
    if currentName ~= nil then
        g_Logger.ErrorChannel("ReloginModule", "Re-login undergoing, current state : %s", currentName)
        return
    end

    g_Game.ServiceManager.blockMsgSend = true
    g_Game.blockNonSystemTicker = true
    self.stateMachine:ChangeState("ReconnectResetConnectState")
end

function ReloginModule:OnSecondTick(delta)
    self.stateMachine:Tick(delta)
end

return ReloginModule