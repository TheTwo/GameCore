local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimeFormatter = require('TimeFormatter')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local WorldTrendDefine = require('WorldTrendDefine')
local TimerUtility = require('TimerUtility')

---@class WorldTrendTimeLineTableNowCell : BaseTableViewProCell
local WorldTrendTimeLineTableNowCell = class('WorldTrendTimeLineTableNowCell', BaseTableViewProCell)

local CONDITION_NORMAL_HEIGHT = 316

function WorldTrendTimeLineTableNowCell:OnCreate()
    self.btnNow = self:Button('p_btn_now', Delegate.GetOrCreate(self, self.OnClickBtnNow))
    self.textTimeNow = self:Text('p_text_time_now')
    self.textName = self:Text('p_text_period_name_now')
    self.textTime = self:Text('p_text_period_time')
    self.rectCell = self:RectTransform('')
    self.goCell = self:GameObject('')

    self.goConditions = self:GameObject('p_item_conditions')
    self.textConditionsTitle = self:Text('p_text_conditions', "worldstage_2x1")
    self.textConditions_1 = self:Text('p_text_conditions_1')
    self.textConditionsNum_1 = self:Text('p_text_num_1')
    self.textConditions_2 = self:Text('p_text_conditions_2')
    self.textConditionsNum_2 = self:Text('p_text_num_2')

    -- self.goSystems = self:GameObject('p_system')
    self.textSystemTitle = self:Text('p_text_new_systems', 'worldstage_xinxitong')
    self.tableviewproNewSystem = self:TableViewPro("p_table_systems")
end

function WorldTrendTimeLineTableNowCell:OnFeedData(stageID)
    local stageConfig = ConfigRefer.WorldStage:Find(stageID)
    if not stageConfig then
        return
    end
    self.curStage = stageID

    local _, month, day = TimeFormatter.TimeToDateTime(ModuleRefer.WorldTrendModule:GetStageOpenTime(self.curStage))
    self.textTimeNow.text = string.format("%d.%d", month, day)
    self.textName.text = I18N.Get(stageConfig:Name())

    if stageConfig:BranchKingdomTasksLength() > 1 then
        self.goConditions:SetActive(true)
        self:InitCondition_1(stageConfig:BranchKingdomTasks(1))
        self:InitCondition_2(stageConfig:BranchKingdomTasks(2))
    else
        self.goConditions:SetActive(false)
    end

    self.tableviewproNewSystem:Clear()
    if stageConfig:UnlockSystemsLength() > 0 then
        for i = 1, stageConfig:UnlockSystemsLength() do
            self.tableviewproNewSystem:AppendData(stageConfig:UnlockSystems(i))
        end
    --     self.goSystems:SetActive(true)
    -- else
    --     self.goSystems:SetActive(false)
    end
    self.delayTimer = TimerUtility.DelayExecuteInFrame(function()
        self:HeightAdapt()
    end, 1)
    local curStageInfo = ModuleRefer.WorldTrendModule:GetStageInfo(self.curStage)
    if not curStageInfo then
        return
    end
    local finishTime = curStageInfo.EndTime.Seconds
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.stageRemainTime = math.floor(finishTime - curTime)
    self.textTime.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(self.stageRemainTime)
    if not self.tickTimer and self.stageRemainTime > 0 then
        self.tickTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.TickSecond), 1, -1)
    end
end

function WorldTrendTimeLineTableNowCell:OnClose()
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
end

function WorldTrendTimeLineTableNowCell:TickSecond()
    self:UpdateStageRemainTime()
end

function WorldTrendTimeLineTableNowCell:UpdateStageRemainTime()
    if not self.stageRemainTime or self.stageRemainTime < 0 then
        if self.tickTimer then
            TimerUtility.StopAndRecycle(self.tickTimer)
            self.tickTimer = nil
        end
        return
    end
    self.stageRemainTime = self.stageRemainTime - 1
    self.textTime.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(self.stageRemainTime)
end

function WorldTrendTimeLineTableNowCell:InitCondition_1(taskID)
    local taskCfg = ConfigRefer.KingdomTask:Find(taskID)
    if not taskCfg then
        return
    end
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(taskID)
    local curStr = tostring(cur)
    local totalStr = tostring(total)
    if cur < total then
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.warning)
    else
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.quality_green)
    end
    local taskDescStr = ModuleRefer.WorldTrendModule:GetTaskDesc(taskCfg, WorldTrendDefine.TASK_TYPE.Global)
    self.textConditions_1.text = taskDescStr
    self.textConditionsNum_1.text = string.format("%s/%s", curStr, totalStr)
end

function WorldTrendTimeLineTableNowCell:InitCondition_2(taskID)
    local taskCfg = ConfigRefer.KingdomTask:Find(taskID)
    if not taskCfg then
        return
    end
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(taskID)
    local curStr = tostring(cur)
    local totalStr = tostring(total)
    if cur < total then
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.warning)
    else
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.quality_green)
    end
    local taskDescStr = ModuleRefer.WorldTrendModule:GetTaskDesc(taskCfg, WorldTrendDefine.TASK_TYPE.Global)
    self.textConditions_2.text = taskDescStr
    self.textConditionsNum_2.text = string.format("%s/%s", curStr, totalStr)
end

function WorldTrendTimeLineTableNowCell:HeightAdapt()
    local cellHeight = self.goCell:GetComponent(typeof(CS.CellSizeComponent)).Height
    local conditionTrans = self.goConditions:GetComponent(typeof(CS.UnityEngine.RectTransform))
    if not self.goConditions.activeSelf then
        self.rectCell.sizeDelta = CS.UnityEngine.Vector2(self.rectCell.sizeDelta.x, cellHeight - CONDITION_NORMAL_HEIGHT)
    else
        --计算condition节点的高度
        local trans_1 = self.textConditionsTitle.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        local textHeight_1 = trans_1 and trans_1.rect.height or 0
        local trans_2 = self.textConditions_1.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        local textHeight_2 = trans_2 and trans_2.rect.height or 0
        local trans_3 = self.textConditionsNum_1.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        local textHeight_3 = trans_3 and trans_3.rect.height or 0
        local trans_4 = self.textConditions_2.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        local textHeight_4 = trans_4 and trans_4.rect.height or 0
        local trans_5 = self.textConditionsNum_2.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        local textHeight_5 = trans_5 and trans_5.rect.height or 0
        local conditionsNodeHeight = textHeight_1 + textHeight_2 + textHeight_3 + textHeight_4 + textHeight_5

        self.rectCell.sizeDelta = CS.UnityEngine.Vector2(self.rectCell.sizeDelta.x, cellHeight - CONDITION_NORMAL_HEIGHT + conditionsNodeHeight)
    end
end

function WorldTrendTimeLineTableNowCell:OnClickBtnNow()
    local UIMediatorNames = require('UIMediatorNames')
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLineMediator, self.curStage)
end

return WorldTrendTimeLineTableNowCell