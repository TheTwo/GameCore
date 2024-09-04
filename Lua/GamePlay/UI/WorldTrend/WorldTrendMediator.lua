local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local GuideUtils = require('GuideUtils')
local ClientDataKeys = require('ClientDataKeys')
local Vector3 = CS.UnityEngine.Vector3

---@class WorldTrendMediator : BaseUIMediator
local WorldTrendMediator = class('WorldTrendMediator', BaseUIMediator)


function WorldTrendMediator:OnCreate()
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')

    self.tableviewproTableStage = self:TableViewPro('p_table_stage')
    self.scrollRect = self:ScrollRect('p_table_stage')
    self.textSeasonName = self:Text('p_text_season_name')
    self.tableviewproTableDot = self:TableViewPro('p_table_dot')

    self.goContent = self:GameObject('p_content')
    self.transStageCell = self:RectTransform('p_cell')

    self.statusRecord1 = self:StatusRecordParent("p_btn_reward_status_01")
    self.statusRecord2 = self:StatusRecordParent("p_btn_reward_status_02")

    self.sliderProgress = self:Slider('p_sld_time')
    self.bottom = self:GameObject('bottom')

    self.btnTips = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnClickTips))
end

function WorldTrendMediator:OnOpened()
    g_Game.EventManager:AddListener(EventConst.WORLD_TREND_SELECT_DOT, Delegate.GetOrCreate(self, self.OnClickDotCell))
    ModuleRefer.WorldTrendModule.PlayOpenVX = true
    self.compChildCommonBack:FeedData({
        title = I18N.Get("WorldStage_info_title")
    })
    self.stageIndex = 0
    self.cellWidth = self.transStageCell.sizeDelta.x
    self.indexList = {}
    self.curStage = ModuleRefer.WorldTrendModule:GetCurStage().Stage

    self.season = ModuleRefer.WorldTrendModule:GetCurSeason()
    local seasonConfig = ConfigRefer.WorldSeason:Find(self.season)
    if seasonConfig then
        self.textSeasonName.text = I18N.Get(seasonConfig:SeasonName())
    end
    local historyStages = ModuleRefer.WorldTrendModule:GetCurSeasonHistoryStages()
    local isGuided = ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.WorldTrendGuide)

    if #historyStages > 0 then
        if not isGuided then
            ModuleRefer.WorldTrendModule.isGuided = true
        end
        self:InitWorldTrendByHistoryStages(historyStages)
    else
        self:InitNewWorldTrend()
    end

    self.curDotIndex = self:GetIndexByStage(self.curStage)
    if ModuleRefer.WorldTrendModule.isGuided then
        self.curDotIndex = 1
        ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.WorldTrendGuide, 1)
        ModuleRefer.WorldTrendModule.isGuided = false
    end

    local param = {index = self.curDotIndex, stage = self.curStage}
    if self.curStage > 0 then
        if  self.scrollRect.enabled == false then
            self.scrollRect.enabled = true
        end
        self.bottom:SetVisible(true)
        self:MoveToStageByIndex(self.curDotIndex,0)
    else
        self.bottom:SetVisible(false)
        self.scrollRect.enabled = false
        return
    end

    self:OnClickDotCell(param)
    --g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_SELECT_DOT, param)

    if not self.checkTimer then
        self.checkTimer = TimerUtility.IntervalRepeat(function()
            self:CheckContentPos()
        end, 0.5, -1)
    end
    if not isGuided then
        GuideUtils.GotoByGuide(3048)
    end
    -- self:UpdateProgress()
end

function WorldTrendMediator:OnClose()
    ModuleRefer.WorldTrendModule.PlayOpenVX = nil
    -- if self.timer then
    --     TimerUtility.StopAndRecycle(self.timer)
    --     self.timer = nil
    -- end
    if self.checkTimer then
        TimerUtility.StopAndRecycle(self.checkTimer)
        self.checkTimer = nil
    end
    g_Game.EventManager:RemoveListener(EventConst.WORLD_TREND_SELECT_DOT, Delegate.GetOrCreate(self, self.OnClickDotCell))
    ModuleRefer.WorldTrendModule:RefreshRedPoint()
end

--没有历史数据时，初始化
function WorldTrendMediator:InitNewWorldTrend()
    local beginStage = ModuleRefer.WorldTrendModule:GetCurSeasonBeginStage()
    if beginStage <= 0 then
        return
    end
    
    self.tableviewproTableStage:Clear()
    self.tableviewproTableDot:Clear()
    local isOpen = self.curStage > 0 and true or false
    local curStage = beginStage
    self:InitStageCell(curStage, isOpen, true)
end

function WorldTrendMediator:InitWorldTrendByHistoryStages(historyStages)
    local lastStage = -1
    self.tableviewproTableStage:Clear()
    self.tableviewproTableDot:Clear()
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

function WorldTrendMediator:InitStageCell(curStage, isOpen, isRecursion, lastStage)
    lastStage = lastStage or -1
    isRecursion = isRecursion or false
    ---@type WorldTrendStageCellParam
    self.stageIndex = self.stageIndex + 1
    local isSpecial = false
    if ModuleRefer.WorldTrendModule.isGuided then
        isSpecial = true
    end
    local param = {lastStage = lastStage, stage = curStage, curMaxStage = self.curStage, isOpen = isOpen, index = self.stageIndex}
    self.tableviewproTableStage:AppendData(param)
    
    if isSpecial then
        param = {lastStage = lastStage, stage = curStage, curMaxStage = 1, isOpen = isOpen, index = self.stageIndex}
    else
        param = {lastStage = lastStage, stage = curStage, curMaxStage = self.curStage, isOpen = isOpen, index = self.stageIndex}
    end
    self.tableviewproTableDot:AppendData(param)
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

---@param param WorldTrendSelectDotCellParam
function WorldTrendMediator:OnClickDotCell(param)
    if not param.index then
        return
    end
    if self.curDotIndex ~= param.index then
        self.curDotIndex = param.index
        self:MoveToStageByIndex(self.curDotIndex,0.4)
    end
end

function WorldTrendMediator:MoveToStageByIndex(index,delay)
    local targetPosX = (index - 1) * (self.cellWidth + self.tableviewproTableStage.spacing.x)
    self.goContent.transform:DOLocalMoveX(-targetPosX - self.cellWidth / 2, delay)
    -- self.goContent.transform.localPosition = Vector3(-targetPosX, 0, 0)
    -- self.goContent.transform.anchoredPosition = CS.UnityEngine.Vector2(self.goContent.transform.anchoredPosition.x, 0)
end

function WorldTrendMediator:CheckContentPos()
    local contentPosX = self.goContent.transform.localPosition.x
    local targetIndex = math.floor(math.abs(contentPosX) / self.cellWidth) + 1
    if targetIndex ~= self.curDotIndex then
        self.curDotIndex = targetIndex
        ---@type WorldTrendSelectDotCellParam
        local param = {index = self.curDotIndex}
        g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_SELECT_DOT, param)
    end
end

function WorldTrendMediator:GetIndexByStage(stage)
    for i = 1, #self.indexList do
        if self.indexList[i] == stage then
            return i
        end
    end
    return 1
end

function WorldTrendMediator:UpdateProgress()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local beginStageOpenTime = ModuleRefer.WorldTrendModule:GetStageOpenTime(ModuleRefer.WorldTrendModule:GetCurSeasonBeginStage())
    local lastStageOpenTime = ModuleRefer.WorldTrendModule:GetStageOpenTime(ModuleRefer.WorldTrendModule:GetCurSeasonLastStage())
    if beginStageOpenTime > 0 and lastStageOpenTime > 0 and lastStageOpenTime > beginStageOpenTime then
        self.sliderProgress.value = (curTime - beginStageOpenTime) / (lastStageOpenTime - beginStageOpenTime)
    end
end

function WorldTrendMediator:OnClickTips()
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnTips.transform, content = I18N.Get("WorldStage_Help_tips")})
end

return WorldTrendMediator