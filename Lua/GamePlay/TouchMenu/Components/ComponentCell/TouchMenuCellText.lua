local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class TouchMenuCellText:BaseUIComponent
local TouchMenuCellText = class('TouchMenuCellText', BaseUIComponent)

function TouchMenuCellText:OnCreate()
    self._p_text_description = self:Text("p_text_description")
    self.rectTransform = self:RectTransform("")
    self.sizeComp = self:BindComponent("", typeof(CS.CellSizeComponent))
end

---@param data TouchMenuCellTextDatum
function TouchMenuCellText:OnFeedData(data)
    self.data = data
    self._p_text_description.text = data.content
    if self.data:IsFlexibleHeight() and self.sizeComp then
        self.sizeComp:CalculateSize()
        self.preferHeight = self.sizeComp.Height
    end
end

function TouchMenuCellText:UsePreferHeight()
    if self.preferHeight then
        local sizeDelta = self.rectTransform.sizeDelta
        self.rectTransform.sizeDelta = {x = sizeDelta.x, y = self.preferHeight}
    end
end

return TouchMenuCellText