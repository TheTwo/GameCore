local Utils = require("Utils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryLvCellData
---@field lvTitle string
---@field amountTitle string
---@field lvNames string[]
---@field lvCounts string[]

---@class AllianceTerritoryMainSummaryLvCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryLvCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryLvCell = class('AllianceTerritoryMainSummaryLvCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryLvCell:ctor()
    BaseTableViewProCell.ctor(self)
    ---@type CS.UnityEngine.UI.Text[]
    self._lvs = {}
    ---@type CS.UnityEngine.UI.Text[]
    self._lvCounts = {}
    ---@type CS.UnityEngine.GameObject[]
    self._lvNameGroup = {}
end

function AllianceTerritoryMainSummaryLvCell:OnCreate(param)
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_amount = self:Text("p_text_amount")
    for i = 1, 6 do
        self._lvs[i] = self:Text(("p_text_lv_%d"):format(i))
        self._lvCounts[i] = self:Text(("p_text_quantity_%d"):format(i))
        self._lvNameGroup[i] = self:GameObject(("p_lv_%d"):format(i))
    end
end

---@param data AllianceTerritoryMainSummaryLvCellData
function AllianceTerritoryMainSummaryLvCell:OnFeedData(data)
    self._p_text_lv.text = data.lvTitle
    self._p_text_amount.text = data.amountTitle
    for i = 1, 6 do
        local lvName = data.lvNames[i]
        local lvCount = data.lvCounts[i]
        if lvName then
            self._lvNameGroup[i]:SetVisible(true)
            self._lvs[i]:SetVisible(true)
            self._lvCounts[i]:SetVisible(true)
            self._lvs[i].text = lvName
            self._lvCounts[i].text = lvCount or "0"
        else
            self._lvNameGroup[i]:SetVisible(false)
            self._lvs[i]:SetVisible(false)
            self._lvCounts[i]:SetVisible(false)
        end
    end
end

return AllianceTerritoryMainSummaryLvCell
