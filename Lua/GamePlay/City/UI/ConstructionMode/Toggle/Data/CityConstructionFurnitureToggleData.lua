---@class CityConstructionFurnitureToggleData
---@field new fun():CityConstructionFurnitureToggleData
local CityConstructionFurnitureToggleData = class("CityConstructionFurnitureToggleData")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local ConfigRefer = require("ConfigRefer")

---@param uiMediator CityConstructionModeUIMediator
---@param category number @enum-FurnitureCategory
function CityConstructionFurnitureToggleData:ctor(uiMediator, category)
    self.uiMediator = uiMediator
    self.category = category
end

function CityConstructionFurnitureToggleData:OnClick()
    if self.uiMediator:SelectToggle(self) then
        self:OnClickImp()
    end
end

function CityConstructionFurnitureToggleData:OnClickImp()
    self.uiMediator:ShowNormalFurnitureList(self.category)
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionFurnitureToggleData:FeedCell(cell)
    self.cell = cell
    local image = string.Empty
    for i = 1, ConfigRefer.CityConfig:CityFurnitureCategoryUILength() do
        local unit = ConfigRefer.CityConfig:CityFurnitureCategoryUI(i)
        if unit:Category() == self.category then
            image = unit:Image()
            break
        end
    end
    g_Game.SpriteManager:LoadSprite(image, self.cell._p_icon_tab_a)
    g_Game.SpriteManager:LoadSprite(image, self.cell._p_icon_tab_b)
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(("%s_%d"):format(ModuleRefer.CityConstructionModule.notifyFurnitureName, self.category), NotificationType.CITY_CONSTRUCTION_TAG_FURNITURE, self.cell._child_reddot_default.go, self.cell._child_reddot_default.redNew)
end

function CityConstructionFurnitureToggleData:Selected()
    self.cell._p_tab_a:SetActive(false)
    self.cell._p_tab_b:SetActive(true)
end

function CityConstructionFurnitureToggleData:UnSelected()
    self.cell._p_tab_a:SetActive(true)
    self.cell._p_tab_b:SetActive(false)
    ModuleRefer.CityConstructionModule:ClearFurnitureRedDots(self.category)
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionFurnitureToggleData:OnClose(cell)
    ModuleRefer.CityConstructionModule:ClearFurnitureRedDots(self.category)
end

return CityConstructionFurnitureToggleData