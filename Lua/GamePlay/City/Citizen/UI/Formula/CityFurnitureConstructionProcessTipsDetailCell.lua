local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityFurnitureConstructionProcessTipsDetailCell:BaseTableViewProCell
---@field new fun():CityFurnitureConstructionProcessTipsDetailCell
---@field super BaseTableViewProCell
local CityFurnitureConstructionProcessTipsDetailCell = class('CityFurnitureConstructionProcessTipsDetailCell', BaseTableViewProCell)

function CityFurnitureConstructionProcessTipsDetailCell:OnCreate(param)
    self._p_icon_tips = self:Image("p_icon_tips")
    self._p_text_tips = self:Text("p_text_tips", I18N.Temp().text_produce_gift)
    self._p_text_tips_num = self:Text("p_text_tips_num")
end

function CityFurnitureConstructionProcessTipsDetailCell:OnFeedData(data)
    
end

return CityFurnitureConstructionProcessTipsDetailCell