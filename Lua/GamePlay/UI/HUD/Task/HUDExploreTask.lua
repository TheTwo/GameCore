local Utils = require("Utils")
local Delegate = require("Delegate")
local BaseUIComponent = require ('BaseUIComponent')
local FloatingGuideFingerHolder = require("FloatingGuideFingerHolder")

---@class HUDExploreTaskData
---@field taskId number
---@field content string
---@field isFinished boolean
---@field playFinished boolean
---@field flyEffectHost HUDExploreComponent
---@field onverrideOnClick fun(param:HUDExploreTaskData)

---@class HUDExploreTask:BaseUIComponent
local HUDExploreTask = class('HUDExploreTask', BaseUIComponent)

function HUDExploreTask:ctor()
    self._taskId = 0
    self._guideFingerHolder = nil
end

function HUDExploreTask:OnCreate()
    self._p_status_n = self:GameObject("p_status_n")
    self._p_text_mission_explore = self:Text("p_text_mission_explore")
    self._p_status_finish = self:GameObject("p_status_finish")
    self._p_text_mission_explore_finish = self:Text("p_text_mission_explore_finish")
    self._p_vfx_hud_mission_complete = self:GameObject("p_vfx_hud_mission_complete")
    self._p_complete_trigger = self:AnimTrigger("p_complete_trigger")
    self._vfx_word_event_trail = self:GameObject("vfx_word_event_trail")
    self._btn_root = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_vx_fingerguide_2 = self:GameObject("p_vx_fingerguide_2")
end

function HUDExploreTask:OnShow()
    self._guideFingerHolder = FloatingGuideFingerHolder.new(self._p_vx_fingerguide_2)
end

function HUDExploreTask:OnHide()
    if self._guideFingerHolder then
        self._guideFingerHolder:Release()
    end
end

---@param data HUDExploreTaskData
function HUDExploreTask:OnFeedData(data)
    self._data = data
    self._taskId = data.taskId
    self._p_status_n:SetActive(not data.isFinished)
    self._p_status_finish:SetActive(data.isFinished)
    self._p_text_mission_explore.text = data.content
    self._p_text_mission_explore_finish.text = data.content
    if Utils.IsNotNull(self._p_vfx_hud_mission_complete) then
        self._p_vfx_hud_mission_complete:SetVisible(data.isFinished)
    end
    if Utils.IsNull(self._p_complete_trigger) then return end
    if data.isFinished and not data.playFinished then
        self._p_complete_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    else
        self._p_complete_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    if data.playFinished then
        self._p_complete_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        if data.flyEffectHost and Utils.IsNotNull(self._vfx_word_event_trail) then
            local effect = CS.UnityEngine.Object.Instantiate(self._vfx_word_event_trail, self._vfx_word_event_trail.transform.parent)
            data.flyEffectHost:AddFlyEffect(effect)
        end
    end
end

function HUDExploreTask:OnClick()
    if self._data and self._data.onverrideOnClick then
        self._data.onverrideOnClick(self._data)
        return
    end
    ---@type TaskItemDataProvider
    local provider = require("TaskItemDataProvider").new(self._taskId)
    provider:OnGoto()
end

return HUDExploreTask