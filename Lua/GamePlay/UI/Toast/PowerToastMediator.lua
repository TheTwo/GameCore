local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local EventConst = require('EventConst')
local MathUtils = require('MathUtils')
local TimerUtility = require('TimerUtility')

---@class PowerToastMediator : BaseUIMediator
local PowerToastMediator = class('PowerToastMediator', BaseUIMediator)

local DURATION = 2.5
local Ease = CS.DG.Tweening.Ease

function PowerToastMediator:OnCreate()
    self.textPower = self:Text('p_text_power', "power_entire_breakdown_name")
    self.textPowerAdd = self:Text('p_text_power_add')
    self.vx_trigger = self:AnimTrigger("vx_trigger")
end

function PowerToastMediator:OnShow(param)
    self.goTrail = self:GameObject("vfx_word_event_trail")
    self.goTrail:SetActive(false)
    self.openTime = 0
    self.goTrail.transform:DOKill()
    self.vx_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
        self:PlayMoveEffect()
    end)
    self.textPowerAdd.text = "+" .. param.power
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.UI_POWER_TOAST_REFRESH, Delegate.GetOrCreate(self, self.RefreshText))
end

function PowerToastMediator:OnHide(param)
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
    self.goTrail.transform:DOKill()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.UI_POWER_TOAST_REFRESH, Delegate.GetOrCreate(self, self.RefreshText))
end

function PowerToastMediator:RefreshText(data)
    self.goTrail.transform:DOKill()
    self.vx_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
        self:PlayMoveEffect()
    end)
    self.textPowerAdd.text = "+" .. data.power
    self.openTime = 0
end

function PowerToastMediator:PlayMoveEffect()
    self.goTrail:SetActive(true)
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if not hudMediator then
        return
    end
    local targetPos = hudMediator:GetPowerPos()
    MathUtils.Paracurve(self.goTrail.transform, self.goTrail.transform.position, targetPos, CS.UnityEngine.Vector3.up, 2.5, 8, 0.5)
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
    self.delayTimer = TimerUtility.DelayExecute(function()
        g_Game.EventManager:TriggerEvent(EventConst.HUD_PLAY_POWER_EFFECT)
    end, 0.5)
end

---@field delta number
function PowerToastMediator:Tick(delta)
    self.openTime = self.openTime + delta
    if self.openTime > DURATION then
        g_Game.UIManager:Close(self.runtimeId)
    end
end

return PowerToastMediator;
