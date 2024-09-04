local UIHelper = require("UIHelper")
local AllianceTechResearchTechColumnHelper = require("AllianceTechResearchTechColumnHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTechResearchTechColumnParameter
---@field nodes AllianceTechGroupChain[]
---@field nodePos number[]

---@class AllianceTechResearchTechColumn:BaseTableViewProCell
---@field new fun():AllianceTechResearchTechColumn
---@field super BaseTableViewProCell
local AllianceTechResearchTechColumn = class('AllianceTechResearchTechColumn', BaseTableViewProCell)

function AllianceTechResearchTechColumn:ctor()
    BaseTableViewProCell.ctor(self)
    ---@type CS.UnityEngine.Transform[]
    self._p_note_pos = {}
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._cells = {}
end

function AllianceTechResearchTechColumn:OnCreate(param)
    for i = 1, 4 do
        self._p_note_pos[i * 2 - 1] = self:Transform(("p_notes_%d"):format(i))
    end
    for i = 5, 7 do
        self._p_note_pos[(i - 4) * 2] = self:Transform(("p_notes_%d"):format(i))
    end
    ---@see AllianceTechResearchTechNode
    self._p_tech_node_template = self:LuaBaseComponent("p_tech_node_template")
    self._p_tech_node_template:SetVisible(false)
end

---@param data AllianceTechResearchTechColumnParameter
function AllianceTechResearchTechColumn:OnFeedData(data)
    local dataCount = #data.nodes
    local isOdd = (dataCount & 1) == 1
    local hasCount= #self._cells
    local posCount = isOdd and 3 or 4
    local reuseCount = math.min(dataCount, hasCount, posCount)
    for i = 1, reuseCount do
        local cell = self._cells[i]
        local cellPosIdx = data.nodePos[i]
        cell.transform:SetParent(self._p_note_pos[cellPosIdx], false)
        cell.transform.localPosition = CS.UnityEngine.Vector3.zero
        cell:SetVisible(true)
        cell:FeedData(data.nodes[i])
    end
    for i = hasCount, dataCount + 1, -1 do
        self._cells[i]:SetVisible(false)
    end
    local addToCount = math.min(dataCount, posCount)
    if addToCount > reuseCount then
        self._p_tech_node_template:SetVisible(true)
        for i = reuseCount + 1, addToCount do
            local cellPosIdx = data.nodePos[i]
            ---@type CS.DragonReborn.UI.LuaBaseComponent
            local cell = UIHelper.DuplicateUIComponent(self._p_tech_node_template, self._p_note_pos[cellPosIdx])
            cell.transform.localPosition = CS.UnityEngine.Vector3.zero
            table.insert(self._cells, cell)
            cell:FeedData(data.nodes[i])
        end
        self._p_tech_node_template:SetVisible(false)
    end
end

function AllianceTechResearchTechColumn:OnRecycle()
    for _, value in ipairs(self._cells) do
        UIHelper.DeleteUIComponent(value)
    end
    table.clear(self._cells)
end

function AllianceTechResearchTechColumn:GetNode(groupId)
    for _, v in pairs(self._cells) do
        ---@type AllianceTechResearchTechNode
        local cell = v.Lua
        if cell and cell._groupId == groupId then
            return cell
        end
    end
end

return AllianceTechResearchTechColumn