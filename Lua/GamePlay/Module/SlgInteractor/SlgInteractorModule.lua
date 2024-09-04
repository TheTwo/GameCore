local BaseModule = require('BaseModule')
local ProtocolId = require("ProtocolId")
local Delegate = require('Delegate')
local EventConst = require('EventConst')

---@class SlgInteractorModule
local SlgInteractorModule = class('SlgInteractorModule', BaseModule)

function SlgInteractorModule:ctor()

end

function SlgInteractorModule:OnRegister()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.CallBackInteract, Delegate.GetOrCreate(self, self.PushCallBackInteract))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.OneInteractEnd, Delegate.GetOrCreate(self, self.PushOneInteract))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.AllInteractEnd, Delegate.GetOrCreate(self, self.PushEndInteract))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.BreakInteract, Delegate.GetOrCreate(self, self.PushBreakInteract))
end

function SlgInteractorModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.CallBackInteract, Delegate.GetOrCreate(self, self.PushCallBackInteract))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.OneInteractEnd, Delegate.GetOrCreate(self, self.PushOneInteract))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.AllInteractEnd, Delegate.GetOrCreate(self, self.PushEndInteract))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.BreakInteract, Delegate.GetOrCreate(self, self.PushBreakInteract))
end

function SlgInteractorModule:PushCallBackInteract(isSucceed, msg)
    if not isSucceed then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_SLG_START_INTREACTOR, msg)
end

function SlgInteractorModule:PushOneInteract(isSucceed, msg)
    if not isSucceed then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_SLG_END_ONCE_INTREACTOR, msg)
end

function SlgInteractorModule:PushEndInteract(isSucceed, msg)
    if not isSucceed then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_SLG_END_ALL_INTREACTOR, msg)
end

function SlgInteractorModule:PushBreakInteract(isSucceed, msg)
    if not isSucceed then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_SLG_BREAK_ALL_INTREACTOR, msg)
end

return SlgInteractorModule
