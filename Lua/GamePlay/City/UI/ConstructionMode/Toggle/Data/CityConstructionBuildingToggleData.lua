---@class CityConstructionBuildingToggleData
---@field new fun():CityConstructionBuildingToggleData
local CityConstructionBuildingToggleData = class("CityConstructionBuildingToggleData")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local ConfigRefer = require("ConfigRefer")

---@param uiMediator CityConstructionModeUIMediator
function CityConstructionBuildingToggleData:ctor(uiMediator)
    self.uiMediator = uiMediator
end

function CityConstructionBuildingToggleData:OnClick()
    if self.uiMediator:SelectToggle(self) then
        self:OnClickImp()
    end
end

function CityConstructionBuildingToggleData:OnClickImp()
    self.uiMediator:ShowBuildingList()
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionBuildingToggleData:FeedCell(cell)
    self.cell = cell
    g_Game.SpriteManager:LoadSprite(ConfigRefer.CityConfig:ConstBuilding(), self.cell._p_icon_tab_a)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.CityConfig:ConstBuilding(), self.cell._p_icon_tab_b)
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(ModuleRefer.CityConstructionModule.notifyBuildingTagName, NotificationType.CITY_CONSTRUCTION_TAG_BUILDING, self.cell._child_reddot_default.go, self.cell._child_reddot_default.redNew)
end

function CityConstructionBuildingToggleData:Selected()
    self.cell._p_tab_a:SetActive(false)
    self.cell._p_tab_b:SetActive(true)
end

function CityConstructionBuildingToggleData:UnSelected()
    self.cell._p_tab_a:SetActive(true)
    self.cell._p_tab_b:SetActive(false)
    ModuleRefer.CityConstructionModule:RefreshBuildingDotsDirty()
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionBuildingToggleData:OnClose(cell)
    ModuleRefer.CityConstructionModule:RefreshBuildingDotsDirty()
end

return CityConstructionBuildingToggleData