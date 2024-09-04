local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class UIPetRankUpPreviewItemCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetRankUpPreviewItemCell = class('UIPetRankUpPreviewItemCell', BaseTableViewProCell)

function UIPetRankUpPreviewItemCell:ctor()

end

function UIPetRankUpPreviewItemCell:OnCreate()
	self.statusRecord = self:StatusRecordParent("")
	self.detailText = self:Text("p_text_detail_n")
	self.detailTextSelected = self:Text("p_text_detail_selected")
	self.levelText = self:Text("p_text_lv")
end

function UIPetRankUpPreviewItemCell:OnShow(param)
end

function UIPetRankUpPreviewItemCell:OnOpened(param)
end

function UIPetRankUpPreviewItemCell:OnClose(param)
end

function UIPetRankUpPreviewItemCell:OnFeedData(data)
	if (data) then
		self.detailText.text = data.desc
		self.detailTextSelected.text = data.desc
		self.levelText.text = data.level
		if (data.selected) then
			self.statusRecord:ApplyStatusRecord(1)
		else
			self.statusRecord:ApplyStatusRecord(0)
		end
	end
end

function UIPetRankUpPreviewItemCell:Select(param)

end

function UIPetRankUpPreviewItemCell:UnSelect(param)

end

return UIPetRankUpPreviewItemCell;
