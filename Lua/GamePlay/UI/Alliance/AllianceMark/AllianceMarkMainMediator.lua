--- scene:scene_league_popup_mark

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceMarkMainMediator:BaseUIMediator
---@field new fun():AllianceMarkMainMediator
---@field super BaseUIMediator
local AllianceMarkMainMediator = class('AllianceMarkMainMediator', BaseUIMediator)

AllianceMarkMainMediator.TabPersonal = 1
AllianceMarkMainMediator.TabAlliance = 2

function AllianceMarkMainMediator:ctor()
    BaseUIMediator.ctor(self)
    self._tab = nil
    ---@type table<number, AllianceMarkMainCellData>
    self._tabCells = {}
    self._eventAdd = false
    ---@type table<number, boolean>
    self._toRemoveRedDotMark = {}
end

function AllianceMarkMainMediator:OnCreate(param)
    ---@type CommonPopupBackMediumComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")
    self._p_group_none = self:GameObject("p_group_none")
    self._p_text_none = self:Text("p_text_none", "alliance_bj_meiyou")
    self._p_btn_player = self:Button("p_btn_player", Delegate.GetOrCreate(self, self.OnClickPlayerTab))
    self._p_btn_player_status = self:StatusRecordParent("p_btn_player")
    self._p_text_player = self:Text("p_text_player", "alliance_bj_geren")
    self._p_text_select_player = self:Text("p_text_select_player", "alliance_bj_geren")
    ---@type NotificationNode
    self._child_reddot_default_player = self:LuaObject("child_reddot_default_player")
    self._p_btn_league = self:Button("p_btn_league", Delegate.GetOrCreate(self, self.OnClickAllianceTab))
    self._p_btn_league_status = self:StatusRecordParent("p_btn_league")
    self._p_text_league = self:Text("p_text_league", "alliance_bj_lianmeng")
    self._p_text_select_league = self:Text("p_text_select_league", "alliance_bj_lianmeng")
    ---@type NotificationNode
    self._child_reddot_default_alliance = self:LuaObject("child_reddot_default_alliance")
    self._p_table_mark = self:TableViewPro("p_table_mark")
end

function AllianceMarkMainMediator:OnOpened(data)
    ---@type CommonBackButtonData
    local titleData = {}
    titleData.title = I18N.Get("league_hud_mark")
    self._child_popup_base_l:FeedData(titleData)
    self:OnClickAllianceTab()
    self:SetupEvents(true)
end

function AllianceMarkMainMediator:OnClose(data)
    self:SetupEvents(false)
end

function AllianceMarkMainMediator:OnClickPlayerTab()
    if self._tab == AllianceMarkMainMediator.TabPersonal then
        return
    end
    self._tab = AllianceMarkMainMediator.TabPersonal
    self._p_btn_player_status:SetState(1)
    self._p_btn_league_status:SetState(0)
    self:GenerateTable()
end

function AllianceMarkMainMediator:OnClickAllianceTab()
    if self._tab == AllianceMarkMainMediator.TabAlliance then
        return
    end
    self._tab = AllianceMarkMainMediator.TabAlliance
    self._p_btn_player_status:SetState(0)
    self._p_btn_league_status:SetState(1)
    self:GenerateTable()
end

function AllianceMarkMainMediator:GenerateTable()
    self._p_table_mark:Clear()
    table.clear(self._tabCells)
    local cellCount = 0
    if self._tab == AllianceMarkMainMediator.TabAlliance then
        local labelData =  ModuleRefer.AllianceModule:GetMyAllianceMapLabels()
        for i, v in pairs(labelData) do
            ---@type AllianceMarkMainCellData
            local cellData = {}
            cellData.id = i
            cellData.serverData = v
            cellCount = cellCount + 1
            self._tabCells[i] = cellData
        end
        if cellCount > 0 then
            ---@type AllianceMarkMainCellData[]
            local cells = self:RefreshAllianceCellIndex(self._tabCells)
            for _, cell in ipairs(cells) do
                self._p_table_mark:AppendData(cell)
            end
        end
    else
        
    end
    self._p_group_none:SetVisible(cellCount <= 0)
end

---@param a AllianceMarkMainCellData
---@param b AllianceMarkMainCellData
function AllianceMarkMainMediator.CompareAllianceMarkCell(a, b )
    return a.serverData.Time.ServerSecond > b.serverData.Time.ServerSecond
end

---@param cellsTable table<number, AllianceMarkMainCellData>
---@return AllianceMarkMainCellData[]
function AllianceMarkMainMediator:RefreshAllianceCellIndex(cellsTable)
    ---@type AllianceMarkMainCellData[]
    local cells = {}
    for _, v in pairs(cellsTable) do
        table.insert(cells, v)
    end
    table.sort(cells, AllianceMarkMainMediator.CompareAllianceMarkCell)
    return cells
end

function AllianceMarkMainMediator:OnShow(param)
    if self._tab then
      self:GenerateTable()  
    end
    self:SetupEvents(true)
end

function AllianceMarkMainMediator:OnHide(param)
    ModuleRefer.AllianceModule:RemoveLabelUnReadNotify(self._toRemoveRedDotMark)
    table.clear(self._toRemoveRedDotMark)
    self:SetupEvents(false)
end

function AllianceMarkMainMediator:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceMapLabelDataChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceMapLabelDataChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    end
end

---@param entity wds.Alliance
function AllianceMarkMainMediator:OnAllianceMapLabelDataChanged(entity, add, remove, change)
    if self._tab ~= AllianceMarkMainMediator.TabAlliance or entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() or not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    if remove then
        for i, v in pairs(remove) do
            local removeData = self._tabCells[i]
            if removeData then
                self._tabCells[i] = nil
                self._p_table_mark:RemData(removeData)
            end
        end
    end
    if change then
        for i, v in pairs(change) do
            local toUpdate = self._tabCells[i]
            if toUpdate then
                toUpdate.serverData = v[2]
                self._p_table_mark:UpdateData(toUpdate)
            end
        end
    end
    if add then
        for i, v in pairs(add) do
            ---@type AllianceMarkMainCellData
            local cellData = {}
            cellData.id = i
            cellData.serverData = v
            self._p_table_mark:InsertData(0, cellData)
            self._tabCells[i] = cellData
        end
    end
    local cellCount = table.nums(self._tabCells)
    self._p_group_none:SetVisible(cellCount <= 0)
    if cellCount > 0 then
        self._p_table_mark:UpdateOnlyAllDataImmediately()
    end
end

function AllianceMarkMainMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

function AllianceMarkMainMediator:MarkToCancelRedDot(id)
    self._toRemoveRedDotMark[id] = true
end

return AllianceMarkMainMediator