local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')

---@class UIWorldSearchState
---@field mediator UIWorldSearchMediator
---@field level number
local UIWorldSearchState = class("UIWorldSearchState")

---@param mediator UIWorldSearchMediator
function UIWorldSearchState:Select(mediator, data)
    self.mediator = mediator
    self.level = 1
end

function UIWorldSearchState:Unselect()
    self.mediator = nil
end

function UIWorldSearchState:SetLevel(level)
    self.level = level
    local maxAttackLevel, maxLevel = self:GetMaxLevels()
    local max = math.min(maxAttackLevel, maxLevel)
    local levelString = string.format("<b>%s</b>", level) .. UIHelper.GetColoredText("/" .. max, ColorConsts.light_grey)
    self.mediator.textInputQuantity.text = levelString
end

function UIWorldSearchState:GetSearchCategory()

end

function UIWorldSearchState:GetSelectedID()
    
end

---@return number, number
function UIWorldSearchState:GetMaxLevels()
    return -1, -1
end

function UIWorldSearchState:GetReachMaxAttackLevelTip()
    
end

return UIWorldSearchState