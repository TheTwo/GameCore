local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
---@class GuideFingerJoyStickMove : BaseUIMediator
local GuideFingerJoyStickMove = class('GuideFingerJoyStickMove', BaseUIMediator)

function GuideFingerJoyStickMove:ctor()
end

function GuideFingerJoyStickMove:OnShow()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GuideFingerJoyStickMove:OnHide()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GuideFingerJoyStickMove:OnCreate(param)
    self.p_text_hint = self:Text("p_text_hint", "guide_des_yaogan1")
end

function GuideFingerJoyStickMove:Tick()
    if CS.UnityEngine.Input.anyKeyDown then
        self:CloseSelf()
    end
end

return GuideFingerJoyStickMove