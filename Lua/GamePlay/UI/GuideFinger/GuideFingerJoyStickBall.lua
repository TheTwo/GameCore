local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
---@class GuideFingerJoyStickBall : BaseUIMediator
local GuideFingerJoyStickBall = class('GuideFingerJoyStickBall', BaseUIMediator)

function GuideFingerJoyStickBall:ctor()
end

function GuideFingerJoyStickBall:OnShow()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GuideFingerJoyStickBall:OnHide()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GuideFingerJoyStickBall:OnCreate(param)
    self.p_text_hint = self:Text("p_text_hint", "guide_des_yaogan2")
end

function GuideFingerJoyStickBall:Tick()
    if CS.UnityEngine.Input.anyKeyDown then
        self:CloseSelf()
    end
end

return GuideFingerJoyStickBall