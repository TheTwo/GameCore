local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
---@class HUDNormalTask : BaseUIComponent
local HUDNormalTask = class("HUDNormalTask", BaseUIComponent)

---@class HUDNormalTaskData
---@field provider TaskItemDataProvider
---@field index number
---@field vxTrigger CS.FpAnimation.FpAnimationCommonTrigger

local AnimTypeCanFinish = {
    [1] = CS.FpAnimation.CommonTriggerType.Custom3,
    [2] = CS.FpAnimation.CommonTriggerType.Custom5,
    [3] = CS.FpAnimation.CommonTriggerType.Custom7,
}

local AnimTypeFinished = {
    [1] = CS.FpAnimation.CommonTriggerType.Custom2,
    [2] = CS.FpAnimation.CommonTriggerType.Custom4,
    [3] = CS.FpAnimation.CommonTriggerType.Custom6,
}

function HUDNormalTask:ctor()
end

function HUDNormalTask:OnCreate()
    self.btnRoot = self:Button("", Delegate.GetOrCreate(self, self.OnBtnRootClick))
    self.textTask = self:Text("p_text_mission_finish")
end

function HUDNormalTask:OnShow()
end

function HUDNormalTask:OnHide()
end

---@param param HUDNormalTaskData
function HUDNormalTask:OnFeedData(param)
    self.provider = param.provider
    self.textTask.text = self.provider:GetTaskStr()
    self.provider:SetClickTransform(self.btnRoot.transform)
    self.index = param.index
    self.vxTrigger = param.vxTrigger
    self.provider:SetClaimCallback(function ()
        self.vxTrigger:PlayAll(AnimTypeFinished[self.index])
    end)
    if self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish then
        self.vxTrigger:PlayAll(AnimTypeCanFinish[self.index])
    end
end

function HUDNormalTask:OnBtnRootClick()
    local canReward = self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish
    if canReward then
        self.provider:OnClaim()
    else
        self.provider:OnGoto()
    end
end

return HUDNormalTask