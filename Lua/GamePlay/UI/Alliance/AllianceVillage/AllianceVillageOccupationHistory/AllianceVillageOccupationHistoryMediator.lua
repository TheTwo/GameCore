--- scene:scene_world_popup_occupation_history

local Delegate = require("Delegate")
local I18N = require("I18N")
local DBEntityType = require("DBEntityType")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceVillageOccupationHistoryMediatorParameter
---@field village wds.Village|wds.BehemothCage

---@class AllianceVillageOccupationHistoryMediator:BaseUIMediator
---@field new fun():AllianceVillageOccupationHistoryMediator
---@field super BaseUIMediator
local AllianceVillageOccupationHistoryMediator = class('AllianceVillageOccupationHistoryMediator', BaseUIMediator)

function AllianceVillageOccupationHistoryMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type wds.Village|wds.BehemothCage
    self._village = nil
    self._selectedTab = 0
    ---@type {prefabIdx:number, cellData:string|AllianceVillageOccupationHistoryAllianceCellData|AllianceVillageOccupationHistoryListTitleCellData|AllianceVillageOccupationHistoryListCellData}[]|nil
    self._firstCells = nil
    ---@type AllianceVillageOccupationHistoryCellData[]|nil
    self._historyCells = nil
end

function AllianceVillageOccupationHistoryMediator:OnCreate(param)
    self._p_text_title = self:Text("p_text_title", "village_info_Occupation_history")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    
    self._p_btn_first = self:Button("p_btn_first", Delegate.GetOrCreate(self, self.OnClickTabFirst))
    self._p_btn_first_status = self:StatusRecordParent("p_btn_first")
    self._p_text_first_n = self:Text("p_text_first_n", "village_info_First_occupation")
    self._p_text_first_selected = self:Text("p_text_first_selected", "village_info_First_occupation")
    self._p_btn_history = self:Button("p_btn_history", Delegate.GetOrCreate(self, self.OnClickTabHistory))
    self._p_btn_history_status = self:StatusRecordParent("p_btn_history")
    self._p_text_reward_n = self:Text("p_text_reward_n", "village_info_Occupation_history")
    self._p_text_reward_selected = self:Text("p_text_reward_selected", "village_info_Occupation_history")
    
    self._p_group_first = self:GameObject("p_group_first")
    self._p_table_first = self:TableViewPro("p_table_first")
    self._p_group_history = self:GameObject("p_group_history")
    self._p_table_history = self:TableViewPro("p_table_history")
    
    self._p_group_empty = self:GameObject("p_group_empty")
    self._p_text_empty = self:Text("p_text_empty", "village_info_No_occupied")
end

---@param param AllianceVillageOccupationHistoryMediatorParameter
function AllianceVillageOccupationHistoryMediator:OnOpened(param)
    self._village = param and param.village
    self:ChangeTab(1, true)
end

function AllianceVillageOccupationHistoryMediator:OnClickTabFirst()
    self:ChangeTab(1)
end

function AllianceVillageOccupationHistoryMediator:OnClickTabHistory()
    self:ChangeTab(2)
end

function AllianceVillageOccupationHistoryMediator:ChangeTab(tab, force)
    if self._selectedTab == tab and not force then
        return
    end
    self._selectedTab = tab
    self._p_btn_first_status:SetState(tab == 1 and 1 or 0)
    self._p_btn_history_status:SetState(tab == 2 and 1 or 0)
    self._p_group_first:SetVisible(tab == 1)
    self._p_group_history:SetVisible(tab == 2)
    local isEmpty = true
    if tab == 1 then
        self:GenerateTableFirstTab(force)
        self._p_table_first:Clear()
        for _, v in ipairs(self._firstCells) do
            self._p_table_first:AppendData(v.cellData, v.prefabIdx)
            isEmpty = false
        end
    elseif tab == 2 then
        self:GenerateTableHistoryTab(force)
        self._p_table_history:Clear()
        for _, v in ipairs(self._historyCells) do
            self._p_table_history:AppendData(v)
            isEmpty = false
        end
    end
    self._p_group_empty:SetVisible(isEmpty)
end

function AllianceVillageOccupationHistoryMediator:GenerateTableFirstTab(force)
    if not force and self._firstCells then
        return
    end
    self._firstCells = table.clear(self._firstCells) or {}
    local firstRecord = self._village and self._village.VillageWar and self._village.VillageWar.OccupyHistoryFirst
    if not firstRecord then
        return
    end
    local isBehemothCage = self._village.TypeHash == DBEntityType.BehemothCage
    if firstRecord.Basic and firstRecord.Basic.AllianceId  ~= 0 then
        local titleCell = {prefabIdx = 0, cellData = I18N.Get("village_info_First_conquest_1")}
        table.insert(self._firstCells, titleCell)
        ---@type AllianceVillageOccupationHistoryAllianceCellData
        local allianceInfo = {}
        allianceInfo.flag = firstRecord.Basic.AllianceFlag
        allianceInfo.allianceName = firstRecord.Basic.AllianceName
        allianceInfo.time = firstRecord.Basic.Time.Seconds
        local firstAllianceCell = {prefabIdx = 1, cellData = allianceInfo}
        table.insert(self._firstCells, firstAllianceCell)
    end
    if not table.isNilOrZeroNums(firstRecord.SoldierDamageRank) then
        local titleCell = {prefabIdx = 0, cellData = I18N.Get(isBehemothCage and "alliance_behemoth_challenge_gift3" or "village_info_First_conquest_2")}
        table.insert(self._firstCells, titleCell)
        local columnTitle = {[1] = I18N.Get("village_info_First_conquest_3"), [2] = I18N.Get(isBehemothCage and "alliance_behemoth_title_damage" or "village_info_First_conquest_4")}
        titleCell = {prefabIdx = 2, cellData = {column = columnTitle}}
        table.insert(self._firstCells, titleCell)
        for i, v in ipairs(firstRecord.SoldierDamageRank) do
            ---@type AllianceVillageOccupationHistoryListCellData
            local playerCell = {}
            playerCell.player = v
            playerCell.rank = i
            table.insert(self._firstCells, {prefabIdx = 3, cellData = playerCell})
        end
    end
    if not isBehemothCage and not table.isNilOrZeroNums(firstRecord.ConstructDamageRank) then
        local titleCell = {prefabIdx = 0, cellData = I18N.Get("village_info_First_conquest_5")}
        table.insert(self._firstCells, titleCell)
        local columnTitle = {[1] = I18N.Get("village_info_First_conquest_3"), [2] = I18N.Get("village_info_First_conquest_6")}
        titleCell = {prefabIdx = 2, cellData = {column = columnTitle}}
        table.insert(self._firstCells, titleCell)
        for i, v in ipairs(firstRecord.ConstructDamageRank) do
            ---@type AllianceVillageOccupationHistoryListCellData
            local playerCell = {}
            playerCell.player = v
            playerCell.rank = i
            table.insert(self._firstCells, {prefabIdx = 3, cellData = playerCell})
        end
    end
end

function AllianceVillageOccupationHistoryMediator:GenerateTableHistoryTab(force)
    if not force and self._historyCells then
        return
    end
    self._historyCells = table.clear(self._historyCells) or {}
    local history = self._village and self._village.VillageWar and self._village.VillageWar.OccupyHistory
    if not history then
        return
    end
    for _, v in ipairs(history) do
        ---@type AllianceVillageOccupationHistoryCellData
        local cell = {}
        cell.flag = v.AllianceFlag
        cell.allianceName = v.AllianceName
        cell.time = v.Time.Seconds
        table.insert(self._historyCells, cell)
    end
end

return AllianceVillageOccupationHistoryMediator