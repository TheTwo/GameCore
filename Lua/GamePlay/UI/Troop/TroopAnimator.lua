local TimerUtility = require("TimerUtility")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
---@class TroopAnimator
local TroopAnimator = class("TroopAnimator")

---@param mediator UITroopMediator
function TroopAnimator:ctor(mediator)
    self._mediator = mediator

    self._powerUpdater = nil
    self._lastPower = 0
    self._lastBuffValue = 0

    self._goVfxStarTemplate = self._mediator:GameObject("vfx_troop_trail")
    self._goVfxStarTemplate.transform.position = CS.UnityEngine.Vector3(-1000, 0, 0)

    ---@type CS.UnityEngine.GameObject[]
    self._vfxStars = {}
end

function TroopAnimator:Release()
    if self._powerUpdater then
        self._powerUpdater:Stop()
        self._powerUpdater = nil
    end

    self:KillTween()
end

function TroopAnimator:KillTween()
    for _, vfxStar in pairs(self._vfxStars) do
        if Utils.IsNotNull(vfxStar) then
            vfxStar.transform:DOKill()
            UIHelper.DeleteUIGameObject(vfxStar)
        end
    end
end

function TroopAnimator:PlayPowerChangeAnimation(power)
    if not self._lastPower then
		self._lastPower = 0
	end
	local startTime = g_Game.Time.time
	local duration = math.min(0.5, math.abs(power - self._lastPower) / 3000)

    if self._powerUpdater then
        self._powerUpdater:Stop()
        self._powerUpdater = nil
    end
    
	self._powerUpdater = TimerUtility.StartFrameTimer(function()
        if Utils.IsNull(self._mediator.CSComponent) then return end
		local pct = (g_Game.Time.time - startTime) / duration
		self._lastPower = math.lerp(self._lastPower,power,pct)
		if pct >= 1.0 then
			self._lastPower = power
		end
		self._mediator.textPower.text = CS.System.String.Format("{0:#,0}", self._lastPower)
		if pct >= 1.0 then
            if self._powerUpdater then
                self._powerUpdater:Stop()
                self._powerUpdater = nil
            end
		end
	end, 1, -1, true)
end

function TroopAnimator:PlayBuffValueChangeAnimation(value)
    if value > self._lastBuffValue then
        self._mediator.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
    self._lastBuffValue = value
end

---@param clickTransform CS.UnityEngine.Transform
---@param targetTransforms CS.UnityEngine.Transform[]
function TroopAnimator:PlayAddHpAnimation(clickTransform, targetTransforms)
    self._vfxStars = {}
    for i = 1, #targetTransforms do
        self._goVfxStarTemplate:SetActive(true)
        local vfxStar = UIHelper.DuplicateUIGameObject(self._goVfxStarTemplate)
        self._goVfxStarTemplate:SetActive(false)
        table.insert(self._vfxStars, vfxStar)
        vfxStar.transform.position = Utils.DeepCopy(clickTransform.position)
        vfxStar.transform:DOMove(targetTransforms[i].position, 1):SetEase(CS.DG.Tweening.Ease.OutCubic):OnComplete(function()
            UIHelper.DeleteUIGameObject(vfxStar)
            self._vfxStars[i] = nil
            targetTransforms[i]:GetComponentInChildren(typeof(CS.FpAnimation.FpAnimationCommonTrigger)):PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            if table.nums(self._vfxStars) == 0 then
                self._mediator.troopEditManager:UpdateTroopFromPreset(self._mediator.troopEditManager:GetCurPresetIndex())
            end
        end)
    end
end

return TroopAnimator