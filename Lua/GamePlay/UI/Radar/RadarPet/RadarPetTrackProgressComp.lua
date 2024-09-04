local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')

---@class RadarPetTrackProgressComp : BaseUIComponent
---@field data HeroConfigCache
local RadarPetTrackProgressComp = class('RadarPetTrackProgressComp', BaseUIComponent)

function RadarPetTrackProgressComp:ctor()

end

function RadarPetTrackProgressComp:OnCreate()
    self.p_img_point = self:Image('p_img_point')
    self.vfx = self:BindComponent("p_img_point", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function RadarPetTrackProgressComp:OnClose()
end

function RadarPetTrackProgressComp:OnFeedData(param)
    g_Game.SpriteManager:LoadSprite("sp_radar_icon_bar_a", self.p_img_point)
    if param.fill and param.isLast then
        -- self.p_img_point:SetVisible(false)
        -- TimerUtility.DelayExecute(function()
            self.p_img_point:SetVisible(true)
            self.vfx:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        -- end, 0.8)
    else
        self.vfx:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self.p_img_point:SetVisible(param.fill)
        self.p_img_point.transform.localScale = CS.UnityEngine.Vector3.one
    end
end

return RadarPetTrackProgressComp
