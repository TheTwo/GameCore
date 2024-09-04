---@class City3DBubbleTrain
local City3DBubbleTrain = class("City3DBubbleTrain")
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local UIHelper = require("UIHelper")
local ColorConsts = require('ColorConsts')
local TimeFormatter = require('TimeFormatter')
local Utils = require('Utils')

function City3DBubbleTrain:RefreshState(furnitureId, configId)
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    local isCustomTraining = castleMilitia.TrainPlan and castleMilitia.TrainPlan > 0
    local isAutoTraining = not (castleMilitia.SwitchOff or isCustomTraining)
    local curSoldierNum = castleMilitia.Count
    local maxSoldierNum = castleMilitia.Capacity
    local isMax = maxSoldierNum <= curSoldierNum
    if isMax then
        self:ClearCustomTimer()
        self:ClearTickTimer()
        self.p_text_status.text = I18N.Get("recruit_info_max")
        self.p_base_progress.color = UIHelper.TryParseHtmlString(ColorConsts.train_blue)
        self.p_text_status.color =  UIHelper.TryParseHtmlString(ColorConsts.quality_orange)
        self.vx_effect_glow.gameObject:SetActive(false)
        self.p_base_progress_view.transform.gameObject:SetActive(false)
    elseif isAutoTraining then
        self:ClearCustomTimer()
        local workId = ModuleRefer.TrainingSoldierModule:GetWorkId(configId)
        local traingSpeed = ModuleRefer.TrainingSoldierModule:GetTraingSpeed(workId, nil, furnitureId, nil)
        if traingSpeed <= 0 then
            return
        end
        local needTime = ((maxSoldierNum - curSoldierNum) / traingSpeed) * 60
        self.endTime = needTime + g_Game.ServerTime:GetServerTimestampInSeconds()
        local isEnough = true
        local itemArrays = ModuleRefer.TrainingSoldierModule:GetCostItems(workId, nil, furnitureId, nil)
        for i = 1, #itemArrays do
            if ModuleRefer.InventoryModule:GetAmountByConfigId(itemArrays[i].id) < itemArrays[i].count then
                isEnough = false
            end
        end
        self.p_base_progress_view.progress = 0
        if isEnough and not self.tickTimer then
            self:RefreshTimeText()
            self.tickTimer = TimerUtility.IntervalRepeat(function() self:RefreshTimeText() end, 0.5, -1)
            self.p_text_status.color =  UIHelper.TryParseHtmlString(ColorConsts.off_white)
            self.p_base_progress.color = UIHelper.TryParseHtmlString(ColorConsts.train_blue)
        elseif not isEnough then
            self:ClearTickTimer()
            self.p_text_status.text = I18N.Get("recruit_info_nofood")
            self.p_text_status.color =  UIHelper.TryParseHtmlString(ColorConsts.army_red)
            self.p_base_progress.color = UIHelper.TryParseHtmlString(ColorConsts.dark_grey)
        end
        self.vx_effect_glow.gameObject:SetActive(isEnough)
    elseif isCustomTraining then
        self:ClearTickTimer()
        local workId = ModuleRefer.TrainingSoldierModule:GetWorkId(configId)
        local traingSpeed = ModuleRefer.TrainingSoldierModule:GetTraingSpeed(workId, nil, furnitureId, nil)
        if traingSpeed <= 0 then
            return
        end
        local targetNum = castleMilitia.Count + castleMilitia.TrainPlan - castleMilitia.TrainProgress
        local needTime = ((targetNum - curSoldierNum) / traingSpeed) * 60
        self.endTime = needTime + g_Game.ServerTime:GetServerTimestampInSeconds()
        if not self.customTickTimer then
            self:RefreshTimeText()
            self.customTickTimer = TimerUtility.IntervalRepeat(function() self:RefreshTimeText() end, 0.5, -1)
            self.p_text_status.color =  UIHelper.TryParseHtmlString(ColorConsts.off_white)
            self.p_base_progress.color = UIHelper.TryParseHtmlString(ColorConsts.train_blue)
        end
        self.vx_effect_glow.gameObject:SetActive(true)
        self.p_base_progress_view.progress =  math.clamp01(targetNum / castleMilitia.Capacity)
    else
        self:ClearCustomTimer()
        self:ClearTickTimer()
        self.p_text_status.text = I18N.Get("recruit_info_notinopration")
        self.p_text_status.color =  UIHelper.TryParseHtmlString(ColorConsts.army_red)
        self.p_base_progress.color = UIHelper.TryParseHtmlString(ColorConsts.dark_grey)
        self.vx_effect_glow.gameObject:SetActive(false)
        self.p_base_progress_view.progress = 0
    end
    self.p_icon_process:SetActive(isAutoTraining and not isMax)
    self.p_text_quantity.text = string.format("<b>%s</b>" ,curSoldierNum) .. "/" .. maxSoldierNum
    self.p_base_progress.progress = math.clamp01(curSoldierNum / maxSoldierNum)
    self.vx_effect_glow.localPosition = CS.UnityEngine.Vector3(math.clamp01(curSoldierNum / maxSoldierNum) * 240 - 150, 0, 0)
end

function City3DBubbleTrain:RefreshTimeText()
    local remainTime = self.endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    if remainTime > 0 and Utils.IsNotNull(self.p_text_status) then
        self.p_text_status.text = TimeFormatter.SimpleFormatTime(remainTime)
    else
        self:ClearTimer()
    end
end

function City3DBubbleTrain:PlayInAnim()
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function City3DBubbleTrain:ClearTimer()
    self:ClearTickTimer()
    self:ClearCustomTimer()
end


function City3DBubbleTrain:ClearTickTimer()
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
end

function City3DBubbleTrain:ClearCustomTimer()
    if self.customTickTimer then
        TimerUtility.StopAndRecycle(self.customTickTimer)
        self.customTickTimer = nil
    end
end

return City3DBubbleTrain