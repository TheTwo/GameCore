local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local TaskItemDataProvider = require("TaskItemDataProvider")
local DBEntityPath = require("DBEntityPath")
local FloatingGuideFingerHolder = require("FloatingGuideFingerHolder")
local Utils = require("Utils")
---@class HUDTaskComponent : BaseUIComponent
local HUDTaskComponent = class("HUDTaskComponent", BaseUIComponent)

function HUDTaskComponent:ctor()
    self.isTaskDirty = false
    self.guideFingerHolder = nil
end

function HUDTaskComponent:OnCreate()
    self.btnIcon = self:Button('p_btn_mission_extend', Delegate.GetOrCreate(self, self.OnBtnIconClick))
    self.btnTask = self:Button('p_btn_mission', Delegate.GetOrCreate(self, self.OnBtnTaskClick))
    self.textTask = self:Text('p_text_mission')
    self.vxTrigger = self:AnimTrigger('trigger_1')

    self.goFinger = self:GameObject('p_vx_fingerguide_1')

    self.luaTask1 = self:LuaObject('p_btn_npc1')
    self.luaTask2 = self:LuaObject('p_btn_npc2')
    self.luaTask3 = self:LuaObject('p_btn_npc3')

    self.luaTask1:SetVisible(false)
    self.luaTask2:SetVisible(false)
    self.luaTask3:SetVisible(false)
end

function HUDTaskComponent:OnShow()
    self.guideFingerHolder = FloatingGuideFingerHolder.new(self.goFinger)
    self:UpdateTask()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetDirty))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function HUDTaskComponent:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetDirty))
    if self.guideFingerHolder then
        self.guideFingerHolder:Release()
    end
end

function HUDTaskComponent:SetDirty()
    self.isTaskDirty = true
end

function HUDTaskComponent:UpdateTask()
    self.btnIcon.gameObject:SetActive(true)
    local recommedTasks = ModuleRefer.QuestModule.Chapter:GetRecommendQuests(1)
    local taskId = recommedTasks[1].config:Id()
    ---@type TaskItemDataProvider
    self.provider = TaskItemDataProvider.new(taskId)
    self.textTask.text = self.provider:GetTaskStr()

    if Utils.IsNotNull(self.vxTrigger) then
        if self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish then
            self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            self.vxTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    end
    
    self.provider:SetClaimCallback(function()
        self:UpdateTask()
    end)
end

function HUDTaskComponent:OnSecondTick()
    if self.isTaskDirty then
        self.isTaskDirty = false
        self:UpdateTask()
    end
end

function HUDTaskComponent:OnBtnIconClick()
    g_Game.UIManager:Open(UIMediatorNames.QuestUIMediator)
end

function HUDTaskComponent:OnBtnTaskClick()
    local state = self.provider:GetTaskState()
    if state == wds.TaskState.TaskStateCanFinish then
        self.provider:OnClaim()
    else
        self.provider:OnGoto()
    end
end

return HUDTaskComponent