local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local MapBuildingSubType = require("MapBuildingSubType")
local VillageSubType = require("VillageSubType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummarySettlementCellData
---@field lvs number[]
---@field hasCount number[]
---@field unlockIndex number|nil
---@field __prefabIndex number

---@class AllianceTerritoryMainSummarySettlementCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummarySettlementCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummarySettlementCell = class('AllianceTerritoryMainSummarySettlementCell', BaseTableViewProCell)

function AllianceTerritoryMainSummarySettlementCell:ctor()
    AllianceTerritoryMainSummarySettlementCell.super.ctor(self)
    ---@type CS.UnityEngine.UI.Text[]
    self._p_text_lv = {}
    ---@type CS.UnityEngine.UI.Text[]
    self._p_text_quantity = {}
end

function AllianceTerritoryMainSummarySettlementCell:OnCreate(param)
    self._p_icon_settlement = self:Image("p_icon_settlement")
    self._p_lock = self:GameObject("p_lock")
    self._p_text_lock = self:Text("p_text_lock")
    for i = 1, 4 do
        self._p_text_lv[i] = self:Text(("p_text_lv_%d"):format(i))
        self._p_text_quantity[i] = self:Text(("p_text_quantity_%d"):format(i))
    end
end

---@param data AllianceTerritoryMainSummarySettlementCellData
function AllianceTerritoryMainSummarySettlementCell:OnFeedData(data)
    -- local hasAny = false
    for i = 1, 4 do
        self._p_text_lv[i].text = tostring(data.lvs[i])
        local limit = ModuleRefer.VillageModule:GetVillageOwnCountLimitByLevel(data.lvs[i], false)
        if limit then
            self._p_text_quantity[i].text = ("%d/%d"):format(data.hasCount[i], limit)
        else
            self._p_text_quantity[i].text = data.hasCount[i]
        end
        -- if data.hasCount[i] > 0 then
        --     hasAny = true
        -- end
    end
    -- local prefix = ModuleRefer.VillageModule:GetVillageIconPrefixByTypeSubTypeLevel(MapBuildingSubType.Stronghold, VillageSubType.Undefine, data.lvs[1])
    -- local icon = ModuleRefer.VillageModule:GetVillageIconRaw(prefix, hasAny, true, false)
    -- g_Game.SpriteManager:LoadSprite(icon, self._p_icon_settlement)
    -- self._p_icon_settlement:SetVisible(true)
    self._p_lock:SetVisible(data.unlockIndex ~= nil)
    if data.unlockIndex then
        self._p_text_lock.text = I18N.GetWithParams("alliance_territory_overview_city_unlockcodition", data.unlockIndex)
    end
end

return AllianceTerritoryMainSummarySettlementCell
