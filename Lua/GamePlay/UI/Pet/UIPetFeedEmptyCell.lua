local Delegate = require("Delegate")
local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class UIPetFeedEmptyCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetFeedEmptyCell = class('UIPetFeedEmptyCell', BaseTableViewProCell)

function UIPetFeedEmptyCell:ctor()

end

function UIPetFeedEmptyCell:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

function UIPetFeedEmptyCell:OnClick(args)
	if self.onClick then
		self.onClick()
	end
end

function UIPetFeedEmptyCell:OnShow(param)
end

function UIPetFeedEmptyCell:OnOpened(param)
end

function UIPetFeedEmptyCell:OnClose(param)
end

---@param param HeroConfigCache
function UIPetFeedEmptyCell:OnFeedData(data)
    self.onClick = data.onClick
end

function UIPetFeedEmptyCell:Select(param)

end

function UIPetFeedEmptyCell:UnSelect(param)

end

return UIPetFeedEmptyCell;
