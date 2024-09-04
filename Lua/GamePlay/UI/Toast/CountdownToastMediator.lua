--- scene:scene_toast_countdown

local Delegate = require("Delegate")

local BaseUIMediator = require("BaseUIMediator")

---@class CountdownToastMediatorParamter
---@field content string
---@field startCountdownTime number
---@field countdown number
---@field startText string

---@class CountdownToastMediator:BaseUIMediator
---@field new fun():CountdownToastMediator
---@field super BaseUIMediator
local CountdownToastMediator = class('CountdownToastMediator', BaseUIMediator)

function CountdownToastMediator:ctor()
    CountdownToastMediator.super.ctor(self)
    self._isInCountdown = false
    self._countDown = nil
    self._countInt = nil
    self._triggerEnd = false
end

function CountdownToastMediator:OnCreate()
    self._p_icon = self:Image("p_icon")
    self._p_text_content = self:Text("p_text_content")
    self._p_text_countdown = self:Text("p_text_countdown")
    self._p_text_start = self:Text("p_text_start")
    self.vx_trigger = self:BindComponent("vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

---@param param CountdownToastMediatorParamter
function CountdownToastMediator:OnOpened(param)
    self._param = param
    self._p_text_start:SetVisible(false)
    self._p_text_start.text = param.startText
    if string.IsNullOrEmpty(param.content) then
        self._p_text_content:SetVisible(false)
    else
        self._p_text_content:SetVisible(true)
        self._p_text_content.text = param.content
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self._countDown = param.startCountdownTime + param.countdown - nowTime
    self._countInt = math.ceil(self._countDown)
    self._p_text_countdown.text = tostring(self._countInt)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._triggerEnd = false
end

function CountdownToastMediator:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CountdownToastMediator:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CountdownToastMediator:Tick(dt)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self._countDown = self._param.startCountdownTime + self._param.countdown - nowTime
    local countdown = math.ceil(self._countDown)
    if countdown > self._param.countdown then
        self._p_text_countdown:SetVisible(false)
        return
    end
    if self._countInt < countdown then
        return
    end
    if self._countInt <= -1 then
        self:CloseSelf()
        return
    end
    self._countInt = countdown
    if self._countInt <= 0 then
        self._p_text_start:SetVisible(true)
        self._p_text_content:SetVisible(false)
        self._p_text_countdown:SetVisible(false)
        if not self._triggerEnd then
            self._triggerEnd = true
            self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
        end
        return
    end
    self._p_text_content:SetVisible(false)
    self._p_text_countdown:SetVisible(true)
    self._p_text_countdown.text = tostring(self._countInt)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
end

return CountdownToastMediator