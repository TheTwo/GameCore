local BaseUIComponent = require ('BaseUIComponent')
local ArtResourceUIConsts = require('ArtResourceUIConsts')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local UIHelper = require('UIHelper')
---@class GvEBossInfoAngeDot : BaseUIComponent
local GvEBossInfoAngeDot = class('GvEBossInfoAngerDot', BaseUIComponent)

GvEBossInfoAngeDot.State = {
    Sleep = 1,
    Active = 2,
    Idle = 3,
}

function GvEBossInfoAngeDot:ctor()
end

function GvEBossInfoAngeDot:OnCreate()    
    self.rectTrans = self:RectTransform('')
    self.imgIconSleep = self:Image('p_icon_gray')
    self.imgIconActive = self:Image('p_icon_glow')
    self.imgIconIdle = self:Image('p_icon_past')
    self.animTrigger = self:AnimTrigger('p_dot_vx_trigger')
    
end


function GvEBossInfoAngeDot:SetupDot(posX,iconType)
    local pos = self.rectTrans.anchoredPosition
    pos.x  = posX
    self.rectTrans.anchoredPosition = pos
    local sleepIcon = "sp_behemoth_icon_anger_glow"
    local activeIcon = 'sp_behemoth_icon_anger_glow'
    local idleIcon = 'sp_behemoth_icon_anger_past'
    if iconType == 2 then
        sleepIcon = "sp_behemoth_icon_anger_finisher" --ArtResourceUIConsts.sp_comp_icon_monster
        activeIcon = "sp_behemoth_icon_anger_finisher" -- ArtResourceUIConsts.sp_comp_icon_monster
        idleIcon = "sp_behemoth_icon_anger_finisher_past"  --ArtResourceUIConsts.sp_comp_icon_monster    
        
        g_Game.SpriteManager:LoadSprite(sleepIcon,self.imgIconSleep)
        g_Game.SpriteManager:LoadSprite(activeIcon,self.imgIconActive)
        g_Game.SpriteManager:LoadSprite(idleIcon,self.imgIconIdle)
    end
    UIHelper.SetGray(self.imgIconSleep.gameObject,true)
end

function GvEBossInfoAngeDot:SetState(state)
    self._curState = state
    if state == GvEBossInfoAngeDot.State.Sleep then
        self.imgIconSleep:SetVisible(true)
        self.imgIconIdle:SetVisible(false)
        self.imgIconActive:SetVisible(false)
    elseif state == GvEBossInfoAngeDot.State.Active then
        self.imgIconSleep:SetVisible(false)
        self.imgIconIdle:SetVisible(false)
        self.imgIconActive:SetVisible(true)        
    elseif state == GvEBossInfoAngeDot.State.Idle then
        self.imgIconSleep:SetVisible(false)
        self.imgIconIdle:SetVisible(true)
        self.imgIconActive:SetVisible(false)
    end
end

function GvEBossInfoAngeDot:GetState()
    return self._curState
end

---为了方便动画同步，这里由上级调用
---@param event FpAnimTriggerEvent
function GvEBossInfoAngeDot:PlayFpAnim(event)
    self.animTrigger:PlayAll(event)
end

return GvEBossInfoAngeDot
