local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class UIPetTypeAllTableViewCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetTypeAllTableViewCell = class('UIPetTypeAllTableViewCell', BaseTableViewProCell)

function UIPetTypeAllTableViewCell:ctor()

end

function UIPetTypeAllTableViewCell:OnCreate()
	self.button = self:Button("p_btn_all", Delegate.GetOrCreate(self, self.OnClick))
	self.textAll = self:Text("p_text_all", "pet_type_name0")
	self.selected = self:GameObject("p_base_select")
end


function UIPetTypeAllTableViewCell:OnShow(param)
end

function UIPetTypeAllTableViewCell:OnOpened(param)
end

function UIPetTypeAllTableViewCell:OnClose(param)
end

function UIPetTypeAllTableViewCell:OnFeedData(data)
	if (data) then
		self.selected:SetActive(data.selected == true)
		self.onClick = data.onClick
	else
		self.selected:SetActive(false)
	end
end

function UIPetTypeAllTableViewCell:Select(param)

end

function UIPetTypeAllTableViewCell:UnSelect(param)

end

function UIPetTypeAllTableViewCell:OnClick()
	if (self.onClick) then
		self.onClick()
	end
end

return UIPetTypeAllTableViewCell;
