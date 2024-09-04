local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityLegoBuffToastUIAttr:BaseUIComponent
local CityLegoBuffToastUIAttr = class('CityLegoBuffToastUIAttr', BaseUIComponent)

function CityLegoBuffToastUIAttr:OnCreate()
    self._p_icon_buff = self:Image("p_icon_buff")
    self._p_text_buff = self:Text("p_text_buff")
end

function CityLegoBuffToastUIAttr:OnFeedData(data)
    
end

return CityLegoBuffToastUIAttr