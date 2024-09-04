local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class UIPetEmptyViewCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetEmptyViewCell = class('UIPetEmptyViewCell', BaseTableViewProCell)

function UIPetEmptyViewCell:ctor()

end

function UIPetEmptyViewCell:OnCreate()

end


function UIPetEmptyViewCell:OnShow(param)
end

function UIPetEmptyViewCell:OnOpened(param)
end

function UIPetEmptyViewCell:OnClose(param)
end

---@param data UIPetIconData
function UIPetEmptyViewCell:OnFeedData(data)

end

function UIPetEmptyViewCell:Select(param)

end

function UIPetEmptyViewCell:UnSelect(param)

end

return UIPetEmptyViewCell;
