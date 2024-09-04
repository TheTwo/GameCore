---@class TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDAbstractProvider
---@field hud TroopHUD
---@field ctrl TroopCtrl
local TroopHUDAbstractProvider = class("TroopHUDAbstractProvider")

function TroopHUDAbstractProvider:ctor(hud)
    self.hud = hud    
    self.ctrl = hud and hud.ctrl or nil  
end

function TroopHUDAbstractProvider:Init()
end

function TroopHUDAbstractProvider:CheckState()
end

function TroopHUDAbstractProvider:OnState_Normal()
end

function TroopHUDAbstractProvider:OnState_Battle()
end

function TroopHUDAbstractProvider:OnState_Selected()
end


function TroopHUDAbstractProvider:OnState_MulitSelected()
end

function TroopHUDAbstractProvider:OnState_BigMap()
end

function TroopHUDAbstractProvider:OnLODChanged(oldOverMax, newOverMax)
end

function TroopHUDAbstractProvider:OnUpdate()
end

return TroopHUDAbstractProvider