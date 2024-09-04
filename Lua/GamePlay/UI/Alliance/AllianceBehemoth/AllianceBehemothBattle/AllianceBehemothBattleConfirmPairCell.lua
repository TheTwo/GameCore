---Deprecated
local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothBattleConfirmPairCell:BaseTableViewProCell
---@field new fun():AllianceBehemothBattleConfirmPairCell
---@field super BaseTableViewProCell
local AllianceBehemothBattleConfirmPairCell = class('AllianceBehemothBattleConfirmPairCell', BaseTableViewProCell)

function AllianceBehemothBattleConfirmPairCell:ctor()
    AllianceBehemothBattleConfirmPairCell.super.ctor(self)
    ---@type AllianceBehemothBattleConfirmCell[]
    self._cells = {}
end

function AllianceBehemothBattleConfirmPairCell:OnCreate(param)
    ---@see AllianceBehemothBattleConfirmCell
    self._p_confirm = self:LuaBaseComponent("p_confirm")
    self._p_confirm:SetVisible(false)
end

---@param data AllianceBehemothBattleConfirmCellData[]
function AllianceBehemothBattleConfirmPairCell:OnFeedData(data)
    local dataCount = #data
    for i = #self._cells, dataCount + 1, -1 do
        self._cells[i]:SetVisible(false)
    end
    self._p_confirm:SetVisible(true)
    for i = #self._cells + 1, dataCount do
        local cell = UIHelper.DuplicateUIComponent(self._p_confirm, self._p_confirm.transform.parent)
        table.insert(self._cells, cell)
    end
    self._p_confirm:SetVisible(false)
    for i = 1, dataCount do
        self._cells[i]:SetVisible(true)
        self._cells[i]:FeedData(data[i])
    end
end

return AllianceBehemothBattleConfirmPairCell