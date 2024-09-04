local State = require("State")
---@class ReconnectSuccessState:State
local ReconnectSuccessState = class("ReconnectSuccessState", State)
local ProtocolId = require("ProtocolId")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local SdkCrashlytics = require("SdkCrashlytics")
local SendClientDataReadyReParameter = require("SendClientDataReadyReParameter")

function ReconnectSuccessState:Enter()
    SdkCrashlytics.RecordCrashlyticsLog("ReconnectSuccessState:Enter")
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.SendClientDataReady, Delegate.GetOrCreate(self, self.OnSendClientDataReady))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushEnterScene, Delegate.GetOrCreate(self, self.OnPushEnterScene))
end

function ReconnectSuccessState:Exit()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushEnterScene, Delegate.GetOrCreate(self, self.OnPushEnterScene))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SendClientDataReady, Delegate.GetOrCreate(self, self.OnSendClientDataReady))
end

function ReconnectSuccessState:OnSendClientDataReady(isSuccess, wrpc)
    local param = SendClientDataReadyReParameter.new()
    param.args.Timestamp = g_Game.ServerTime:GetServerTimestampInSeconds()
    param:Send()
    g_Logger.TraceChannel("ReloginModule", "Send ClientDataReady")
end

function ReconnectSuccessState:OnPushEnterScene()
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Tip)

    g_Game.EventManager:TriggerEvent(EventConst.RELOGIN_SUCCESS)
    g_Game.ServiceManager.blockMsgSend = false
    g_Game.ServiceManager:RemoveAllLocker()
    g_Game.blockNonSystemTicker = false
    g_Game.ModuleManager:RemoveModule('ReloginModule')
    g_Logger.TraceChannel("ReloginModule", "Reconnect Finished")
end

return ReconnectSuccessState