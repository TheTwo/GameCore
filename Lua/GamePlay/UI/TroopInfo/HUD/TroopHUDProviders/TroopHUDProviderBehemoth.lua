local TroopHUDAbstractProvider = require('TroopHUDAbstractProvider')
local ModuleRefer = require('ModuleRefer')
local MapHUDFadeDefine = require('MapHUDFadeDefine')

---@class TroopHUDProviderBehemoth : TroopHUDAbstractProvider
---@field new fun(hud:TroopHUD):TroopHUDProviderBehemoth
local TroopHUDProviderBehemoth = class("TroopHUDProviderBehemoth",TroopHUDAbstractProvider)

function TroopHUDProviderBehemoth:ctor(hud)
    TroopHUDAbstractProvider.ctor(self,hud)
end

function TroopHUDProviderBehemoth:Init()
    self.hud:SetupBottomLevel()
end

function TroopHUDProviderBehemoth:CheckState()
    -- if not self.ctrl then return self.hud.State.Hide end
    -- local troopData = self.ctrl._data         
    -- local battleState = troopData.MapStates.Battling or troopData.MapStates.Attacking
    return self.hud.State.Hide
end
function TroopHUDProviderBehemoth:OnState_Normal()
    --Hide()
end

function TroopHUDProviderBehemoth:OnState_Battle()
    --Hide()
end

function TroopHUDProviderBehemoth:OnState_Selected()
    --Hide()
end


function TroopHUDProviderBehemoth:OnState_MulitSelected()
    --Hide
end

function TroopHUDProviderBehemoth:OnState_BigMap()
   --Hide All
end

function TroopHUDProviderBehemoth:OnLODChanged(oldOverMax, newOverMax)
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

return TroopHUDProviderBehemoth