local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryCityCellData
---@field lvs number[]
---@field has boolean[]
---@field unlockIndex number|nil
---@field __prefabIndex number
---@field mapBuildingSubType number[] @MapBuildingSubType
---@field villageSubType number[] @VillageSubType

---@class AllianceTerritoryMainSummaryCityCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryCityCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryCityCell = class('AllianceTerritoryMainSummaryCityCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryCityCell:ctor()
    AllianceTerritoryMainSummaryCityCell.super.ctor(self)
    ---@type CS.StatusRecordParent[]
    self._p_city = {}
    ---@type CS.UnityEngine.UI.Image[]
    self._p_icon_settlement = {}
    ---@type CS.UnityEngine.UI.Text[]
    self._p_text_lv = {}
end

function AllianceTerritoryMainSummaryCityCell:OnCreate(param)
    for i = 1, 4 do
        self._p_city[i] = self:StatusRecordParent(("p_city_%d"):format(i))
        self._p_icon_settlement[i] = self:Image(("p_icon_settlement_%d"):format(i))
        self._p_text_lv[i] = self:Text(("p_text_lv_%d"):format(i))
    end
    self._p_lock = self:GameObject("p_lock")
    self._p_text_lock = self:Text("p_text_lock")
end

---@param data AllianceTerritoryMainSummaryCityCellData
function AllianceTerritoryMainSummaryCityCell:OnFeedData(data)
    for i = 1, 4 do
        local lv = data.lvs[i]
        if lv and lv > 0 then
            local prefix = ModuleRefer.VillageModule:GetVillageIconPrefixByTypeSubTypeLevel(data.mapBuildingSubType[i], data.villageSubType[i], lv)
            local icon = ModuleRefer.VillageModule:GetVillageIconRaw(prefix, data.has[i], true, false, false)
            self._p_city[i]:SetState(data.has[i] and 0 or 1)
            self._p_text_lv[i].text = tostring(lv)
            g_Game.SpriteManager:LoadSprite(icon, self._p_icon_settlement[i])
        else
            self._p_city[i]:SetState(2)
        end
    end
    self._p_lock:SetVisible(data.unlockIndex ~= nil)
    if data.unlockIndex then
        self._p_text_lock.text = I18N.GetWithParams("alliance_territory_overview_city_unlockcodition", data.unlockIndex)
    end
end

return AllianceTerritoryMainSummaryCityCell
