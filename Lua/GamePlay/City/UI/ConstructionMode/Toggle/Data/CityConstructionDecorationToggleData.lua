---@class CityConstructionDecorationToggleData
---@field new fun():CityConstructionDecorationToggleData
local CityConstructionDecorationToggleData = class("CityConstructionDecorationToggleData")
local NotificationType = require("NotificationType")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local FurnitureCategory = require("FurnitureCategory")

---@param uiMediator CityConstructionModeUIMediator
function CityConstructionDecorationToggleData:ctor(uiMediator)
    self.uiMediator = uiMediator
end

function CityConstructionDecorationToggleData:OnClick()
    if self.uiMediator:SelectToggle(self) then
        self:OnClickImp()
    end
end

function CityConstructionDecorationToggleData:OnClickImp()
    self.uiMediator:ShowDecorationList()
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionDecorationToggleData:FeedCell(cell)
    self.cell = cell
    g_Game.SpriteManager:LoadSprite(ConfigRefer.CityConfig:ConstDecorate(), self.cell._p_icon_tab_a)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.CityConfig:ConstDecorate(), self.cell._p_icon_tab_b)
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(ModuleRefer.CityConstructionModule.notifyDecorationName, NotificationType.CITY_CONSTRUCTION_TAG_DECORATION, self.cell._child_reddot_default.go, self.cell._child_reddot_default.redNew)
end

function CityConstructionDecorationToggleData:Selected()
    self.cell._p_tab_a:SetActive(false)
    self.cell._p_tab_b:SetActive(true)
end

function CityConstructionDecorationToggleData:UnSelected()
    self.cell._p_tab_a:SetActive(true)
    self.cell._p_tab_b:SetActive(false)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_CANCEL_PLACE)
    ModuleRefer.CityConstructionModule:ClearFurnitureRedDots(FurnitureCategory.Decoration)
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionDecorationToggleData:OnClose(cell)
    ModuleRefer.CityConstructionModule:ClearFurnitureRedDots(FurnitureCategory.Decoration)
end

return CityConstructionDecorationToggleData