local BaseUIComponent = require('BaseUIComponent')
---@class CommonScrollDot : BaseUIComponent
local CommonScrollDot = class('CommonScrollDot', BaseUIComponent)

function CommonScrollDot:OnCreate()
    self.dotOnShow = self:GameObject('p_dot_select_1')
    self.dotOnHide = self:GameObject('p_dot_n_1')
end

function CommonScrollDot:SetDotVisible(shouldShow)
    self.dotOnShow:SetActive(shouldShow)
    self.dotOnHide:SetActive(not shouldShow)
end

return CommonScrollDot