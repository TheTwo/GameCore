--- scene:scene_league_popup_troop_war

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local ConfigRefer = require("ConfigRefer")
local AllianceActivityWarTroopListPopupCellData = require("AllianceActivityWarTroopListPopupCellData")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceActivityWarTroopListPopupMediator:BaseUIMediator
---@field new fun():AllianceActivityWarTroopListPopupMediator
---@field super BaseUIMediator
local AllianceActivityWarTroopListPopupMediator = class('AllianceActivityWarTroopListPopupMediator', BaseUIMediator)

function AllianceActivityWarTroopListPopupMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type wds.AllianceActivityBattleInfo
    self._battleData = nil
    ---@type AllianceActivityWarTroopListPopupCellData[]
    self._cellsData = {}
end

function AllianceActivityWarTroopListPopupMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")
    self._p_text_troop = self:Text("p_text_troop")
    self._p_table_troop = self:TableViewPro("p_table_troop")
end

function AllianceActivityWarTroopListPopupMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceActivityWarTroopListPopupMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleChanged))
end

---@param param wds.AllianceActivityBattleInfo
function AllianceActivityWarTroopListPopupMediator:OnOpened(param)
    self._battleData = param
    ---@type CommonBackButtonData
    local exitBtnData = {}
    exitBtnData.title = I18N.Get("alliance_battle_hud14")
    self._child_popup_base_l:FeedData(exitBtnData)
    self:GenerateTable()
    self:RefreshUI()
end

function AllianceActivityWarTroopListPopupMediator:GenerateTable()
    local allowEdit = self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated
    local isAdmin = ModuleRefer.AllianceModule:IsAllianceLeader() and allowEdit
    local selfPlayerId = ModuleRefer.PlayerModule.playerId
    local battleId = self._battleData.ID
    local memberDic = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    self._p_table_troop:Clear()
    table.clear(self._cellsData)
    for _, v in pairs(self._battleData.Members) do
        local cellData = AllianceActivityWarTroopListPopupCellData.new(v)
        cellData._isSelf = selfPlayerId == v.PlayerId and allowEdit
        cellData._adminMode = isAdmin
        cellData._battleId = battleId
        cellData._memberInfo = memberDic[v.FacebookId]
        table.insert(self._cellsData, cellData)
        self._p_table_troop:AppendData(cellData)
    end
end

function AllianceActivityWarTroopListPopupMediator:RefreshTable()
    local allowEdit = self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated
    local isAdmin = ModuleRefer.AllianceModule:IsAllianceLeader()
    local selfPlayerId = ModuleRefer.PlayerModule.playerId
    local battleId = self._battleData.ID
    local memberDic = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    ---@type table<number, wds.AllianceBattleMemberInfo>
    local newTableData = {}
    ---@type wds.AllianceBattleMemberInfo[]
    local addCells = {}
    if (self._battleData.Members) then
        for _,v in pairs(self._battleData.Members) do
            newTableData[v.PlayerId] = v
            table.insert(addCells, v)
        end
    end
    local currentTableData = {}
    for i = #self._cellsData, 1, -1 do
        local cellData = self._cellsData[i]
        local newData = newTableData[cellData._memberData.PlayerId]
        if not newData then
            cellData:OnRemFromTable(self._p_table_troop)
            self._p_table_troop:RemData(cellData)
            table.remove(self._cellsData, i)
        else
            cellData:UpdateData(self._p_table_troop, newData)
            cellData._adminMode = isAdmin and allowEdit
            cellData._isSelf = selfPlayerId == cellData._memberData.PlayerId and allowEdit
            currentTableData[newData.PlayerId] = cellData
            self._p_table_troop:UpdateData(cellData)
        end
    end
    for i = 1, #addCells do
        local addData = addCells[i]
        local hasData = currentTableData[addData.PlayerId]
        if not hasData then
            local addCellData = AllianceActivityWarTroopListPopupCellData.new(addData)
            addCellData._isSelf = selfPlayerId == addData.PlayerId and allowEdit
            addCellData._adminMode = isAdmin and allowEdit
            addCellData._battleId = battleId
            addCellData._memberInfo = memberDic[addData.FacebookId]
            table.insert(self._cellsData, addCellData)
            self._p_table_troop:AppendData(addCellData)
        end
    end
end

function AllianceActivityWarTroopListPopupMediator:RefreshUI()
    local battleConfig = ConfigRefer.AllianceBattle:Find(self._battleData.CfgId)
    local memberCount = table.nums(self._battleData.Members)
    self._p_text_troop.text = I18N.GetWithParams("alliance_battle_hud9", memberCount, battleConfig:MaxJoinMemberCount())
end

---@param entity wds.Alliance
function AllianceActivityWarTroopListPopupMediator:OnBattleChanged(entity, changedData)
    if not self._battleData then
        return
    end
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    if ModuleRefer.AllianceModule:GetAllianceId() ~= entity.ID then
        return
    end
    local battleId = self._battleData.ID
    if not changedData[self._battleData.ID] then
        return
    end
    self._battleData = ModuleRefer.AllianceModule:GetMyAllianceActivityBattleById(battleId)
    self:RefreshUI()
    self:RefreshTable()
end

function AllianceActivityWarTroopListPopupMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

return AllianceActivityWarTroopListPopupMediator