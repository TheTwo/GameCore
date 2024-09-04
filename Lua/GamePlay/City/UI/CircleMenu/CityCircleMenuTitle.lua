local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityCircleMenuTitle:BaseUIComponent
local CityCircleMenuTitle = class('CityCircleMenuTitle', BaseUIComponent)

function CityCircleMenuTitle:OnCreate()
    self._p_text_city_name = self:Text("p_text_city_name")
    self._p_text_timer = self:Text("p_text_timer")
    self._p_lvl = self:GameObject("p_lvl")
    self._p_text_lvl = self:Text("p_text_lvl")
end

return CityCircleMenuTitle