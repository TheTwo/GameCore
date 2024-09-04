---prefab:ui3d_bubble_pet_probability
local Utils = require("Utils")
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")

---@class SEUnitHudPetCatch
---@field new fun():SEUnitHudPetCatch
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field p_text_probability CS.U2DTextMesh
---@field icon CS.U2DSpriteMesh
---@field FacingCamera CS.U2DFacingCamera
---@field p_probability CS.UnityEngine.GameObject
---@field p_text_probability_1 CS.U2DTextMesh
---@field p_text_success CS.U2DTextMesh
---@field p_text_failed CS.U2DTextMesh
---@field p_probability_progress CS.UnityEngine.GameObject
---@field p_progress CS.U2DSpriteMesh
local SEUnitHudPetCatch = class('SEUnitHudPetCatch')

SEUnitHudPetCatch.curve = CS.UnityEngine.AnimationCurve.EaseInOut(0, 0, 1, 1)

function SEUnitHudPetCatch:ctor()
    ---@type SeNpcConfigCell
    self._config = nil
    ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}[]
    self._pendingRate = {}
    self._targetSuccess = false
    self._delayHide = nil
end

function SEUnitHudPetCatch:Awake()
    self.p_text_probability_1.text = I18N.Get("捕捉概率")
end

function SEUnitHudPetCatch:ResetToNormal()
    self._targetSuccess = false
    table.clear(self._pendingRate)
    self.p_probability_progress:SetVisible(false)
    self.p_progress.fillAmount = 0
    self.p_text_success:SetVisible(false)
    self.p_text_failed:SetVisible(false)
end

function SEUnitHudPetCatch:GetGameObject()
    if Utils.IsNull(self.behaviour) then return nil end
    return self.behaviour.gameObject
end

---@param unit SEUnit
function SEUnitHudPetCatch:SetUnit(unit)
    self._config = unit:GetConfig()
end

---@param ballConfig PetPocketBallConfigCell
function SEUnitHudPetCatch:ShowAsCatchTarget(ballConfig, unitCanCatchStatus)
    if not ballConfig then
        self.p_probability:SetVisible(false)
    else
        local rate = 0
        if unitCanCatchStatus then
            rate = self:CalculateRate(ballConfig)
        end
        self.p_text_probability.text = string.format("%d%%", rate)
        self.p_text_probability.color = SEUnitHudPetCatch.BackgroundColorByRate(rate)
        self.p_probability:SetVisible(true)
    end
end

function SEUnitHudPetCatch:SetShowIcon(show)
    self.icon:SetVisible(show)
end

function SEUnitHudPetCatch:SetShowProgress(show)
    self.p_probability_progress:SetVisible(show)
end

---@return CS.UnityEngine.Color
function SEUnitHudPetCatch.BackgroundColorByRate(rate)
    local color
    if rate >= 80 then
        color = UIHelper.TryParseHtmlString(ColorConsts.army_green) or CS.UnityEngine.Color(0.0, 1.0, 0.0, 1.0)
    elseif rate >= 40 then
        color = UIHelper.TryParseHtmlString("#FF9833") or CS.UnityEngine.Color(1.0, 1.0, 0.0, 1.0)
    else
        color = UIHelper.TryParseHtmlString(ColorConsts.army_red) or CS.UnityEngine.Color(1.0, 0.0, 0.0, 1.0)
    end
    return color
end

---@param ballConfig PetPocketBallConfigCell
function SEUnitHudPetCatch:CalculateRate(ballConfig)
    local value = math.floor(ballConfig:Effect() * self._config:CatchSuccessRate() * 100 + 0.5)
    return math.clamp(value,0, 100)
end

---@param lastPair {targetValue:number, needTime:number, passTime:number, lastValue:number}
---@return {targetValue:number, needTime:number, passTime:number, lastValue:number}
function SEUnitHudPetCatch.MakeSmallStop(lastPair)
    ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}
    local ret = {}
    ret.targetValue = lastPair.targetValue
    ret.needTime = 0.08
    ret.passTime = 0
    ret.lastValue = lastPair.targetValue
    return ret
end

---@param ballConfig PetPocketBallConfigCell
function SEUnitHudPetCatch:PlaySuccess(ballConfig)
    self.p_progress.fillAmount = 0
    self._targetSuccess = true
    table.clear(self._pendingRate)
    local value = self:CalculateRate(ballConfig)
    self.p_text_success:SetVisible(false)
    self.p_text_failed:SetVisible(false)
    if value >= 100 then
        local color = SEUnitHudPetCatch.BackgroundColorByRate(100)
        self.p_text_probability.color = color
        self.p_progress.color = color
        self.p_progress.fillAmount = 1
        self.p_text_success:SetVisible(true)
        self:SetShowProgress(true)
        self._delayHide = 0.5
    else
        local ConstMain = ConfigRefer.ConstMain
        local lastValue = 0
        local timeIndex = 1
        local lastNeedTime = 0
        local needTime = 0
        if value < 50 then
            ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}
            local pair = {}
            pair.lastValue = lastValue
            pair.targetValue = value
            pair.passTime = 0
            needTime = ConfigTimeUtility.NsToSeconds(ConstMain:PetCatchDelayShowDurations(timeIndex))
            pair.needTime = needTime - lastNeedTime
            lastNeedTime = needTime
            timeIndex = timeIndex + 1
            lastValue = pair.targetValue
            self._pendingRate[#self._pendingRate + 1] = pair
            --self._pendingRate[#self._pendingRate + 1] = SEUnitHudPetCatch.MakeSmallStop(pair)
            pair = {}
            pair.lastValue = lastValue
            pair.targetValue = value * 2
            pair.passTime = 0
            needTime = ConfigTimeUtility.NsToSeconds(ConstMain:PetCatchDelayShowDurations(timeIndex))
            pair.needTime = needTime - lastNeedTime
            lastNeedTime = needTime
            timeIndex = timeIndex + 1
            lastValue = pair.targetValue
            self._pendingRate[#self._pendingRate + 1] = pair
            --self._pendingRate[#self._pendingRate + 1] = SEUnitHudPetCatch.MakeSmallStop(pair)
        else
            ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}
            local pair = {}
            pair.lastValue = lastValue
            pair.targetValue = value
            pair.passTime = 0
            needTime = ConfigTimeUtility.NsToSeconds(ConstMain:PetCatchDelayShowDurations(timeIndex))
            pair.needTime = needTime - lastNeedTime
            lastNeedTime = needTime
            timeIndex = timeIndex + 1
            lastValue = pair.targetValue
            self._pendingRate[#self._pendingRate + 1] = pair
            --self._pendingRate[#self._pendingRate + 1] = SEUnitHudPetCatch.MakeSmallStop(pair)
        end
        ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}
        local final = {}
        final.lastValue = lastValue
        final.targetValue = 100
        needTime = ConfigTimeUtility.NsToSeconds(ConstMain:PetCatchDelayShowDurations(timeIndex))
        final.needTime = needTime - lastNeedTime
        lastNeedTime = needTime
        final.passTime = 0
        self._pendingRate[#self._pendingRate + 1] = final
    end
end

---@param ballConfig PetPocketBallConfigCell
function SEUnitHudPetCatch:PlayFail(ballConfig, stepNumber)
    self.p_progress.fillAmount = 0
    self._targetSuccess = false
    table.clear(self._pendingRate)
    local value = self:CalculateRate(ballConfig)
    self.p_text_success:SetVisible(false)
    self.p_text_failed:SetVisible(false)
    local ConstMain = ConfigRefer.ConstMain
    local lastValue = 0
    if value <= 0 then
        self.p_text_failed:SetVisible(true)
        local color = SEUnitHudPetCatch.BackgroundColorByRate(0)
        self.p_text_probability.color = color
        self.p_progress.color = color
        self:SetShowProgress(true)
        self._delayHide = 0.5
    elseif value >= 50 then
        ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}
        local pair = {}
        pair.lastValue = 0
        pair.targetValue = value
        pair.passTime = 0
        pair.needTime = ConfigTimeUtility.NsToSeconds(ConstMain:PetCatchDelayShowDurations(1))
        lastValue = pair.targetValue
        self._pendingRate[#self._pendingRate + 1] = pair
    else
        stepNumber = math.max(1, stepNumber or 1)
        stepNumber = 100 // value
        local index = 1
        local lastNeedTime = 0
        local needTime = 0
        for i = 1, stepNumber do
            ---@type {targetValue:number, needTime:number, passTime:number, lastValue:number}
            local pair = {}
            pair.lastValue = lastValue
            pair.targetValue = value * i
            pair.passTime = 0
            needTime = ConfigTimeUtility.NsToSeconds(ConstMain:PetCatchDelayShowDurations(index))
            pair.needTime = needTime - lastNeedTime
            lastNeedTime = needTime
            index = index + 1
            lastValue = pair.targetValue
            self._pendingRate[#self._pendingRate + 1] = pair
            if i < stepNumber then
                --self._pendingRate[#self._pendingRate + 1] = SEUnitHudPetCatch.MakeSmallStop(pair)
            end
        end
    end
end

function SEUnitHudPetCatch.EaseInOutExpo(value)
    if value <= 0 then return 0 end
    if value >= 1 then return 1 end
    if value < 0.5 then
        return CS.UnityEngine.Mathf.Pow(2, 20 * value - 10) * 0.5
    end
    return (2 - CS.UnityEngine.Mathf.Pow(2, -20 * value + 10)) * 0.5
end

function SEUnitHudPetCatch:Tick(dt)
    if self._delayHide then
        self._delayHide = self._delayHide - dt
        if self._delayHide <= 0 then
            self.p_text_success:SetVisible(false)
            self.p_text_failed:SetVisible(false)
            self.p_probability_progress:SetVisible(false)
            self.p_probability:SetVisible(false)
            self._delayHide = nil
        end
    end
    if #self._pendingRate <= 0 then
        return
    end
    if not self.p_probability_progress.activeSelf then
        return
    end
    self.p_probability:SetVisible(true)
    local targetGroup = self._pendingRate[1]
    targetGroup.passTime = targetGroup.passTime + dt
    if targetGroup.passTime >= targetGroup.needTime then
        self.p_progress.fillAmount = math.inverseLerp(0, 100, targetGroup.targetValue)
        table.remove(self._pendingRate, 1)
        local rate = math.floor(targetGroup.targetValue + 0.5)
        self.p_text_probability.text = string.format("%d%%", rate)
        local color = SEUnitHudPetCatch.BackgroundColorByRate(rate)
        self.p_text_probability.color = color
        self.p_progress.color = color
        if #self._pendingRate <= 0 then
            self.p_text_success:SetVisible(self._targetSuccess)
            self.p_text_failed:SetVisible(not self._targetSuccess)
            self._delayHide = 0.5
        end
    else
        --local stepLerp = SEUnitHudPetCatch.curve:Evaluate(math.inverseLerp(0, targetGroup.needTime, targetGroup.passTime))
        local stepLerp = SEUnitHudPetCatch.EaseInOutExpo(math.inverseLerp(0, targetGroup.needTime, targetGroup.passTime))
        local value = math.lerp(targetGroup.lastValue, targetGroup.targetValue, stepLerp)
        self.p_progress.fillAmount = math.inverseLerp(0, 100, value)
        local rate = math.floor(value + 0.5)
        self.p_text_probability.text = string.format("%d%%", rate)
        local color = SEUnitHudPetCatch.BackgroundColorByRate(rate)
        self.p_text_probability.color = color
        self.p_progress.color = color
    end
end

return SEUnitHudPetCatch