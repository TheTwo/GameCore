local AllianceActivityDataProviderDefine = require("AllianceActivityDataProviderDefine")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local AllianceExpeditionCreateType = require('AllianceExpeditionCreateType')
local AllianceActivityCellDataWorldEventBig = require('AllianceActivityCellDataWorldEventBig')

---@class AllianceActivityDataProvider
---@field new fun():AllianceActivityDataProvider
local AllianceActivityDataProvider = class('AllianceActivityDataProvider')

---@alias setAllianceActivityCellCallback fun(cellData:AllianceWarActivityCell)

---@type {DataType:AllianceActivityDataProviderDefine.SourceType, InitCellsUsage:fun():table<number, AllianceWarActivityCell>, RelaseCellsUsage:fun(), SetCellDataChange:fun(onAdd:setAllianceActivityCellCallback,onRemove:setAllianceActivityCellCallback,onUpdate:setAllianceActivityCellCallback)}[]
AllianceActivityDataProvider.DataProviderClass = {
    {
        DataType = AllianceActivityDataProviderDefine.SourceType.AllianceGve,
        InitCellsUsage = function()
            return ModuleRefer.AllianceModule.Behemoth:GenerateActivityCells()
        end,
        RelaseCellsUsage = function()
            ModuleRefer.AllianceModule.Behemoth:ReleaseActivityCells()
        end,
        SetCellDataChange = function(onAdd, onRemove, onUpdate)
            ModuleRefer.AllianceModule.Behemoth:SetActivityCellsDataChange(onAdd, onRemove, onUpdate)
        end,
    }, 
    -- {
    --     DataType = AllianceActivityDataProviderDefine.SourceType.AllianceExpeditionBig,
    --     InitCellsUsage = function()
    --         local res = ModuleRefer.WorldEventModule:GetAllianceExpeditions()
    --         local cells = {}
    --         local index = 1
    --         for k, v in pairs(res) do
    --             if v.CreateType ~= AllianceExpeditionCreateType.ItemActivator then
    --                 local cellData = AllianceActivityCellDataWorldEventBig.new(index, v)
    --                 cells[index] = cellData
    --                 index = index + 1
    --             end
    --         end
    --         return cells
    --     end,
    --     RelaseCellsUsage = function()
    --         -- ModuleRefer.AllianceModule.Behemoth:ReleaseActivityCells()
    --     end,
    --     SetCellDataChange = function(onAdd, onRemove, onUpdate)
    --         -- ModuleRefer.AllianceModule.Behemoth:SetActivityCellsDataChange(onAdd, onRemove, onUpdate)
    --     end,
    -- },
}

function AllianceActivityDataProvider:ctor()
    ---@type AllianceWarActivityCell[]
    self._currentDataSource = {}
    ---@type table<string, AllianceWarActivityCell>
    self._currentDataSourceMap = {}
    ---@type setAllianceActivityCellCallback
    self._inUsingOnAdd = nil
    ---@type setAllianceActivityCellCallback
    self._inUsingOnRemove = nil
    ---@type setAllianceActivityCellCallback
    self._inUsingOnUpdate = nil
end

---@param onAdd setAllianceActivityCellCallback
---@param onRemove setAllianceActivityCellCallback
---@param onUpdate setAllianceActivityCellCallback
---@return AllianceWarActivityCell[]
function AllianceActivityDataProvider:InitTableViewDataSource(onAdd, onRemove, onUpdate)
    self._inUsingOnAdd = onAdd
    self._inUsingOnRemove = onRemove
    self._inUsingOnUpdate = onUpdate

    local add = Delegate.GetOrCreate(self, self.OnDataAdd)
    local remove = Delegate.GetOrCreate(self, self.OnDataRemove)
    local update = Delegate.GetOrCreate(self, self.OnDataUpdate)

    table.clear(self._currentDataSource)
    for _, value in pairs(AllianceActivityDataProvider.DataProviderClass) do
        local addCells = value.InitCellsUsage()
        if addCells then
            for _, cellValue in pairs(addCells) do
                table.insert(self._currentDataSource, cellValue)
            end
        end
        value.SetCellDataChange(add, remove, update)
    end
    return self._currentDataSource
end

function AllianceActivityDataProvider:ReleaseTableViewDataSource()
    for _, value in ipairs(AllianceActivityDataProvider.DataProviderClass) do
        value.SetCellDataChange(nil, nil, nil)
        value.RelaseCellsUsage()
    end
    table.clear(self._currentDataSource)
    self._inUsingOnAdd = nil
    self._inUsingOnRemove = nil
    self._inUsingOnUpdate = nil
end

---@param cellData AllianceWarActivityCell
function AllianceActivityDataProvider:OnDataAdd(cellData)
    if self._inUsingOnAdd then
        self._inUsingOnAdd(cellData)
    end
end

---@param cellData AllianceWarActivityCell
function AllianceActivityDataProvider:OnDataRemove(cellData)
    if self._inUsingOnRemove then
        self._inUsingOnAdd(cellData)
    end
end

---@param cellData AllianceWarActivityCell
function AllianceActivityDataProvider:OnDataUpdate(cellData)
    if self._inUsingOnUpdate then
        self._inUsingOnAdd(cellData)
    end
end

return AllianceActivityDataProvider
