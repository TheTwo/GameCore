local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFarmLandTouchDragCell:BaseUIComponent
---@field new fun():CityFarmLandTouchDragCell
---@field super BaseUIComponent
local CityFarmLandTouchDragCell = class('CityFarmLandTouchDragCell', BaseUIComponent)

function CityFarmLandTouchDragCell:OnCreate(param)
    ---@type BaseItemIcon
    self._p_item_cost_cell = self:LuaObject("p_item_cost_cell")
    self._p_root_harvest = self:GameObject("p_root_harvest")
    self._p_img_harvest = self:Image("p_img_harvest")
    self._p_num_bubble_root = self:GameObject("p_num_bubble_root")
    self._p_num_bubble_root_status = self:StatusRecordParent("p_num_bubble_root")
    self._p_text_number = self:Text("p_text_number")
    self._selfTrans = self:RectTransform("")
end

---@param data CityFarmLandTouchCellData
function CityFarmLandTouchDragCell:OnFeedData(data)
    self._p_root_harvest:SetVisible(data.harvestMode)
    self._p_item_cost_cell:SetVisible(not data.harvestMode)
    self._p_num_bubble_root:SetVisible(not data.harvestMode)
    if data.harvestMode then
        if not string.IsNullOrEmpty(data.harvestIcon) then
            g_Game.SpriteManager:LoadSprite(data.harvestIcon, self._p_img_harvest)
        end
    else
        local config = data.cropConfig
        local itemId = config:ItemId()
        local item = ConfigRefer.Item:Find(itemId)
        ---@type ItemIconData
        local iconData = {}
        iconData.configCell = item
        iconData.showCount = false
        self._p_item_cost_cell:FeedData(iconData)
    end
end

---@param worldPos CS.UnityEngine.Vector3
function CityFarmLandTouchDragCell:UpdatePos(worldPos)
    local localPos = self._selfTrans.parent:InverseTransformPoint(worldPos)
    self._selfTrans.anchoredPosition = CS.UnityEngine.Vector2(localPos.x, localPos.y) 
end

function CityFarmLandTouchDragCell:UpdateLeftCount(count)
    self._p_text_number.text = tostring(count)
    self._p_num_bubble_root_status:SetState(count <= 0 and 1 or 0)
end

return CityFarmLandTouchDragCell