local BaseUIComponent = require('BaseUIComponent')
local NodeLineCell = class('NodeLineCell',BaseUIComponent)

function NodeLineCell:OnCreate(param)
    self.goLineN = self:GameObject('p_line_n')
    self.goLineUnlock = self:GameObject('p_line_unlock')
end

function NodeLineCell:OnFeedData(isLight)
    self.goLineN:SetActive(not isLight)
    self.goLineUnlock:SetActive(isLight)
end

return NodeLineCell
