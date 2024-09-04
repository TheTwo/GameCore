local BaseUIComponent = require("BaseUIComponent")
local EarthRevivalDefine = require("EarthRevivalDefine")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local AllianceTaskItemDataProvider = require("AllianceTaskItemDataProvider")
local TaskItemDataProvider = require("TaskItemDataProvider")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local CommonLeaderboardPopupDefine = require("CommonLeaderboardPopupDefine")
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local I18N = require("I18N")
local TaskListSortHelper = require("TaskListSortHelper")
local TimerUtility = require("TimerUtility")
local GuideUtils = require("GuideUtils")
local ItemPopType = require("ItemPopType")
---@class EarthRevivalNews : BaseUIComponent
local EarthRevivalTask = class("EarthRevivalTask", BaseUIComponent)

local CELL_MAX_HEIGHT = 616
local CONDITION_NORMAL_HEIGHT = 316
local CONDITION_FIX_HEIGHT_COUNT = 166      --condition节点中三个固定节点的高度

function EarthRevivalTask:ctor()
    ---@type EarthRevivalTaskCellParam[]
    self.taskDataCells = {}
    ---@type EarthRevivalTaskCellParam[]
    self.tableTaskDataCells = {}
    ---@type table<number, number>
    self.taskId2TaskDataCellIndex = {}
end

function EarthRevivalTask:OnCreate()
    self.textLabelTimer = self:Text('p_text_level')
    self.luaTimer = self:LuaObject('child_time')
    self.textPoints = self:Text('p_text_lv')
    self.tableProgress = self:TableViewPro('p_table_progress')
    self.tableDates = self:TableViewPro('p_table_day')
    self.btnTabPlayer = self:Button('p_btn_player', Delegate.GetOrCreate(self, self.OnBtnTabPlayerClick))
    self.goTabPlayerSelected = self:GameObject('p_base_a_player')
    self.textTabPlayerSelected = self:Text('p_text_a_player', 'worldstage_geren')
    self.goTabPlayerUnselected = self:GameObject('p_base_b_player')
    self.textTabPlayerUnselected = self:Text('p_text_b_player', 'worldstage_geren')
    self.btnTabAlliance = self:Button('p_btn_league', Delegate.GetOrCreate(self, self.OnBtnTabAllianceClick))
    self.goTabAllianceSelected = self:GameObject('p_base_a_league')
    self.textTabAllianceSelected = self:Text('p_text_a_league', 'worldstage_lianmeng')
    self.goTabAllianceUnselected = self:GameObject('p_base_b_league')
    self.textTabAllianceUnselected = self:Text('p_text_b_league', 'worldstage_lianmeng')
    self.tableTask = self:TableViewPro('p_table_item')
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnRightClick))
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnLeftClick))
    self.btnRank = self:Button('p_btn_rank', Delegate.GetOrCreate(self, self.OnBtnRankClick))
    self.btnShop = self:Button('p_btn_shop', Delegate.GetOrCreate(self, self.OnBtnShopClick))

    self.textRank = self:Text('p_text_rank', 'worldstage_rank')
    self.textTimeline = self:Text('p_text_timeline', 'worldstage_timeline')

    self.luaReddotPlayer = self:LuaObject('p_reddot_player')
    self.luaReddotAlliance = self:LuaObject('p_reddot_league')

    self.btnTimeline = self:Button('p_btn_timeline', Delegate.GetOrCreate(self, self.OnBtnTimelineClick))
    self.reddotTimeline = self:LuaObject('p_reddot_timeline')
    self.tableviewproTimeline = self:TableViewPro('p_table_timeline')
    self.rectTimeLine = self:RectTransform('p_table_timeline')
    self.textTemplate = self:Text('p_text_table_template')

    self.goJoinAlliance = self:GameObject('p_add_alliance')
    self.textHintAlliance = self:Text('p_text_add_alliance', 'worldstage_qjrlm')
    self.textBtnJoinAlliance = self:Text('p_text', 'worldstage_jrlm')
    self.btnJoinAlliance = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.OnBtnJoinAllianceClick))

    self.tabStateCtrler = {
        [EarthRevivalDefine.TaskTabType.Player] = {
            select = {
                go = self.goTabPlayerSelected,
                text = self.textTabPlayerSelected,
            },
            unselect = {
                go = self.goTabPlayerUnselected,
                text = self.textTabPlayerUnselected,
            },
        },
        [EarthRevivalDefine.TaskTabType.Alliance] = {
            select = {
                go = self.goTabAllianceSelected,
                text = self.textTabAllianceSelected,
            },
            unselect = {
                go = self.goTabAllianceUnselected,
                text = self.textTabAllianceUnselected,
            },
        },
    }

end

function EarthRevivalTask:OnShow()
    self.reddotTimeline:SetVisible(ModuleRefer.WorldTrendModule:IsWorldTrendCanReward())
    g_Game.EventManager:TriggerEvent(EventConst.UPDATE_WORLD_TREND_STAGE_REWARD)
    g_Game.EventManager:AddListener(EventConst.ON_EARTH_REVIVAL_TASK_DAY_SELECT, Delegate.GetOrCreate(self, self.OnDayTabSelect))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans.MsgPath, Delegate.GetOrCreate(self, self.OnPlanInfoChanged))
end

function EarthRevivalTask:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_EARTH_REVIVAL_TASK_DAY_SELECT, Delegate.GetOrCreate(self, self.OnDayTabSelect))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans.MsgPath, Delegate.GetOrCreate(self, self.OnPlanInfoChanged))
end

function EarthRevivalTask:OnFeedData()
    self.normalHeight = self.textTemplate.rectTransform.sizeDelta.y
    self.normalWidth = self.textTemplate.rectTransform.sizeDelta.x
    self.selectedStage = ModuleRefer.EarthRevivalModule.taskModule:GetCurrentStage()
    self.selectedTab = EarthRevivalDefine.TaskTabType.Player
    self.selectedDay = ModuleRefer.EarthRevivalModule.taskModule:GetCurrentDayOffsetByCfgId(self.selectedStage)
    self.openedStages = ModuleRefer.EarthRevivalModule.taskModule:GetCurrentOpenedStages()
    self:UpdateTaskTab()
    self:UpdateTimer()
    self:UpdateProcess()
    self:UpdatePaginator()
    self:UpdateTabReddot()
    self:UpdateTimeLine()
    self:SwitchToTab(self.selectedTab)
end

---@param a EarthRevivalTaskCellParam
---@param b EarthRevivalTaskCellParam
function EarthRevivalTask.TaskSorter(a, b)
    local TaskStatePriority = {
        [wds.TaskState.TaskStateFinished] = 2,
        [wds.TaskState.TaskStateCanFinish] = 4,
        [wds.TaskState.TaskStateReceived] = 3,
        [wds.TaskState.TaskStateCanReceive] = 1,
        [wds.TaskState.TaskStateInit] = 0,
    }
    local aPriority = TaskStatePriority[a.provider:GetTaskState()]
    local bPriority = TaskStatePriority[b.provider:GetTaskState()]
    local aUnlock = a.unlockDay <= a.curDay
    local bUnlock = b.unlockDay <= b.curDay
    if aUnlock and bUnlock then
        if aPriority ~= bPriority then
            return aPriority > bPriority
        else
            local aTId = a.provider:GetTaskCfgId()
            local bTId = b.provider:GetTaskCfgId()
            local aLink = ModuleRefer.EarthRevivalModule.taskModule:GetLinkIdByTaskId(aTId)
            local bLink = ModuleRefer.EarthRevivalModule.taskModule:GetLinkIdByTaskId(bTId)
            if aLink and bLink and aLink ~= bLink then
                return aLink < bLink
            elseif aLink and not bLink then
                return true
            elseif not aLink and bLink then
                return false
            else
                return aTId < bTId
            end
        end
    else
        return a.unlockDay < b.unlockDay
    end
end

function EarthRevivalTask:UpdateTaskTable()
    local taskList = ModuleRefer.EarthRevivalModule.taskModule:GetTaskListByCfgId(self.selectedStage)
    ---@type EarthRevivalTaskCellParam[]
    self.taskDataCells = {}
    local dayKeys = ModuleRefer.EarthRevivalModule.taskModule:GetDayKeysByCfgId(self.selectedStage)
    if self.selectedTab == EarthRevivalDefine.TaskTabType.Player then
        for _, key in ipairs(dayKeys) do
            local list = taskList[key].playerTasks or {}
            for _, task in ipairs(list) do
                ---@type EarthRevivalTaskCellParam
                local cell = {}
                cell.provider = TaskItemDataProvider.new(task)
                cell.curDay = self.selectedDay
                cell.unlockDay = key
                table.insert(self.taskDataCells, cell)
            end
        end
    else
        for _, key in ipairs(dayKeys) do
            local list = taskList[key].allianceTasks or {}
            for _, task in ipairs(list) do
                ---@type EarthRevivalTaskCellParam
                local cell = {}
                cell.provider = AllianceTaskItemDataProvider.new(task)
                cell.curDay = self.selectedDay
                cell.unlockDay = key
                table.insert(self.taskDataCells, cell)
            end
        end
    end
    table.sort(self.taskDataCells, self.TaskSorter)
    for i, task in ipairs(self.taskDataCells) do
        self.taskId2TaskDataCellIndex[task.provider:GetTaskCfgId()] = i
    end
    self.tableTask:Clear()
    table.clear(self.tableTaskDataCells)
    local index = 1
    for _, task in ipairs(self.taskDataCells) do
        if not ModuleRefer.EarthRevivalModule.taskModule:CanLinkTaskDisplay(task.provider:GetTaskCfgId()) then
            goto continue
        end
        local curIndex = index
        task.provider:SetClaimCallback(function ()
            local nextTid = ModuleRefer.EarthRevivalModule.taskModule:GetNextTaskIdInLink(task.provider:GetTaskCfgId())
            if nextTid then
                local nextCellIndex = self.taskId2TaskDataCellIndex[nextTid]
                if nextCellIndex then
                    local nextCell = self.taskDataCells[nextCellIndex]
                    nextCell.provider.claimCallback = task.provider.claimCallback
                    self:UpdateTaskTableCell(curIndex, nextCell)
                end
            else
                self:UpdateTaskTable()
            end
            self:UpdateTaskTab()
            self:UpdateTabReddot()
            local data = wrpc.PushRewardRequest.New(nil, wds.enum.ItemProfitType.ItemAddByOpenBox, ItemPopType.PopTypeLightReward,nil)
            data.ItemID:Add(EarthRevivalDefine.ProgressItemId)
            data.ItemCount:Add(200)
            ModuleRefer.RewardModule:ShowLightReward(data)
        end)
        table.insert(self.tableTaskDataCells, task)
        self.tableTask:AppendData(task)
        index = index + 1
        ::continue::
    end
    ModuleRefer.EarthRevivalModule.taskModule:UpdateReddot()
end

---@param i number
---@param cell EarthRevivalTaskCellParam
function EarthRevivalTask:UpdateTaskTableCell(i, cell)
    local oldCell = self.tableTaskDataCells[i]
    for k, _ in pairs(oldCell) do
        oldCell[k] = cell[k]
    end
    self.tableTask:UpdateData(oldCell)
end

function EarthRevivalTask:UpdateTaskTab()
    local days = ModuleRefer.EarthRevivalModule.taskModule:GetTaskDaysByCfgId(self.selectedStage)
    self.tableDates:Clear()
    for _, day in ipairs(days) do
        ---@type EarthRevivalTaskDayTabCellData
        local data = {}
        data.day = day
        data.isLock = day > ModuleRefer.EarthRevivalModule.taskModule:GetCurrentDayOffsetByCfgId(self.selectedStage)
        data.isSelect = day == self.selectedDay
        local playerTaskCanClaim, allianceTaskCanClaim = ModuleRefer.EarthRevivalModule.taskModule:IsAnyTaskCanClaimByCfgIdAndDay(self.selectedStage, day)
        data.isNotify = (playerTaskCanClaim or allianceTaskCanClaim) and not data.isLock
        self.tableDates:AppendData(data)
    end
    ModuleRefer.EarthRevivalModule.taskModule:UpdateReddot()
end

function EarthRevivalTask:UpdateProcess()
    local curPoints = ModuleRefer.EarthRevivalModule.taskModule:GetCurrentTaskPoints(self.selectedStage)
    self.textPoints.text = curPoints
    self.tableProgress:Clear()
    for i, rewardId in ipairs(ModuleRefer.EarthRevivalModule.taskModule:GetProgressRewardsByCfgId(self.selectedStage)) do
        ---@type EarthRevivalTaskRewardChestCellParam
        local data = {}
        data.neededPoints = ConfigRefer.WorldStageTaskPlan:Find(self.selectedStage):ProgressValue(i)
        data.canClaim = curPoints >= data.neededPoints and not ModuleRefer.EarthRevivalModule.taskModule:IsProcessRewardClaimed(self.selectedStage, data.neededPoints)
        data.claimed = ModuleRefer.EarthRevivalModule.taskModule:IsProcessRewardClaimed(self.selectedStage, data.neededPoints)
        data.index = i
        data.rewardId = rewardId
        data.selectedStage = self.selectedStage
        data.lastNeededPoints = i > 1 and ConfigRefer.WorldStageTaskPlan:Find(self.selectedStage):ProgressValue(i - 1) or 0
        data.curPoints = curPoints
        self.tableProgress:AppendData(data)
    end
end

function EarthRevivalTask:UpdateTimer()
    self.textLabelTimer.text = ModuleRefer.EarthRevivalModule.taskModule:GetStageDesc(self.selectedStage)
    ---@type CommonTimerData
    local data = {}
    data.endTime = ModuleRefer.EarthRevivalModule.taskModule:GetTaskEndTimeInSecByCfgId(self.selectedStage)
    data.needTimer = true
    self.luaTimer:FeedData(data)
end

function EarthRevivalTask:UpdatePaginator()
    local selectIndex = table.indexof(self.openedStages, self.selectedStage, 1)
    self.btnLeft:SetVisible(false)
    self.btnRight:SetVisible(false)
end

function EarthRevivalTask:UpdateTabReddot()
    local isPlayerTaskCanClaim, isAllianceTaskCanClaim = ModuleRefer.EarthRevivalModule.taskModule:IsAnyTaskCanClaimByCfgId(self.selectedStage)
    self.luaReddotPlayer:SetVisible(isPlayerTaskCanClaim)
    self.luaReddotAlliance:SetVisible(isAllianceTaskCanClaim)
end

function EarthRevivalTask:UpdateTimeLine()
    self.tableviewproTimeline:Clear()
    local curStage = ModuleRefer.WorldTrendModule:GetCurStage()
    if curStage.Stage == 0 then
        return
    end
    local cellHeight = self:GetCellHeight(curStage.Stage)
    self.tableviewproTimeline:AppendDataEx(curStage.Stage, 0, cellHeight, 1)
    local historyStages = ModuleRefer.WorldTrendModule:GetCurSeasonHistoryStages()
    for i = #historyStages, 1, -1 do
        self.tableviewproTimeline:AppendData(historyStages[i].Stage, 0)
    end
    self.rectTimeLine.sizeDelta = CS.UnityEngine.Vector2(self.rectTimeLine.sizeDelta.x + 1, self.rectTimeLine.sizeDelta.y)
    self.tableviewproTimeline:RefreshAllShownItem()
end

function EarthRevivalTask:SwitchToStage(stage)
    self.selectedStage = stage
    self.selectedDay = ModuleRefer.EarthRevivalModule.taskModule:GetCurrentDayOffsetByCfgId(self.selectedStage)
    self:UpdateTaskTab()
    self:UpdateTimer()
    self:UpdateProcess()
    self:UpdatePaginator()
    self:UpdateTaskTable()
    self:UpdateTabReddot()
end

function EarthRevivalTask:OnTaskClaim()
end

function EarthRevivalTask:OnDayTabSelect(day)
    self.selectedDay = day
    self:UpdateTaskTable()
    self:UpdateTabReddot()
end

function EarthRevivalTask:OnPlanInfoChanged()
    self:UpdateProcess()
end

function EarthRevivalTask:OnBtnTabPlayerClick()
    self:SwitchToTab(EarthRevivalDefine.TaskTabType.Player)
    self.goJoinAlliance:SetActive(false)
    self.tableTask.gameObject:SetActive(true)
end

function EarthRevivalTask:OnBtnTabAllianceClick()
    self:SwitchToTab(EarthRevivalDefine.TaskTabType.Alliance)
    local isInAlliance = ModuleRefer.AllianceModule:IsInAlliance()
    self.goJoinAlliance:SetActive(not isInAlliance)
    self.tableTask.gameObject:SetActive(isInAlliance)
end

function EarthRevivalTask:OnBtnLeftClick()
    local selectIndex = table.indexof(self.openedStages, self.selectedStage, 1)
    self:SwitchToStage(self.openedStages[selectIndex - 1])
end

function EarthRevivalTask:OnBtnRightClick()
    local selectIndex = table.indexof(self.openedStages, self.selectedStage, 1)
    self:SwitchToStage(self.openedStages[selectIndex + 1])
end

function EarthRevivalTask:OnBtnShopClick()
    g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator)
end

function EarthRevivalTask:SwitchToTab(tabType)
    self.selectedTab = tabType
    for k, v in pairs(self.tabStateCtrler) do
        v.select.go:SetActive(k == tabType)
        v.unselect.go:SetActive(k ~= tabType)
    end
    self:UpdateTaskTable()
end

function EarthRevivalTask:OnBtnRankClick()
    ---@type CommonLeaderboardPopupMediatorParam
    local data = {}
    data.leaderboardDatas = {}
    for _, stage in ipairs(ModuleRefer.EarthRevivalModule.taskModule:GetCurrentOpenedStages()) do
        local playerLeaderboardId = ConfigRefer.WorldStageTaskPlan:Find(stage):PlayerLeaderboardReward()
        local allianceLeaderboardId = ConfigRefer.WorldStageTaskPlan:Find(stage):AllianceLeaderboardReward()
        local leaderboardData = {
            cfgIds = {playerLeaderboardId, allianceLeaderboardId},
            stageName = ModuleRefer.EarthRevivalModule.taskModule:GetStageDesc(stage),
        }
        table.insert(data.leaderboardDatas, leaderboardData)
    end
    data.leaderboardTitles = { 'worldstage_geren', 'worldstage_lianmeng' }
    data.rewardsTitles = { 'worldstage_geren', 'worldstage_lianmeng' }
    data.rewardsTitleHint = I18N.Get('worldstage_phfj')
    data.style = CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD | CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD
    data.title = "worldstage_jfph"
    g_Game.UIManager:Open(UIMediatorNames.CommonLeaderboardPopupMediator, data)
end

function EarthRevivalTask:OnBtnJoinAllianceClick()
    GuideUtils.GotoByGuide(1071)
end

function EarthRevivalTask:OnBtnTimelineClick()
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLineMediator)
end

function EarthRevivalTask:GetCellHeight(stageID)
    local stageConfig = ConfigRefer.WorldStage:Find(stageID)
    if not stageConfig then
        return 0
    end
    if stageConfig:BranchKingdomTasksLength() > 1 then
        local content_1 = self:GetTaskDesc(stageConfig:BranchKingdomTasks(1))
        local settings_1 = self.textTemplate:GetGenerationSettings(CS.UnityEngine.Vector2(0, self.textTemplate:GetPixelAdjustedRect().size.y))
        local width_1 = self.textTemplate.cachedTextGeneratorForLayout:GetPreferredWidth(content_1, settings_1) / self.textTemplate.pixelsPerUnit
        local height_1 = (math.floor(width_1 / self.normalWidth) + 1) * self.normalHeight

        local content_2 = self:GetTaskDesc(stageConfig:BranchKingdomTasks(2))
        local settings_2 = self.textTemplate:GetGenerationSettings(CS.UnityEngine.Vector2(0, self.textTemplate:GetPixelAdjustedRect().size.y))
        local width_2 = self.textTemplate.cachedTextGeneratorForLayout:GetPreferredWidth(content_2, settings_2) / self.textTemplate.pixelsPerUnit
        local height_2 = (math.floor(width_2 / self.normalWidth) + 1) * self.normalHeight
        
        return CELL_MAX_HEIGHT - CONDITION_NORMAL_HEIGHT + CONDITION_FIX_HEIGHT_COUNT + height_1 + height_2
    end
    return CELL_MAX_HEIGHT - CONDITION_NORMAL_HEIGHT
end

function EarthRevivalTask:GetTaskDesc(taskID)
    local taskCfg = ConfigRefer.KingdomTask:Find(taskID)
    if not taskCfg then
        return string.Empty
    end
    local WorldTrendDefine = require("WorldTrendDefine")
    return ModuleRefer.WorldTrendModule:GetTaskDesc(taskCfg, WorldTrendDefine.TASK_TYPE.Global)
end

return EarthRevivalTask