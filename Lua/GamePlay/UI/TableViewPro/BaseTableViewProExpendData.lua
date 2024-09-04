local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class BaseTableViewProExpendData
---@field new fun():BaseTableViewProExpendData
local BaseTableViewProExpendData = class('BaseTableViewProExpendData')

function BaseTableViewProExpendData:ctor()
    self.__isExpanded = false
    self.__childCellsData = {}
end

---@return number
function BaseTableViewProExpendData:GetChildCount()
    return #self.__childCellsData
end

---@param index number
---@return any
function BaseTableViewProExpendData:GetChildAt(index)
    return self.__childCellsData[index]
end

---@param index number
---@return number
function BaseTableViewProExpendData:GetPrefabIndex(index)
    return 1
end

---@return boolean
function BaseTableViewProExpendData:IsExpanded()
    return self.__isExpanded
end

---@param isExpanded boolean
function BaseTableViewProExpendData:SetExpanded(isExpanded)
    self.__isExpanded = isExpanded
end

---@param tableView CS.TableViewPro
function BaseTableViewProExpendData:OnRemFromTable(tableView)
    for i = self:GetChildCount(), 1, -1 do
        local childData = self:GetChildAt(i)
        if childData.OnRemFromTable then
            childData.OnRemFromTable(tableView)
        end
        tableView:RemData(childData)
    end
end

---@param tableView CS.TableViewPro
---@param newChildCellsData any[]
function BaseTableViewProExpendData:RefreshChildCells(tableView, newChildCellsData)
    if tableView and self:IsExpanded() then
        local selfIndex = tableView:GetDataIndex(self)
        if selfIndex >= 0 then
            local oldCount = self:GetChildCount()
            local newCount = #newChildCellsData
            for i = oldCount, (newCount+1), -1 do
                local oldData = self:GetChildAt(i)
                if oldData.OnRemFromTable then
                    oldData:OnRemFromTable(tableView)
                end
                tableView:RemData(oldData)
                table.remove(self.__childCellsData, i)
            end
            local updateCount = math.min(oldCount, newCount)
            for i = 1, updateCount do
                self.__childCellsData[i] = newChildCellsData[i]
                tableView:ReplaceData(selfIndex + i, newChildCellsData[i])
            end
            for i = (updateCount+1), newCount do
                table.insert(self.__childCellsData, i, newChildCellsData[i])
                tableView:InsertData(selfIndex + i, newChildCellsData[i], self:GetPrefabIndex(i))
            end
        else
            table.clear(self.__childCellsData)
            table.addrange(self.__childCellsData, newChildCellsData)
        end
    else
        table.clear(self.__childCellsData)
        table.addrange(self.__childCellsData, newChildCellsData)
    end
end

---@param tableView CS.TableViewPro
---@param func fun(childCellData:any):boolean,boolean
---@return number
function BaseTableViewProExpendData:ReverseForeachChildCells(tableView, func)
    local operateTableView = tableView and self:IsExpanded() and tableView:GetDataIndex(self) >= 0 or false
    local oldCount = self:GetChildCount()
    for i = oldCount, 1, -1 do
        local oldData = self:GetChildAt(i)
        local remove,co = func(oldData)
        if remove then
            if operateTableView then
                if oldData.OnRemFromTable then
                    oldData:OnRemFromTable(tableView)
                end
                tableView:RemData(oldData)
            end
            table.remove(self.__childCellsData, i)
        end
        if not co then
            break
        end
    end
    return self:GetChildCount()
end

return BaseTableViewProExpendData