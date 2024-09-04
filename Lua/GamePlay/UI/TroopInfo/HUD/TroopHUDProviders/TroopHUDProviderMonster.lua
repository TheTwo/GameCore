local TroopHUDAbstractProvider = require('TroopHUDAbstractProvider')
local SlgUtils = require('SlgUtils')
local ModuleRefer = require('ModuleRefer')
local MapHUDFadeDefine = require('MapHUDFadeDefine')

---@class TroopHUDProviderMonster : TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDProviderMonster
local TroopHUDProviderMonster = class("TroopHUDProviderMonster",TroopHUDAbstractProvider)

function TroopHUDProviderMonster:ctor(hud)
    TroopHUDAbstractProvider.ctor(self,hud)
end

function TroopHUDProviderMonster:Init()       
    self.hud:GetHeroHeight()
    self.hud:SetupDeadWaring()
    self.hud:SetupBottomLevel()
    self.hud:SetupRadarBubble()
    self._isInCity = ModuleRefer.SlgModule:IsInCity()
end

function TroopHUDProviderMonster:CheckState()
    if not self.ctrl then return self.hud.State.Hide end
    local troopData = self.ctrl._data  
    local battleState = troopData.MapStates.Battling or troopData.MapStates.Attacking
    if battleState and self.hud.battleRelation or self.hud.isInGve then
        return self.hud.State.InBattle
    else
        if self.ctrl:IsSelected() and not self._isInCity then
            return self.hud.State.Select
        else            
            return self.hud.State.Hide
        end
    end
end

function TroopHUDProviderMonster:OnState_Normal()
    self.hud:SetHeroIconImgVisible(false,SlgUtils.TroopType.Monster)
    self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.Monster)
    self.hud.hpGo:SetVisible(false)
    self.hud.hpValueText:SetVisible(false)     
end

function TroopHUDProviderMonster:OnState_Battle()
    local troopType = SlgUtils.TroopType.Monster
    if  self.hud.showingWarning then
         self.hud:SetHeroIconImgVisible(false,troopType)
         self.hud.burstGo:SetVisible(true)
         self.hud:SetTroopNameTxtVisible(false)
         self.hud.burstTimer.fillAmount = 0
    else
         self.hud:SetHeroIconImgVisible(true,troopType)
         self.hud.burstGo:SetVisible(false)
         self.hud:SetTroopNameTxtVisible(false)
    end
    self.hud.hpGo:SetVisible(true)   
    self.hud.hpValueText:SetVisible(true)     
    self.hud:TickBurstTimer()    
end

function TroopHUDProviderMonster:OnState_Selected()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.Monster)
    self.hud:SetTroopNameTxtVisible(false)
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)     
end


function TroopHUDProviderMonster:OnState_MulitSelected()
    --Hide
end

function TroopHUDProviderMonster:OnState_BigMap()
    --Hide All
end

function TroopHUDProviderMonster:OnLODChanged(oldOverMax, newOverMax)

    if not self.hud.hideAll then        
        self.hud:OnLODChanged_MobBottomLevel(oldOverMax, newOverMax)
        self.hud:TryShowRadarTaskBubble()
    else
        if self.showEventMark then 
            self.eventMarkSetter:ResetMaterial() 
            self.eventMark.gameObject:SetVisible(false)
        end
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.FadeOut)
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.FadeOut)            
    end

    self.hud:UpateRadarBubble()
    self.hud:UpdateWorldEventMark()
end

return TroopHUDProviderMonster