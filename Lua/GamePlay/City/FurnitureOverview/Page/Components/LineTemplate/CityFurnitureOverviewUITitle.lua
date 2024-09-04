local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityFurnitureOverviewUITitle:BaseUIComponent
local CityFurnitureOverviewUITitle = class('CityFurnitureOverviewUITitle', BaseUIComponent)

function CityFurnitureOverviewUITitle:OnCreate()
    self._p_text_title = self:Text("p_text_title")
end

function CityFurnitureOverviewUITitle:OnFeedData(data)
    self._p_text_title.text = data
end

return CityFurnitureOverviewUITitle