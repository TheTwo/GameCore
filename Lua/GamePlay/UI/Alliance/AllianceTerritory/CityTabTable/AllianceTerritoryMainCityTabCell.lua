local Delegate = require("Delegate")
local I18N = require("I18N")
local GotoUtils = require("GotoUtils")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomScene = require("KingdomScene")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local ColorConsts = require("ColorConsts")
local ModuleRefer = require("ModuleRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryMainCityTabCellData
---@field serverData wds.MapBuildingBrief
---@field config FixedMapBuildingConfigCell
---@field territoryConfig TerritoryConfigCell
---@field isRebuilding boolean

---@class AllianceTerritoryMainCityTabCell:BaseUIComponent
---@field new fun():AllianceTerritoryMainCityTabCell
---@field super BaseUIComponent
local AllianceTerritoryMainCityTabCell = class('AllianceTerritoryMainCityTabCell', BaseUIComponent)

function AllianceTerritoryMainCityTabCell:OnCreate(param)
    self._p_icon_territory = self:Image("p_icon_territory")
    self._p_text_lv_territory = self:Text("p_text_lv_territory")
    self._p_text_name_territory = self:Text("p_text_name_territory")
    self._p_text_position = self:Text("p_text_position")
    self._p_btn_click_go = self:Button("p_btn_click_go", Delegate.GetOrCreate(self, self.OnClickGoTo))
    self._p_icon_transform = self:GameObject("p_icon_transform")
    self._p_base_construction = self:GameObject("p_base_construction")
    self._p_construction = self:GameObject("p_construction")
    self._p_text_construction = self:Text("p_text_construction")
    self._p_slider_build = self:Slider("p_slider_build")
    self._p_btn_add = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickGoTo))
end

---@param data AllianceTerritoryMainCityTabCellData
function AllianceTerritoryMainCityTabCell:OnFeedData(data)
    self._data = data
    g_Game.SpriteManager:LoadSprite(data.config:Image(), self._p_icon_territory)
    self._p_text_lv_territory.text = string.format("Lv:%s", data.config:Level())
    self._p_text_name_territory.text = I18N.Get(data.config:Name())
    local layoutX,layoutY = KingdomMapUtils.GetLayoutSize(data.config:Layout())
    local pos = self:GetPos()
    local edgePointX = math.floor(pos.X - layoutX * 0.5)
    local edgePointY = math.floor(pos.Y - layoutY * 0.5)
    self._p_text_position.text = string.format('<a><color="%s">X:%d Y:%d</color></a>', ColorConsts.dark_grey, edgePointX, edgePointY)
    local currentIsAllianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
	self._p_icon_transform:SetVisible(currentIsAllianceCenter and currentIsAllianceCenter == data.serverData.EntityID)

    if self._data.isRebuilding then
        self._p_construction:SetVisible(true)
        ---@type wds.RuinRebuildBuildingInfo
        local rebuild = self._data.serverData
        local percent = tostring(rebuild.BuildProgressPercent) .. "%%"
        self._p_text_construction.text = I18N.GetWithParams("village_outpost_info_under_construction_2", percent)
        self._p_slider_build.value = rebuild.BuildProgressPercent / 100
    else
        self._p_construction:SetVisible(false)
    end
end

function AllianceTerritoryMainCityTabCell:OnClickGoTo()
    local toPos = self:GetPos()
    self:GetParentBaseUIMediator():CloseSelf(nil, true)
    AllianceWarTabHelper.GoToCoord(toPos.X, toPos.Y)
end

function AllianceTerritoryMainCityTabCell:GetPos()
    local pos
    if self._data.serverData.Pos then
        pos = self._data.serverData.Pos
    elseif self._data.territoryConfig then
        local territoryPos = self._data.territoryConfig:VillagePosition()
        pos = { X = territoryPos:X(), Y = territoryPos:Y()}
    end
    return pos
end


return AllianceTerritoryMainCityTabCell
