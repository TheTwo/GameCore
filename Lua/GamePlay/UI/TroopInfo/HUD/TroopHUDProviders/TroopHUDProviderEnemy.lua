local TroopHUDAbstractProvider = require('TroopHUDAbstractProvider')
local SlgUtils = require('SlgUtils')

---@class TroopHUDProviderEnemy : TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDProviderEnemy
local TroopHUDProviderEnemy = class("TroopHUDProviderEnemy",TroopHUDAbstractProvider)

function TroopHUDProviderEnemy:ctor(hud)
    TroopHUDAbstractProvider.ctor(self,hud)
end

function TroopHUDProviderEnemy:Init()
    
end

function TroopHUDProviderEnemy:CheckState()
    if not self.ctrl then return self.hud.State.Hide end
    local troopData = self.ctrl._data  
    local battleState = troopData.MapStates.Battling or troopData.MapStates.Attacking
    if battleState and self.hud.battleRelation or self.hud.isInGve then
        return self.hud.State.InBattle
    else
        if self.ctrl:IsSelected() then
            return self.hud.State.Select
        else            
            return self.hud.State.Normal
        end
    end
end

function TroopHUDProviderEnemy:OnState_Normal()
     self.hud:SetHeroIconImgVisible(false,SlgUtils.TroopType.Enemy)
     self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.Enemy)  
     self.hud.hpGo:SetVisible(false)
     self.hud.hpValueText:SetVisible(false)       
end

function TroopHUDProviderEnemy:OnState_Battle()
    local troopType = SlgUtils.TroopType.Enemy
    self.hud:SetHeroIconImgVisible(true,troopType)        
    self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.Enemy)
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)    
end

function TroopHUDProviderEnemy:OnState_Selected()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.Enemy)
    self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.Enemy)  
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)        
end


function TroopHUDProviderEnemy:OnState_MulitSelected()
    --Hide
end

function TroopHUDProviderEnemy:OnState_BigMap()
   --Hide All   
end

function TroopHUDProviderEnemy:OnLODChanged(oldOverMax, newOverMax)
    self.hud:UpdateTitle()
end

return TroopHUDProviderEnemy