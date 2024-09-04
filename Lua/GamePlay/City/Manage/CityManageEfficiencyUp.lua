local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityManageEfficiencyUp:BaseUIComponent
local CityManageEfficiencyUp = class('CityManageEfficiencyUp', BaseUIComponent)

function CityManageEfficiencyUp:OnCreate()
    self._p_icon_efficiency = self:Image("p_icon_efficiency")
    self._p_text_efficiency = self:Text("p_text_efficiency")
    self._p_btn_goto_efficiency = self:Button("p_btn_goto_efficiency", Delegate.GetOrCreate(self, self.OnClickGoto))
end

function CityManageEfficiencyUp:OnFeedData(data)
    
end

function CityManageEfficiencyUp:OnClickGoto()
    
end

return CityManageEfficiencyUp