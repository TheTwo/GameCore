---scene: scene_hud_explore_end_guide
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
---@class GuideFingerSlideMediator:BaseUIMediator
local GuideFingerSlideMediator = class("GuideFingerSlideMediator", BaseUIMediator)

function GuideFingerSlideMediator:OnShow()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
end

function GuideFingerSlideMediator:OnHide()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
end

function GuideFingerSlideMediator:Update()
    if CS.UnityEngine.Input.anyKey then
        self:CloseSelf()
    end
end

return GuideFingerSlideMediator