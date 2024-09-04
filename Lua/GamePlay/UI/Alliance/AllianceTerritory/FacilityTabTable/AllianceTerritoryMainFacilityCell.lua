local Delegate = require("Delegate")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainFacilityCellData
---@field serverData wds.MapBuildingBrief[]|nil
---@field config FlexibleMapBuildingConfigCell

---@class AllianceTerritoryMainFacilityCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainFacilityCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainFacilityCell = class('AllianceTerritoryMainFacilityCell', BaseTableViewProCell)

function AllianceTerritoryMainFacilityCell:OnCreate(param)
    self._p_icon_facility = self:Image("p_icon_facility")
    self._p_text_lv_facility = self:Text("p_text_lv_facility")
    self._p_text_name_facility = self:Text("p_text_name_facility")
    self._p_text_constructed = self:Text("p_text_constructed")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetail))
    self._p_btn_view = self:Button("p_btn_view", Delegate.GetOrCreate(self, self.OnClickBtnView))
    self._p_status_lock = self:GameObject("p_status_lock")
end

---@param data AllianceTerritoryMainFacilityCellData
function AllianceTerritoryMainFacilityCell:OnFeedData(data)
    self._data = data
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(self._data.config:Image()), self._p_icon_facility)
    self._p_text_lv_facility.text = string.format("Lv:%s", self._data.config:Level())
    self._p_text_name_facility.text = I18N.Get(self._data.config:Name())
    if not data.serverData then
        self._p_status_lock:SetVisible(true)
        self._p_text_constructed:SetVisible(false)
        self._p_btn_view:SetVisible(false)
    else
        self._p_status_lock:SetVisible(false)
        self._p_text_constructed:SetVisible(true)
        self._p_btn_view:SetVisible(#data.serverData > 0)
        self._p_text_constructed.text = I18N.GetWithParams("alliance_bj_yijianzao", #data.serverData)
    end
end

function AllianceTerritoryMainFacilityCell:OnClickBtnDetail()
    ---@type AllianceBuildingDetailMediatorParameter
    local parameter = {}
    parameter.isUnlocked = ModuleRefer.AllianceTechModule:IsBuildingTechSatisfy(self._data.config) and ModuleRefer.AllianceTechModule:IsBuildingAllianceCenterSatisfy(self._data.config) and ModuleRefer.KingdomConstructionModule:GetBuildingLimitCount(self._data.config) > 0
    parameter.buildingConfig = self._data.config
    parameter.clickRectTrans = self._p_btn_detail:GetComponent(typeof(CS.UnityEngine.RectTransform))
    g_Game.UIManager:Open(UIMediatorNames.AllianceBuildingDetailMediator, parameter)
end

function AllianceTerritoryMainFacilityCell:OnClickBtnView()
    ---@type AllianceBuildingPositionMediatorParameter
    local parameter = {}
    parameter.clickRectTrans = self._p_btn_view:GetComponent(typeof(CS.UnityEngine.RectTransform))
    parameter.parentMediatorId = self:GetParentBaseUIMediator():GetRuntimeId()
    parameter.position = {}
    for _, v in pairs(self._data.serverData) do
        table.insert(parameter.position, {x=math.floor(v.Pos.X + 0.5),y=math.floor(v.Pos.Y + 0.5)})
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceBuildingPositionMediator, parameter)
end

return AllianceTerritoryMainFacilityCell