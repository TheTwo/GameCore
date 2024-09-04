local TroopHUDAbstractProvider = require('TroopHUDAbstractProvider')

---@class TroopHUDProviderMobileFortress : TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDProviderMobileFortress
local TroopHUDProviderMobileFortress = class("TroopHUDProviderMobileFortress",TroopHUDAbstractProvider)

function TroopHUDProviderMobileFortress:ctor(hud)
    TroopHUDAbstractProvider.ctor(self,hud)
end
function TroopHUDProviderMobileFortress:CheckState()
end
function TroopHUDProviderMobileFortress:Init()    
    self.hud:SetupAllianceBehemothBottomLevel()    
end

function TroopHUDProviderMobileFortress:CheckState()
    if not self.ctrl then return self.hud.State.Hide end
    local troopData = self.ctrl._data  
    local battleState = troopData.MapStates.Battling or troopData.MapStates.Attacking
    if self.ctrl:IsSelected() and not self._isInCity then
        return self.hud.State.Select
    elseif battleState then
        return self.hud.State.InBattle
    else
        return self.hud.State.Normal
    end
end

function TroopHUDProviderMobileFortress:OnState_Normal()
    local troopType = self.ctrl.troopType
    self.hud:SetHeroIconImgVisible(false)              
    self.hud:SetBehemothNameTxtVisible(true,troopType)  
    self.hud.hpGo:SetVisible(false)
    self.hud.hpValueText:SetVisible(false)
end

function TroopHUDProviderMobileFortress:OnState_Battle()
    local troopType = self.ctrl.troopType
    self.hud:SetHeroIconImgVisible(false)           
    self.hud:SetBehemothNameTxtVisible(true,troopType)     
    self.hud.hpGo:SetVisible(false)
    self.hud.hpValueText:SetVisible(false)
end

function TroopHUDProviderMobileFortress:OnState_Selected()
    local troopType = self.ctrl.troopType
    self.hud:SetHeroIconImgVisible(true,troopType)      
    self.hud:SetBehemothNameTxtVisible(true,troopType)
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)
end


function TroopHUDProviderMobileFortress:OnState_MulitSelected()
    --Hide
end

function TroopHUDProviderMobileFortress:OnState_BigMap()  
    --Hide All
end

function TroopHUDProviderMobileFortress:OnLODChanged(oldOverMax, newOverMax)
    self.hud:OnLODChanged_BehemothBottomLevel(oldOverMax, newOverMax)
end

return TroopHUDProviderMobileFortress