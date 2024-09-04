local BaseUIComponent = require ('BaseUIComponent')

---@class CityFurniturePlaceLegoRoomBuffUINode:BaseUIComponent
local CityFurniturePlaceLegoRoomBuffUINode = class('CityFurniturePlaceLegoRoomBuffUINode', BaseUIComponent)

---@class UIRoomBuffNode
---@field image string
---@field isPlaced boolean
---@field isPreview boolean

function CityFurniturePlaceLegoRoomBuffUINode:OnCreate()
    self._p_img_furniture = self:Image("p_img_furniture")
    self._p_icon_check = self:GameObject("p_icon_check")
    self._trigger_templates = self:AnimTrigger("trigger_templates")
end

---@param data UIRoomBuffNode
function CityFurniturePlaceLegoRoomBuffUINode:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.image, self._p_img_furniture)
    self._p_icon_check:SetActive(data.isPlaced)
    self._trigger_templates:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    if data.isPreview then
        self._trigger_templates:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

return CityFurniturePlaceLegoRoomBuffUINode