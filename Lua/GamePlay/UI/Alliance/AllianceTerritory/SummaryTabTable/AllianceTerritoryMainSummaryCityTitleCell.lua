local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryCityTitleCellData
---@field subType number[]
---@field hasCount number[]
---@field __prefabIndex number

---@class AllianceTerritoryMainSummaryCityTitleCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryCityTitleCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryCityTitleCell = class('AllianceTerritoryMainSummaryCityTitleCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryCityTitleCell:ctor()
    AllianceTerritoryMainSummaryCityTitleCell.super.ctor(self)
    ---@type CS.UnityEngine.UI.Text[]
    self._p_text_title = {}
    ---@type CS.UnityEngine.UI.Text[]
    self._p_text_number = {}
end

function AllianceTerritoryMainSummaryCityTitleCell:OnCreate(param)
    for i = 1, 4 do
        self._p_text_title[i] = self:Text(("p_text_title_%d"):format(i)) 
        self._p_text_number[i] = self:Text(("p_text_number_%d"):format(i)) 
    end
end

---@param data AllianceTerritoryMainSummaryCityTitleCellData
function AllianceTerritoryMainSummaryCityTitleCell:OnFeedData(data)
    for i = 1, 4 do
        self._p_text_title[i].text = ModuleRefer.VillageModule.GetVillageSubTypeName(data.subType[i])
        local limit = ModuleRefer.VillageModule:GetVillageOwnCountLimitBySubType(data.subType[i])
        if limit then
            self._p_text_number[i].text = I18N.GetWithParams("village_info_numandtotal", tostring(data.hasCount[i]), tostring(limit))
        else
            self._p_text_number[i].text = tostring(data.hasCount[i])
        end
    end
end

return AllianceTerritoryMainSummaryCityTitleCell
