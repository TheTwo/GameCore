local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')
local NotificationType = require('NotificationType')
local EventConst = require('EventConst')

---@class AllianceAchievementLeaderChapterTab : BaseTableViewProCell
local AllianceAchievementLeaderChapterTab = class('AllianceAchievementLeaderChapterTab', BaseTableViewProCell)

function AllianceAchievementLeaderChapterTab:OnCreate()
    self.statusRecordParent = self:StatusRecordParent("p_btn_chapter")
    self.p_btn_chapter = self:Button("p_btn_chapter", Delegate.GetOrCreate(self, self.Select))

    self.p_text_a = self:Text('p_text_a')
    self.p_text_b = self:Text('p_text_b')
    self.p_text_c = self:Text('p_text_c')

    self.p_icon_lock = self:GameObject('p_icon_lock')
    self.reddot = self:LuaObject('child_reddot_default')
end

function AllianceAchievementLeaderChapterTab:OnShow()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEADER_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshRedDot))
end

function AllianceAchievementLeaderChapterTab:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEADER_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshRedDot))
end

function AllianceAchievementLeaderChapterTab:RefreshRedDot(chapter)
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Leader_" .. self.index, NotificationType.ALLIANCE_ACHIEVEMENT_LEADER)
    ModuleRefer.NotificationModule:AttachToGameObject(node, self.reddot.go, self.reddot.redTextGo, self.reddot.redText)
    self:CheckUnlock()
    -- if self.isLock then
    --     ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 0)
    -- end
end

function AllianceAchievementLeaderChapterTab:OnFeedData(param)
    self.isSelected = false
    self.param = param
    self.index = param.index
    self.onClick = param.onClick
    self.p_text_a.text = I18N.GetWithParams("第{1}章", self.index)
    self.p_text_b.text = I18N.GetWithParams("第{1}章", self.index)
    self.p_text_c.text = I18N.GetWithParams("第{1}章", self.index)
    self:RefreshRedDot()
end

function AllianceAchievementLeaderChapterTab:CheckUnlock()
    -- 第一章外 当前一章节任务都完成时解锁
    self.isLock = self.index ~= 1 and not ModuleRefer.AllianceJourneyModule:IsLeaderTaskChapterUnlock(self.index - 1) or false
    if not self.isSelected then
        self:UnSelect()
    end
    self.p_icon_lock:SetVisible(self.isLock)
end

function AllianceAchievementLeaderChapterTab:Select()
    if self.isLock then
        -- ModuleRefer.ToastModule:AddSimpleToast("#未解锁")
        -- return
    end
    self.isSelected = true
    if self.onClick then
        self.onClick(self.index)
    end
    self.statusRecordParent:SetState(0) -- 选中
end

function AllianceAchievementLeaderChapterTab:UnSelect()
    self.isSelected = false
    if self.isLock then
        self.statusRecordParent:SetState(2) -- 未解锁
    else
        self.statusRecordParent:SetState(1) -- 正常

    end
end

return AllianceAchievementLeaderChapterTab
