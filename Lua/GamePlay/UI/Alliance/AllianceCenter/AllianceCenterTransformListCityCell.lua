local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local Utils = require("Utils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceCenterTransformListCityCellData
---@field building wds.MapBuildingBrief
---@field buildingConfig FixedMapBuildingConfigCell

---@class AllianceCenterTransformListCityCell:BaseTableViewProCell
---@field new fun():AllianceCenterTransformListCityCell
---@field super BaseTableViewProCell
local AllianceCenterTransformListCityCell = class('AllianceCenterTransformListCityCell', BaseTableViewProCell)

function AllianceCenterTransformListCityCell:OnCreate(param)
    self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_icon_city = self:Image("p_icon_city")
    self._p_text_lv_territory = self:Text("p_text_lv_territory")
    self._p_text_name_new = self:Text("p_text_name_new")
    self._p_status_now = self:GameObject("p_status_now")
    self._child_img_select = self:GameObject("child_img_select")
    self._p_status_attack = self:GameObject("p_status_attack")
    self._p_status_defence = self:GameObject("p_status_defence")
    self._p_text_currrent = self:Text("p_text_currrent", "alliance_center_siteselection_current_tips2")
    if Utils.IsNotNull(self._p_status_now) then
        self._p_status_now:SetVisible(false)
    end
    self._selfStatus = self:StatusRecordParent("")
end

---@param data AllianceCenterTransformListCityCellData
function AllianceCenterTransformListCityCell:OnFeedData(data)
    self._data = data
    local building = data.building
    -- self._p_status_now:SetVisible(building.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone)
    self._p_text_currrent:SetVisible(building.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone)
    local icon = ModuleRefer.VillageModule:GetVillageIcon(ModuleRefer.AllianceModule:GetAllianceId(), ModuleRefer.PlayerModule:GetPlayerId(), building.ConfigId)
    g_Game.SpriteManager:LoadSprite(icon, self._p_icon_city)
    self._p_text_lv_territory.text = ("Lv.%d"):format(data.buildingConfig:Level())
    self._p_text_name_new.text = I18N.Get(data.buildingConfig:Name())
end

function AllianceCenterTransformListCityCell:OnClickSelf()
    self:GetTableViewPro():SetToggleSelect(self._data)
end

function AllianceCenterTransformListCityCell:Select()
    -- self._child_img_select:SetVisible(true)
    self._selfStatus:SetState(1)
end

function AllianceCenterTransformListCityCell:UnSelect()
    -- self._child_img_select:SetVisible(false)
    self._selfStatus:SetState(0)
end

return AllianceCenterTransformListCityCell