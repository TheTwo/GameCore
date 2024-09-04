local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local WorldTrendDefine = require('WorldTrendDefine')
local TimeFormatter = require('TimeFormatter')

---@class WorldTrendTimeLineTableBeforeCell : BaseTableViewProCell
local WorldTrendTimeLineTableBeforeCell = class('WorldTrendTimeLineTableBeforeCell', BaseTableViewProCell)

function WorldTrendTimeLineTableBeforeCell:OnCreate()
    self.btnBefore = self:Button('p_btn_before', Delegate.GetOrCreate(self, self.OnClickBtnBefore))
    self.goNormal = self:GameObject('p_normal')
    self.goReward = self:GameObject('p_btn_reward')

    self.textTimeBefore = self:Text('p_text_time_before')
    self.textName = self:Text('p_text_period_name_before')
end

function WorldTrendTimeLineTableBeforeCell:OnFeedData(stageID)
    local stageConfig = ConfigRefer.WorldStage:Find(stageID)
    if not stageConfig then
        return
    end
    self.curStage = stageID

    local _, month, day = TimeFormatter.TimeToDateTime(ModuleRefer.WorldTrendModule:GetStageOpenTime(self.curStage))
    self.textTimeBefore.text = string.format("%d.%d", month, day)
    self.textName.text = I18N.Get(stageConfig:Name())

    self:UpdateRewardStage()

    g_Game.EventManager:AddListener(EventConst.UPDATE_WORLD_TREND_STAGE_REWARD, Delegate.GetOrCreate(self, self.UpdateRewardStage))
end

function WorldTrendTimeLineTableBeforeCell:OnClickBtnBefore()
    local UIMediatorNames = require('UIMediatorNames')
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLineMediator, self.curStage)
end

function WorldTrendTimeLineTableBeforeCell:UpdateRewardStage()
    local state = ModuleRefer.WorldTrendModule:GetStageState(self.curStage)
    self.goNormal:SetActive(state ~= WorldTrendDefine.BRANCH_STATE.CanReward)
    self.goReward:SetActive(state == WorldTrendDefine.BRANCH_STATE.CanReward)
end

function WorldTrendTimeLineTableBeforeCell:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.UPDATE_WORLD_TREND_STAGE_REWARD, Delegate.GetOrCreate(self, self.UpdateRewardStage))
end

return WorldTrendTimeLineTableBeforeCell