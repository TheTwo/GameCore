local TroopHUDAbstractProvider = require('TroopHUDAbstractProvider')
local SlgUtils = require('SlgUtils')
local ModuleRefer = require('ModuleRefer')
---@class TroopHUDProviderMySelf : TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDProviderMySelf
local TroopHUDProviderMySelf = class("TroopHUDProviderMySelf",TroopHUDAbstractProvider)

function TroopHUDProviderMySelf:ctor(hud)
    TroopHUDAbstractProvider.ctor(self,hud)
end

function TroopHUDProviderMySelf:Init()
    
end

function TroopHUDProviderMySelf:CheckState()
    if not self.ctrl then return self.hud.State.Hide end
    local troopData = self.ctrl._data         
    if self.ctrl:IsSelected() then
    local seleCount = ModuleRefer.SlgModule.selectManager:GetSelectCount()

    if seleCount >= 2 then
        return self.hud.State.MulitSelect
    else
        return self.hud.State.Select
    end
    elseif troopData.MapStates.Battling or troopData.MapStates.Attacking then
        return self.hud.State.InBattle
    else
        return self.hud.State.Normal
    end    
end

function TroopHUDProviderMySelf:OnState_Normal()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.MySelf)
    self.hud:SetTroopNameTxtVisible(false)  
    self.hud.hpValueText:SetVisible(false)
end

function TroopHUDProviderMySelf:OnState_Battle()
    
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.MySelf)      
    if self.hud.isInGve then        
        self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.MySelf)        
    else                
        self.hud:SetTroopNameTxtVisible(false)
    end            
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)
    
end

function TroopHUDProviderMySelf:OnState_Selected()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.MySelf)
    self.hud:SetTroopNameTxtVisible(true,SlgUtils.TroopType.MySelf)    
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)
    self.hud:UpdateHPBar()
    self.hud.hpValueText:SetVisible(true)
end


function TroopHUDProviderMySelf:OnState_MulitSelected()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.MySelf)
    self.hud.hpGo:SetVisible(true)
    self.hud.hpValueText:SetVisible(true)
    self.hud:UpdateHPBar()
    self.hud.hpValueText:SetVisible(true)
end

function TroopHUDProviderMySelf:OnState_BigMap()
    self.hud:SetHeroIconImgVisible(true,SlgUtils.TroopType.MySelf)
    self.hud.nameTxt:SetVisible(false)
    self.hud.hpGo:SetVisible(false)
    self.hud.hpValueText:SetVisible(false)
end

function TroopHUDProviderMySelf:OnLODChanged(oldOverMax, newOverMax)
    self.hud:UpdateTitle()
end


return TroopHUDProviderMySelf