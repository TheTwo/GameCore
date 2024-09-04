local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')

---@class WorldTrendTimeLineMediator : BaseUIMediator
local WorldTrendTimeLineMediator = class('WorldTrendTimeLineMediator', BaseUIMediator)

local CONTENT_OFFSET = 770

function WorldTrendTimeLineMediator:OnCreate()
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.tableviewproTimeLine = self:TableViewPro("p_table_timeline")
    self.goContent = self:GameObject('p_content')
    self.transStageCell = self:RectTransform('p_item')
    self.btnLeftRewardDot = self:Button('p_btn_reddot_left', Delegate.GetOrCreate(self, self.OnClickLeftRewardDot))
    self.textLeftRewardNum = self:Text('p_text_number_left')
    self.btnRightRewardDot = self:Button('p_btn_reddot_right', Delegate.GetOrCreate(self, self.OnClickRightRewardDot))
    self.textRightRewardNum = self:Text('p_text_number_right')
end

function WorldTrendTimeLineMediator:OnOpened(defaultStage)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("worldstage_shijianxian"),
        onClose = Delegate.GetOrCreate(self, self.OnBackBtnClick)
    })

    self.indexList = {}
    self.maxCloseStage = 2
    self.stageIndex = 0
    self.curDotIndex = 1
    self.cellWidth = self.transStageCell.sizeDelta.x
    self.cellWidthList = {}
    self.curStage = ModuleRefer.WorldTrendModule:GetCurStage().Stage
    local historyStages = ModuleRefer.WorldTrendModule:GetCurSeasonHistoryStages()

    if #historyStages > 0 then
        self:InitWorldTrendByHistoryStages(historyStages)
    else
        self:InitNewWorldTrend()
    end
    if defaultStage and defaultStage > 0 then
        self.curDotIndex = self:GetIndexByStage(self.indexList[defaultStage])
    else
        self.curDotIndex = self:GetIndexByStage(self.curStage)
    end
    self:MoveToStageByIndex(self.curDotIndex,0)
    self:UpdateRewardDot()
    if not self.checkTimer then
        self.checkTimer = TimerUtility.IntervalRepeat(function()
            self:CheckContentPos()
        end, 0.5, -1)
    end
end

function WorldTrendTimeLineMediator:OnShow()
end

function WorldTrendTimeLineMediator:OnHide()
    if self.checkTimer then
        TimerUtility.StopAndRecycle(self.checkTimer)
        self.checkTimer = nil
    end
end

function WorldTrendTimeLineMediator:OnBackBtnClick()
    self:BackToPrevious()
end

--没有历史数据时，初始化
function WorldTrendTimeLineMediator:InitNewWorldTrend()
    local beginStage = ModuleRefer.WorldTrendModule:GetCurSeasonBeginStage()
    if beginStage <= 0 then
        return
    end
    
    self.tableviewproTimeLine:Clear()
    local isOpen = self.curStage > 0 and true or false
    local curStage = beginStage
    self:InitStageCell(curStage, isOpen, true)
end

function WorldTrendTimeLineMediator:InitWorldTrendByHistoryStages(historyStages)
    local lastStage = -1
    self.tableviewproTimeLine:Clear()
    for i = 1, #historyStages do
        if i > 1 then
            lastStage = historyStages[i - 1].Stage
        end
        self:InitStageCell(historyStages[i].Stage, true, false, lastStage)
    end
    lastStage = historyStages[#historyStages].Stage
    local curStageNode = ModuleRefer.WorldTrendModule:GetCurStage()
    self:InitStageCell(curStageNode.Stage, true, true, lastStage)
end

function WorldTrendTimeLineMediator:InitStageCell(curStage, isOpen, isRecursion, lastStage)
    if self.maxCloseStage <= 0 then
        return
    end
    lastStage = lastStage or -1
    isRecursion = isRecursion or false
    ---@type WorldTrendStageCellParam
    self.stageIndex = self.stageIndex + 1
    ---@type WorldTrendTimeLineCellParam
    local param = {stage = curStage, isOpen = isOpen, lastStage = lastStage, index = self.stageIndex}
    if not isOpen then
        self.maxCloseStage = self.maxCloseStage - 1
    end
    local isLastShowStage = self.maxCloseStage <= 0     --是否是最后一个显示的阶段
    param.isLastShowStage = isLastShowStage
    local cellWidth = ModuleRefer.WorldTrendModule:GetStageCellWidth(curStage, isOpen, isLastShowStage)
    self.tableviewproTimeLine:AppendDataEx(param, cellWidth, 0)
    table.insert(self.cellWidthList, cellWidth)

    
    self.indexList[self.stageIndex] = curStage
    if not isRecursion then
        return
    end
    local config = ConfigRefer.WorldStage:Find(curStage)
    if not config then
        return
    end
    if config:BranchesLength() > 0 and config:Branches(1) > 0 then
        self:InitStageCell(config:Branches(1), false, isRecursion, curStage)
    end
end

function WorldTrendTimeLineMediator:GetIndexByStage(stage)
    for i = 1, #self.indexList do
        if self.indexList[i] == stage then
            return i
        end
    end
    return 1
end

function WorldTrendTimeLineMediator:MoveToStageByIndex(index,delay)
    local targetPosX = self:GetTargetPosXByIndex(index - 1)
    self.goContent.transform:DOLocalMoveX(-targetPosX , delay)
end

function WorldTrendTimeLineMediator:CheckContentPos()
    local contentPosX = self.goContent.transform.localPosition.x
    local targetIndex = self:GetCenterPosIndex(contentPosX)
    if targetIndex ~= self.curDotIndex then
        self.curDotIndex = targetIndex
        self:UpdateRewardDot()
        -- ---@type WorldTrendSelectDotCellParam
        -- local param = {index = self.curDotIndex}
        -- g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_SELECT_DOT, param)
    end
end

function WorldTrendTimeLineMediator:GetTargetPosXByIndex(index)
    if index > #self.cellWidthList or index <= 0 then
        return 0
    end
    if index <= 1 then
        return CONTENT_OFFSET
    end
    local targetPosX = 0
    for i = 1, index - 1 do
        targetPosX = targetPosX + self.cellWidthList[i] + self.tableviewproTimeLine.spacing.x
    end
    if index <= 2 then
        return targetPosX + 90 + CONTENT_OFFSET
    else
        return targetPosX + 90 + CONTENT_OFFSET + 820
    end
    -- return targetPosX + CONTENT_OFFSET
end

function WorldTrendTimeLineMediator:GetCellWidthByIndex(index)
    if index > #self.cellWidthList or index <= 0 then
        return 0
    end
    return self.cellWidthList[index]
end

function WorldTrendTimeLineMediator:GetCenterPosIndex(contentPosX)
    for i = 1, #self.cellWidthList do
        contentPosX = math.abs(contentPosX) - self.cellWidthList[i]
        if contentPosX < 0 then
            return i
        end
    end
    return #self.cellWidthList
end

function WorldTrendTimeLineMediator:UpdateRewardDot()
    if self.curDotIndex <= 2 then
        self.btnLeftRewardDot.gameObject:SetActive(false)
    end
    if self.curDotIndex >= #self.indexList - 1 then
        self.btnRightRewardDot.gameObject:SetActive(false)
    end
    local leftCount = ModuleRefer.WorldTrendModule:GetCanRewardStageLeftCount(self.curDotIndex)
    local rightCount = ModuleRefer.WorldTrendModule:GetCanRewardStageRightCount(self.curDotIndex)
    if leftCount > 0 then
        self.textLeftRewardNum.text = leftCount
        self.btnLeftRewardDot.gameObject:SetActive(true)
    else
        self.btnLeftRewardDot.gameObject:SetActive(false)
    end
    if rightCount > 0 then
        self.textRightRewardNum.text = rightCount
        self.btnRightRewardDot.gameObject:SetActive(true)
    else
        self.btnRightRewardDot.gameObject:SetActive(false)
    end
end

function WorldTrendTimeLineMediator:OnClickLeftRewardDot()
    if self.curDotIndex <= 1 then
        return
    end
    self.curDotIndex = ModuleRefer.WorldTrendModule:GetLeftRewardIndex(self.curDotIndex)
    self:MoveToStageByIndex(self.curDotIndex,0.5)
    self:UpdateRewardDot()
end

function WorldTrendTimeLineMediator:OnClickRightRewardDot()
    if self.curDotIndex >= #self.indexList then
        return
    end
    self.curDotIndex = ModuleRefer.WorldTrendModule:GetRightRewardIndex(self.curDotIndex)
    self:MoveToStageByIndex(self.curDotIndex,0.5)
    self:UpdateRewardDot()
end


return WorldTrendTimeLineMediator