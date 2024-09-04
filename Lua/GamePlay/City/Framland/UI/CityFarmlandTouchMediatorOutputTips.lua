local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFarmlandTouchMediatorOutputTips:BaseUIMediator
---@field new fun():CityFarmlandTouchMediatorOutputTips
---@field super BaseUIMediator
local CityFarmlandTouchMediatorOutputTips = class('CityFarmlandTouchMediatorOutputTips', BaseUIComponent)

function CityFarmlandTouchMediatorOutputTips:OnCreate(param)
    self.SelfTrans = self:RectTransform("")
    self._p_text_title = self:Text("p_text_title")
    self._p_text_item_1 = self:Text("p_text_item_1", "farm_info_prossess")
    self._p_text_content_1 = self:Text("p_text_content_1")
    self._p_text_item_2 = self:Text("p_text_item_2", "farm_info_timecost")
    self._p_text_content_2 = self:Text("p_text_content_2")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_icon_content_1 = self:Image("p_icon_content_1")
end

---@param data CityFarmLandTouchCellData
function CityFarmlandTouchMediatorOutputTips:OnFeedData(data)
    local config = data.cropConfig
    local outputItemConfig = ConfigRefer.Item:Find(config:ItemId())
    self._p_text_title.text = I18N.Get(outputItemConfig:NameKey())
    self._p_text_content_1.text = tostring(ModuleRefer.InventoryModule:GetAmountByConfigId(config:ItemId()))
    self._p_text_content_2.text = TimeFormatter.SimpleFormatTimeWithoutZero(config:RipeTime())
    self._p_text_detail.text = I18N.Get(outputItemConfig:DescKey())
    g_Game.SpriteManager:LoadSprite(outputItemConfig:Icon(), self._p_icon_content_1)
end

return CityFarmlandTouchMediatorOutputTips