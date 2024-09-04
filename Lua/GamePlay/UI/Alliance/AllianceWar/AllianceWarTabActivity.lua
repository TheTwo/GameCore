local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

---@class AllianceWarTabActivity
---@field new fun(host:AllianceWarMediator, nodeName:string):AllianceWarTabActivity
local AllianceWarTabActivity = class('AllianceWarTabActivity')

---@param host AllianceWarNewMediator
function AllianceWarTabActivity:ctor(host, nodeName)
    self._host = host
    self._p_root = host:GameObject(nodeName)
    self._p_table = host:TableViewPro("p_table_event")
    ---@type AllianceActivityCellDataWrapper[]
    self._cells = {}
end

function AllianceWarTabActivity:OnEnter()
    self._p_root:SetVisible(true)
    table.clear(self._cells)
    self._p_table:Clear()
    local initCells = ModuleRefer.AllianceModule.ActivityDataProvider:InitTableViewDataSource(
        Delegate.GetOrCreate(self, self.OnCellDataAdd),
        Delegate.GetOrCreate(self, self.OnCellDataRemove),
        Delegate.GetOrCreate(self, self.OnCellDataUpdate)
    )
    for _, value in ipairs(initCells) do
        table.insert(self._cells, AllianceWarTabActivity.MakeWrapperData(value))
    end
    table.sort(self._cells, AllianceWarTabActivity.CompareWrapperCellData)
    for _, value in ipairs(self._cells) do
        local prefabIndex = value.cellData:GetPrefabIndex()
        self._p_table:AppendData(value, prefabIndex)
    end
    self._host:SetTabHasData(#self._cells > 0)
end

function AllianceWarTabActivity:OnExit()
    ModuleRefer.AllianceModule.ActivityDataProvider:ReleaseTableViewDataSource()
    table.clear(self._cells)
    self._p_table:Clear()
    self._p_root:SetVisible(false)
end

---@param cellData AllianceWarActivityCell
---@return AllianceActivityCellDataWrapper
function AllianceWarTabActivity.MakeWrapperData(cellData)
    ---@type AllianceActivityCellDataWrapper
    local wrapperCell = {}
    wrapperCell.cellData = cellData
    return wrapperCell
end

---@param a AllianceActivityCellDataWrapper
---@param b AllianceActivityCellDataWrapper
function AllianceWarTabActivity.CompareWrapperCellData(a, b)
    return AllianceWarTabActivity.CompareCellData(a.cellData, b.cellData)
end

---@param a AllianceActivityCellData
---@param b AllianceActivityCellData
function AllianceWarTabActivity.CompareCellData(a, b)
    local updateTimeA = a:LastUpdateTime()
    local updateTimeB = b:LastUpdateTime()
    if updateTimeB < updateTimeA then
        return true
    elseif updateTimeB > updateTimeA then
        return false
    else
        local typeA = a.GetSoureType()
        local typeB = a.GetSoureType()
        if typeA < typeB then
            return true
        elseif typeA > typeB then
            return false
        end
    end
    return b._cellId > a._cellId
end

function AllianceWarTabActivity:OnCellDataAdd(cellData)
    local addData = AllianceWarTabActivity.MakeWrapperData(cellData)
    if #self._cells > 0 then
        for index, value in ipairs(self._cells) do
            if AllianceWarTabActivity.CompareWrapperCellData(addData, value) then
                table.insert(self._cells, addData, index)
                self._p_table:InsertData(index - 1,addData, addData.cellData:GetPrefabIndex())
                return
            end
        end
    end
    table.insert(self._cells, addData)
    self._p_table:AppendData(addData, addData.cellData:GetPrefabIndex())
end

---@param cellData AllianceActivityCellData
function AllianceWarTabActivity:OnCellDataRemove(cellData)
    local toRemoveKey = cellData:GetCellDataKey()
    for index = #self._cells, 1, -1 do
        local cell = self._cells[index]
        if cell.cellData:GetCellDataKey() == toRemoveKey then
            table.remove(self._cells, index)
            self._p_table:RemData(cell)
            return
        end
    end
end

---@param cellData AllianceActivityCellData
function AllianceWarTabActivity:OnCellDataUpdate(cellData)
    local updateKey = cellData:GetCellDataKey()
    local removeAndAdd = false
    for index = #self._cells, 1, -1 do
        local cell = self._cells[index]
        if cell.cellData:GetCellDataKey() == updateKey then
            if cell.cellData:LastUpdateTime() == cellData:LastUpdateTime() then
                cell.cellData = cellData
                self._p_table:UpdateChild(cell)
                return
            else
                table.remove(self._cells, index)
                self._p_table:RemData(cell)
                removeAndAdd = true
                break
            end
        end
    end
    if not removeAndAdd then return end
    self:OnCellDataAdd(cellData)
end

return AllianceWarTabActivity