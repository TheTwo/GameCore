local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local AllianceWarBuildingCellDataVillageWar = require("AllianceWarBuildingCellDataVillageWar")

---@class AllianceWarTabBuilding
---@field new fun(host:AllianceWarMediator, nodeName:string):AllianceWarTabBuilding
local AllianceWarTabBuilding = class('AllianceWarTabBuilding')

---@param host AllianceWarMediator
function AllianceWarTabBuilding:ctor(host, nodeName)
    self._host = host
    self._p_root = host:GameObject(nodeName)
    self._p_table = host:TableViewPro("p_table_building")
    ---@type AllianceWarBuildingCellData[]
    self._tableData = {}
end

function AllianceWarTabBuilding:OnEnter()
    self._p_root:SetVisible(true)
    self._p_table:Clear()
    self:GenerateCellsData()
    for _, cellData in ipairs(self._tableData) do
        self._p_table:AppendData(cellData)
    end
    self._host:SetTabHasData(#self._tableData > 0)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnWarDataChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnOwnWarDataChange))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnWarDataChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnOwnWarDataChange))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnWarDataChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnOwnWarDataChange))
end

function AllianceWarTabBuilding:OnExit()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnWarDataChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnOwnWarDataChange))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnWarDataChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnOwnWarDataChange))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnWarDataChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnOwnWarDataChange))

    self._p_table:Clear()
    self._p_root:SetVisible(false)
end

function AllianceWarTabBuilding:GenerateCellsData()
    table.clear(self._tableData)
    local villageWars = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    local gateWars = ModuleRefer.AllianceModule:GetMyAllianceGateWars()
    local ownVillageWars = ModuleRefer.AllianceModule:GetMyAllianceOwnVillageWar()
    local behemothWars = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()
    local ownBehemothWars = ModuleRefer.AllianceModule:GetMyAllianceOwnedBehemothCageWar()
    ---@type AllianceWarBuildingCellDataVillageWar[]
    local toAddArray = {}
    for id, v in pairs(villageWars) do
        local addCell = AllianceWarBuildingCellDataVillageWar.new(id)
        addCell:UpdateData(v, false)
        table.insert(toAddArray, addCell)
    end
    for id, v in pairs(gateWars) do
        local addCell = AllianceWarBuildingCellDataVillageWar.new(id)
        addCell:UpdateData(v, false)
        table.insert(toAddArray, addCell)
    end
    for _, infos in pairs(ownVillageWars) do
        for id, v in pairs(infos.WarInfo) do
            local addCell = AllianceWarBuildingCellDataVillageWar.new(id)
            addCell:UpdateData(v, true)
            table.insert(toAddArray, addCell)
        end
    end
    for id, v in pairs(behemothWars) do
        local addCell = AllianceWarBuildingCellDataVillageWar.new(id)
        addCell:UpdateData(v, false)
        table.insert(toAddArray, addCell)
    end
    for _, infos in pairs(ownBehemothWars) do
        for id, v in pairs(infos.WarInfo) do
            local addCell = AllianceWarBuildingCellDataVillageWar.new(id)
            addCell:UpdateData(v, true)
            table.insert(toAddArray, addCell)
        end
    end
    table.sort(toAddArray, AllianceWarTabBuilding.SortForAllianceWarBuildingCellDataVillageWar)
    table.addrange(self._tableData, toAddArray)
end

---@param entity wds.Alliance
function AllianceWarTabBuilding:OnWarDataChanged(entity, changedData)
    if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    local add, remove, change = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.VillageAllianceWarInfo)
    if remove then
        for i = #self._tableData, 1, -1 do
            local cell = self._tableData[i]
            if cell:GetType() == 1 and remove[cell:GetId()] then
                table.remove(self._tableData, i)
                self._p_table:RemData(cell)
            end
        end
    end
    if change then
        for i = #self._tableData, 1, -1 do
            local cell = self._tableData[i]
            if cell:GetType() == 1 and change[cell:GetId()] then
                cell:UpdateData(change[cell:GetId()][2], false)
                self._p_table:UpdateData(cell)
            end
        end
    end
    if add then
        ---@type AllianceWarBuildingCellDataVillageWar[]
        local toAddArray = {}
        for i, v in pairs(add) do
            local addCell = AllianceWarBuildingCellDataVillageWar.new(i)
            addCell:UpdateData(v, false)
            table.insert(toAddArray, addCell)
        end
        table.sort(toAddArray, AllianceWarTabBuilding.SortForAllianceWarBuildingCellDataVillageWar)
        local checkCellIdx = #self._tableData
        for i = #toAddArray, 1, -1 do
            local willAdd = toAddArray[i]
            local endTime = willAdd:GetEndTime()
            while checkCellIdx > 0 do
                local compare = self._tableData[checkCellIdx]
                if not endTime or endTime >= compare:GetEndTime() then
                    break
                end
                checkCellIdx = checkCellIdx - 1
            end
            table.insert(self._tableData, checkCellIdx + 1, willAdd)
            self._p_table:InsertData(checkCellIdx, willAdd)
        end
    end
end

---@param entity wds.Alliance
function AllianceWarTabBuilding:OnOwnWarDataChange(entity, changedData)
    if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() or not changedData then
        return
    end
    ---@type table<number, wds.VillageAllianceWarInfo>[]
    local totalAdd = {}
    for _, v in pairs(changedData) do
        if v.WarInfo then
            local add, remove, change = OnChangeHelper.GenerateMapFieldChangeMap(v.WarInfo, wds.VillageAllianceWarInfo)
            if remove then
                for i = #self._tableData, 1, -1 do
                    local cell = self._tableData[i]
                    if cell:GetType() == 1 and remove[cell:GetId()] then
                        table.remove(self._tableData, i)
                        self._p_table:RemData(cell)
                    end
                end
            end
            if change then
                for i = #self._tableData, 1, -1 do
                    local cell = self._tableData[i]
                    if cell:GetType() == 1 and change[cell:GetId()] then
                        cell:UpdateData(change[cell:GetId()][2], true)
                        self._p_table:UpdateData(cell)
                    end
                end
            end
            if add then
                table.insert(totalAdd, add)
            end
        end
    end
    if #totalAdd > 0 then
        ---@type AllianceWarBuildingCellDataVillageWar[]
        local toAddArray = {}
        for _, add in ipairs(totalAdd) do
            for i, v in pairs(add) do
                local addCell = AllianceWarBuildingCellDataVillageWar.new(i)
                addCell:UpdateData(v, true)
                table.insert(toAddArray, addCell)
            end
        end
        table.sort(toAddArray, AllianceWarTabBuilding.SortForAllianceWarBuildingCellDataVillageWar)
        local checkCellIdx = #self._tableData
        for i = #toAddArray, 1, -1 do
            local willAdd = toAddArray[i]
            local endTime = willAdd:GetEndTime()
            while checkCellIdx > 0 do
                local compare = self._tableData[checkCellIdx]
                if not endTime or endTime >= compare:GetEndTime() then
                    break
                end
                checkCellIdx = checkCellIdx - 1
            end
            table.insert(self._tableData, checkCellIdx + 1, willAdd)
            self._p_table:InsertData(checkCellIdx, willAdd)
        end
    end
end

---@param a AllianceWarBuildingCellDataVillageWar
---@param b AllianceWarBuildingCellDataVillageWar
---@return boolean
function AllianceWarTabBuilding.SortForAllianceWarBuildingCellDataVillageWar(a, b)
    local timeA = a:GetEndTime()
    local timeB = b:GetEndTime()
    if not timeA then
        return false
    end
    if not timeB then
        return true
    end
    return timeA < timeB
end

return AllianceWarTabBuilding
