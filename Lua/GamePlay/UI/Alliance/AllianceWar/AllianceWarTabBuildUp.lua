local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceWarCellData = require("AllianceWarCellData")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")

---@class AllianceWarTabBuildUp
---@field new fun(host:AllianceWarMediator, nodeName:string):AllianceWarTabBuildUp
local AllianceWarTabBuildUp = class('AllianceWarTabBuildUp')

---@param host AllianceWarMediator
function AllianceWarTabBuildUp:ctor(host, nodeName)
    self._host = host
    self._p_root = host:GameObject(nodeName)
    self._p_table = host:TableViewPro("p_table_war")
    ---@type AllianceWarCellData[]
    self._tableData = {}
end

function AllianceWarTabBuildUp:OnEnter()
    self._p_root:SetVisible(true)
    self._p_table:Clear()
    self:GenerateCellsData()
    for _, cellData in ipairs(self._tableData) do
        self._p_table:AppendData(cellData)
    end
    self._host:SetTabHasData(#self._tableData > 0)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTeamInfosChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTeamInfosChanged))
end

function AllianceWarTabBuildUp:OnExit()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTeamInfosChanged))
    self._p_table:Clear()
    self._p_root:SetVisible(false)
end

function AllianceWarTabBuildUp:GenerateCellsData()
    table.clear(self._tableData)
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData or not myAllianceData.AllianceTeamInfos or not myAllianceData.AllianceTeamInfos.Infos then
        return
    end
    local infos = myAllianceData.AllianceTeamInfos.Infos
    for i, v in pairs(infos) do
        self:DoAddCell(i, v)
    end
end

---@param id number
---@param serverData wds.AllianceTeamInfo
function AllianceWarTabBuildUp:DoAddCell(id, serverData)
    ---@type AllianceWarPlayerCellData[]
    local children = {}
    for _, member in pairs(serverData.Members) do
        ---@type AllianceWarPlayerCellData
        local playerCell = {}
        playerCell.memberInfo = member
        table.insert(children, playerCell)
    end
    local warCellData = AllianceWarCellData.new(children)
    warCellData:Setup(id, serverData)
    table.insert(self._tableData, warCellData)
    return warCellData
end

---@param entity wds.Alliance
function AllianceWarTabBuildUp:OnAllianceTeamInfosChanged(entity, changedData)
    if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    local add,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.AllianceTeamInfo)
    if remove then
        for i = #self._tableData, 1, -1 do
            local cellData = self._tableData[i]
            local id,type = cellData:GetIdAndType()
            if type == 1 and remove[id] then
                table.remove(self._tableData, i)
                cellData:OnRemFromTable(self._p_table)
                self._p_table:RemData(cellData)
            end
        end
    end
    if change then
        for i = #self._tableData, 1, -1 do
            local cellData = self._tableData[i]
            local id,type = cellData:GetIdAndType()
            if type == 1 and change[id] then
                local isExpended = cellData:IsExpanded()
                if isExpended then
                    cellData:SetExpanded(false)
                    self._p_table:UpdateData(cellData)
                end
                cellData:Setup(id, change[id][2])
                cellData:ReGenerateChildCell(self._p_table)
                cellData:SetExpanded(isExpended)
                self._p_table:UpdateData(cellData)
            end
        end
    end
    if add then
        for i, v in pairs(add) do
            local cell = self:DoAddCell(i, v)
            self._p_table:AppendData(cell)
        end
    end
    self._host:SetTabHasData(#self._tableData > 0)
end

return AllianceWarTabBuildUp