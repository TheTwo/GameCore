local ConfigRefer = require('ConfigRefer')
local GuideConditionProcesser = require('GuideConditionProcesser')
local GuideUtils = require('GuideUtils')
local GuideTargetGetters = require('GuideTargetGetters')
local TimerUtility = require('TimerUtility')
local EventConst = require('EventConst')
local GuideType = require('GuideType')
local UIMediatorNames = require('UIMediatorNames')
---@class BaseGuideStep
local BaseGuideStep = class('BaseGuideStep')

BaseGuideStep.MaxRetryCount = 20
BaseGuideStep.RetryInterval = 0.1

function BaseGuideStep:ctor(id)
    self.id = id
    self.cfg = ConfigRefer.Guide:Find(id)

    ---@type GuideCallConfigCell
    self.guideCallCfg = nil

    ---@type GuideGroupConfigCell
    self.guideGroupCfg = nil

    self.retryCount = 0

    ---@type GuideConditionProcesser
    self.condPraser = GuideConditionProcesser.new()

    self.target = nil
    self.dragTarget = nil

    self.isExecuting = false
end

function BaseGuideStep:Execute()
    if self:Check() then
        g_Game.EventManager:TriggerEvent(EventConst.GUIDE_STEP_START, self)
        self.isExecuting = true
        if not self:NeedTarget() then
            self:ExecuteImpl()
            return
        end
        self.retryHandle = TimerUtility.IntervalRepeat(function()
            local success, errInfo = self:InitTarget()
            if success then
                self:ExecuteImpl()
                TimerUtility.StopAndRecycle(self.retryHandle)
                self.retryHandle = nil
            else
                self.retryCount = self.retryCount + 1
                if self.retryCount >= BaseGuideStep.MaxRetryCount then
                    self:Stop()
                    g_Logger.WarnChannel('BaseGuideStep', '引导%d执行失败: %s', self.id, errInfo)
                end
            end
        end, BaseGuideStep.RetryInterval, BaseGuideStep.MaxRetryCount)
    else
        local onFailedStep = self:GetOnFailedStep()
        if onFailedStep then
            onFailedStep:Execute()
        end
    end
end

---@protected
function BaseGuideStep:ExecuteImpl()
    -- override this
    g_Logger.ErrorChannel('BaseGuideStep', 'BaseGuideStep:ExecuteImpl() is not implemented, id:%d', self.id)
end

function BaseGuideStep:End()
    g_Game.EventManager:TriggerEvent(EventConst.GUIDE_STEP_END, self, true)
    self.isExecuting = false
end

--- 强行结束引导
function BaseGuideStep:Stop()
    if self.retryHandle then
        TimerUtility.StopAndRecycle(self.retryHandle)
        self.retryHandle = nil
    end
    self.isExecuting = false
    self:PostStop()
    g_Game.EventManager:TriggerEvent(EventConst.GUIDE_STEP_END, self, false)
end

--- 强行结束引导后的处理(关闭ui、清理现场等)
---@protected
function BaseGuideStep:PostStop()
    -- override this
end

---@protected
function BaseGuideStep:Check()
    if self.guideCallCfg and not self.guideCallCfg:CityExplorMode() then
        if GuideUtils.IsInMyCityExplorMode() then
            return false
        end
    end

    return self.condPraser:ExeConditionCmd(self.cfg:TriggerCmd(), self.guideCall)
end

function BaseGuideStep:InitTarget()
    local guideTargetGetter = GuideTargetGetters.GetTargetGetter(self.cfg:Zone():Type())
    local success, target = guideTargetGetter(self.cfg:Zone())
    if success then
        if target.range < 0.01 then
            target.range = 100
        end
        local offsetCfg = self.cfg:MaskOffset()
        target.offset = CS.UnityEngine.Vector3(offsetCfg:X(),offsetCfg:Y(),0)
        target.camerSize = self.cfg:CameraSize()
        self.target = target
    else
        self.target = nil
        self.dragTarget = nil
        return false, target
    end

    local dragId = self.cfg:Drag()
    if dragId and dragId > 0 then
        local dragCfg = ConfigRefer.GuideGesture:Find(dragId)
        local dragTargetGetter = GuideTargetGetters.GetTargetGetter(dragCfg:Zone():Type())
        local dragTargetSuccess, dragTarget = dragTargetGetter(dragCfg:Zone())
        if dragTargetSuccess then
            self.dragTarget = dragTarget
        else
            self.target = nil
            self.dragTarget = nil
            return false, dragTarget
        end
    end

    return true
end

---@return number
function BaseGuideStep:GetCfgId()
    return self.id
end

---@return GuideConfigCell
function BaseGuideStep:GetCfg()
    return self.cfg
end

---@return BaseGuideStep | nil
function BaseGuideStep:GetNextStep()
    local nextId = self.cfg:Next()
    if nextId > 0 then
        return require("GuideStepSimpleFactory").CreateGuideStep(nextId):SetGuideCallCfg(self.guideCallCfg):SetGuideGroupCfg(self.guideGroupCfg)
    end
    return nil
end

---@return BaseGuideStep | nil
function BaseGuideStep:GetOnFailedStep()
    local onFailedId = self.cfg:GuideOnFail()
    if onFailedId > 0 then
        return require("GuideStepSimpleFactory").CreateGuideStep(onFailedId):SetGuideCallCfg(self.guideCallCfg):SetGuideGroupCfg(self.guideGroupCfg)
    end
    return nil
end

---@param guideCallCfg GuideCallConfigCell
function BaseGuideStep:SetGuideCallCfg(guideCallCfg)
    self.guideCallCfg = guideCallCfg
    return self
end

---@param guideGroupCfg GuideGroupConfigCell
function BaseGuideStep:SetGuideGroupCfg(guideGroupCfg)
    self.guideGroupCfg = guideGroupCfg
    return self
end

---@return GuideCallConfigCell
function BaseGuideStep:GetGuideCallCfg()
    return self.guideCallCfg
end

---@return GuideGroupConfigCell
function BaseGuideStep:GetGuideGroupCfg()
    return self.guideGroupCfg
end

function BaseGuideStep:GetType()
    return self.cfg:Type()
end

---@return boolean
function BaseGuideStep:ShouldUpload()
    return self.cfg:Upload()
end

function BaseGuideStep:IsForce()
    return self.cfg:Type() == GuideType.UIClick or self.cfg:Type() == GuideType.GroundClick
end

function BaseGuideStep:NeedTarget()
    return self.cfg:Zone() and self.cfg:Zone():Type() > 0
end

function BaseGuideStep:IsRetrying()
    return self.retryHandle ~= nil
end

function BaseGuideStep:IsExecuting()
    return self.isExecuting
end

function BaseGuideStep:ShowGuideFinger(onlyMask)
    local data = {}
    if onlyMask then
        data = {config = self.cfg}
    else
        data.onClick = function(forceStop)
            if forceStop then
                self:Stop()
            else
                g_Game.EventManager:TriggerEvent(EventConst.GUIDE_STEP_END, self, true)
            end
        end
        data.config = self.cfg
        data.targetData = self.target
        data.dstTargetData = self.dragTarget
    end
    local fingerWin = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIGuideFingerMediator)
    if fingerWin then
        fingerWin:FeedData(data)
    else
        g_Game.UIManager:Open(UIMediatorNames.UIGuideFingerMediator, data)
    end
end

return BaseGuideStep