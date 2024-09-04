local UIHelper = require("UIHelper")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTechResearchLinkerColumnParameter
---@field linkMap table<number, table<number, boolean>>
---@field leftPos2Group table<number, number>
---@field rightPos2Group table<number, number>

---@class AllianceTechResearchLinkerColumn:BaseTableViewProCell
---@field new fun():AllianceTechResearchLinkerColumn
---@field super BaseTableViewProCell
local AllianceTechResearchLinkerColumn = class('AllianceTechResearchLinkerColumn', BaseTableViewProCell)

function AllianceTechResearchLinkerColumn:ctor()
    BaseTableViewProCell.ctor(self)
    ---@type CS.UnityEngine.Transform[]
    self._p_note_pos = {}
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._cells = {}
    self._eventsAdd = false
    ---@type table<number, boolean>
    self._linkGroups = {}
end

function AllianceTechResearchLinkerColumn:OnCreate(param)
    for i = 1, 4 do
        self._p_note_pos[i * 2 - 1] = self:Transform(("p_notes_%d"):format(i))
    end
    for i = 5, 7 do
        self._p_note_pos[(i - 4) * 2] = self:Transform(("p_notes_%d"):format(i))
    end
    ---@see AllianceTechResearchLinkerNode
    self._p_link_line_template = self:LuaBaseComponent("p_link_line_template")
    self._p_link_line_template:SetVisible(false)
end

---@param linkMap table<number, table<number, boolean>>
---@return table<number, number>
function AllianceTechResearchLinkerColumn.BuildLinkFlag(linkMap)
    ---@type table<number, number>
    local ret = {}
    for leftPos, rightPosSet in pairs(linkMap) do
        for rightPos, _ in pairs(rightPosSet) do
            ret[leftPos] = (ret[leftPos] or 0) | 4
            ret[rightPos] = (ret[rightPos] or 0) | 8
            if leftPos < rightPos then
                ret[leftPos] = ret[leftPos] | 2
                ret[rightPos] = ret[rightPos] | 1
                for f = leftPos + 1, rightPos - 1 do
                    ret[f] = (ret[f] or 0) | 3
                end
            elseif rightPos < leftPos then
                ret[leftPos] = ret[leftPos] | 1
                ret[rightPos] = ret[rightPos] | 2
                for f = rightPos + 1, leftPos - 1 do
                    ret[f] = (ret[f] or 0) | 3
                end
            end
        end
    end
    return ret
end

---@param data AllianceTechResearchLinkerColumnParameter
function AllianceTechResearchLinkerColumn:OnFeedData(data)
    self._data = data
    table.clear(self._linkGroups)
    for _, v in pairs(data.leftPos2Group) do
        self._linkGroups[v] = true
    end
    for _, v in pairs(data.rightPos2Group) do
        self._linkGroups[v] = true
    end
    self:RefreshLink()
    self:SetupEvents(true)
end

function AllianceTechResearchLinkerColumn:OnRecycle(param)
    for _, value in ipairs(self._cells) do
        UIHelper.DeleteUIComponent(value)
    end
    table.clear(self._cells)
    self._data = nil
    self:SetupEvents(false)
end

function AllianceTechResearchLinkerColumn:OnClose(param)
    self._data = nil
    self:SetupEvents(false)
end

function AllianceTechResearchLinkerColumn:RefreshLink()
    ---@type table<number, number>
    local needCellsPos = AllianceTechResearchLinkerColumn.BuildLinkFlag(self._data.linkMap)
    local unlockCellsPos = self:RefreshUnlockStatus()

    ---@type AllianceTechResearchLinkerNodeParameter[]
    local cellsData = {}
    for i, v in pairs(needCellsPos) do
        ---@type AllianceTechResearchLinkerNodeParameter
        local cellData = {}
        cellData.cellPosIdx = i
        cellData.linkFlag = v
        cellData.unlockFlag = unlockCellsPos[i] or 0
        table.insert(cellsData, cellData)
    end

    local dataCount = table.nums(cellsData)
    local hasCount= #self._cells
    local reuseCount = math.min(dataCount, hasCount)
    for i = 1, reuseCount do
        local cell = self._cells[i]
        local cellPosIdx = cellsData[i].cellPosIdx
        cell.transform:SetParent(self._p_note_pos[cellPosIdx], false)
        cell.transform.localPosition = CS.UnityEngine.Vector3.zero
        cell:SetVisible(true)
        cell:FeedData(cellsData[i])
    end
    for i = hasCount, dataCount + 1, -1 do
        self._cells[i]:SetVisible(false)
    end
    if dataCount > reuseCount then
        self._p_link_line_template:SetVisible(true)
        for i = reuseCount + 1, dataCount do
            local cellPosIdx = cellsData[i].cellPosIdx
            ---@type CS.DragonReborn.UI.LuaBaseComponent
            local cell = UIHelper.DuplicateUIComponent(self._p_link_line_template, self._p_note_pos[cellPosIdx])
            cell.transform.localPosition = CS.UnityEngine.Vector3.zero
            table.insert(self._cells, cell)
            cell:FeedData(cellsData[i])
        end
        self._p_link_line_template:SetVisible(false)
    end
end

function AllianceTechResearchLinkerColumn:RefreshUnlockStatus()
    ---@type table<number, table<number, boolean>>
    local unlockMap = {}
    local TechModule = ModuleRefer.AllianceTechModule
    for leftPos, rightPosSet in pairs(self._data.linkMap) do
        local leftGroup = self._data.leftPos2Group[leftPos]
        for rightPos, _ in pairs(rightPosSet) do
            local rightGroup = self._data.rightPos2Group[rightPos]
            if TechModule:IsLeftUnlockLinkToRight(leftGroup, rightGroup) then
                local posSet = unlockMap[leftPos]
                if not posSet then
                    posSet = {}
                    unlockMap[leftPos] = posSet
                end
                posSet[rightPos] = true
            end
        end
    end
    return AllianceTechResearchLinkerColumn.BuildLinkFlag(unlockMap)
end

function AllianceTechResearchLinkerColumn:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_TECH_NODE_UPDATED, Delegate.GetOrCreate(self, self.OnNodeUpdate))
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TECH_NODE_UPDATED, Delegate.GetOrCreate(self, self.OnNodeUpdate))
    end
end

function AllianceTechResearchLinkerColumn:OnNodeUpdate(groupIdMap)
    if not self._data then
        return
    end
    for i, _ in pairs(groupIdMap) do
        if self._linkGroups[i] then
            self:RefreshLink()
            return
        end
    end
end

return AllianceTechResearchLinkerColumn