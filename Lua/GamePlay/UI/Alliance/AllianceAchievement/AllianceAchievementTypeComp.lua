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

---@class AllianceAchievementTypeComp : BaseTableViewProCell
local AllianceAchievementTypeComp = class('AllianceAchievementTypeComp', BaseTableViewProCell)

function AllianceAchievementTypeComp:OnCreate()
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_img_full = self:GameObject('p_img_full')
    self.p_icon_achievement = self:Image('p_icon_achievement')
    self.p_text_name = self:Text('p_text_name')
    self.p_text_detail = self:Text('p_text_detail')
    self.p_progress = self:Slider('p_progress')
    self.p_text_progress = self:Text('p_text_progress')

    self.reddot = self:LuaObject('child_reddot_default')
end

function AllianceAchievementTypeComp:OnShow()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshData))
end

function AllianceAchievementTypeComp:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshData))
end

function AllianceAchievementTypeComp:OnFeedData(param)
    self.param = param
    self.canClick = self.param.canClick
    if param.index == AllianceLongTermTaskType.Develop then
        g_Game.SpriteManager:LoadSprite('sp_league_achievement_icon_builder', self.p_icon_achievement)
        self.p_text_name.text = I18N.Get("alliance_target_47")
        self.p_text_detail.text = I18N.Get("alliance_target_50")
    elseif param.index == AllianceLongTermTaskType.Territory then
        g_Game.SpriteManager:LoadSprite('sp_league_achievement_icon_ruler', self.p_icon_achievement)
        self.p_text_name.text = I18N.Get("alliance_target_48")
        self.p_text_detail.text = I18N.Get("alliance_target_51")
    elseif param.index == AllianceLongTermTaskType.War then
        g_Game.SpriteManager:LoadSprite('sp_league_achievement_icon_fearless', self.p_icon_achievement)
        self.p_text_name.text = I18N.Get("alliance_target_49")
        self.p_text_detail.text = I18N.Get("alliance_target_52")
    end

    self:RefreshData(self.param.index)
end

function AllianceAchievementTypeComp:RefreshData(index)
    if index ~= self.param.index then
        return
    end

    local count = 0
    for k, v in pairs(self.param.tasks) do
        if ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(v.TID) >= wds.TaskState.TaskStateFinished then
            count = count + 1
        end
    end

    self.p_text_progress.text = count .. "/" .. #self.param.tasks
    self.p_progress.value = count / #self.param.tasks

    -- 红点
    if self.canClick then
        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_LongTerm_" .. self.param.index, NotificationType.ALLIANCE_ACHIEVEMENT_LONG)
        ModuleRefer.NotificationModule:AttachToGameObject(node, self.reddot.go, self.reddot.redTextGo, self.reddot.redText)
    end
end

function AllianceAchievementTypeComp:OnBtnClick()
    if self.canClick then
        g_Game.UIManager:Open(UIMediatorNames.AllianceAchievementPopUpMediator, self.param)
    end
end

function AllianceAchievementTypeComp:SetCanClick(canClick)
    self.canClick = canClick
    self.reddot:SetVisible(canClick)
end

return AllianceAchievementTypeComp
