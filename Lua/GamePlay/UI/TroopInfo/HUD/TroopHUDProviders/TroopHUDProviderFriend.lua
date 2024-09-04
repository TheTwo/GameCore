local TroopHUDAbstractProvider = require('TroopHUDAbstractProvider')
local SlgUtils = require('SlgUtils')

---@class TroopHUDProviderFriend : TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDProviderFriend
local TroopHUDProviderFriend = class("TroopHUDProviderFriend",TroopHUDAbstractProvider)

function TroopHUDProviderFriend:ctor(hud)
    TroopHUDAbstractProvider.ctor(self,hud)
end

function TroopHUDProviderFriend:CheckState()

end

function TroopHUDProviderFriend:Init()
    
end

function TroopHUDProviderFriend:CheckState()
    if not self.ctrl then return self.hud.State.Hide end
    local troopData = self.ctrl._data  
    local battleState = troopData.MapStates.Battling or troopData.MapStates.Attacking
   if battleState and self.hud.battleRelation or self.hud.isInGve then
        return self.hud.State.InBattle
    else
        local viewer = self.ctrl:GetTroopView()
        if self.ctrl:IsSelected() or viewer.isFocus then
            return self.hud.State.Select       
        else
            return self.hud.State.Normal
        end
    end
    return self.hud.State.Hide    
end

function TroopHUDProviderFriend:OnState_Normal()
    self.hud:SetHeroIconImgVisible(false)            
    self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.Friend)  
    self.hud.hpGo:SetVisible(false)
    self.hud.hpValueText:SetVisible(false)
end

function TroopHUDProviderFriend:OnState_Battle()
    local troopType = SlgUtils.TroopType.Friend
    self.hud:SetHeroIconImgVisible(false)            
    self.hud:SetTroopNameTxtVisible(true,troopType)
    self.hud.hpGo:SetVisible(false)
    self.hud.hpValueText:SetVisible(false)
    
end

function TroopHUDProviderFriend:OnState_Selected()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.Friend)
    self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.Friend)
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)    
end


function TroopHUDProviderFriend:OnState_MulitSelected()
    --Hide
end

function TroopHUDProviderFriend:OnState_BigMap()
   --Hide All
end

function TroopHUDProviderFriend:OnLODChanged(oldOverMax, newOverMax)
    self.hud:UpdateTitle()
end

return TroopHUDProviderFriend