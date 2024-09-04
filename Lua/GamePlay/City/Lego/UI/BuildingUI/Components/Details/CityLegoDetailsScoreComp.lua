local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityLegoDetailsScoreComp:BaseUIComponent
local CityLegoDetailsScoreComp = class('CityLegoDetailsScoreComp', BaseUIComponent)

function CityLegoDetailsScoreComp:OnCreate()
    self._p_text_property_name = self:Text("p_text_property_name", "fur_score")
    self._p_text_property_value_old = self:Text("p_text_property_value_old")
end

---@param furniture CityFurniture
function CityLegoDetailsScoreComp:OnFeedData(furniture)
    self._p_text_property_value_old.text = ("+%d"):format(furniture.furnitureCell:AddScore())
end

return CityLegoDetailsScoreComp