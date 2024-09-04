local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class UIPetIconCellEx : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetIconCellEx = class('UIPetIconCellEx', BaseTableViewProCell)

function UIPetIconCellEx:ctor()

end

function UIPetIconCellEx:OnCreate()
	self._comp = self:LuaObject("child_card_pet_s")
	self._slider = self:Slider("p_progress_exp_pet")
	self._expGroup = self:GameObject("exp")
	self._expText = self:Text("p_text_exp_pet")
	self._expNumText = self:Text("p_text_exp_pet_num")
	self._expFullText = self:Text("p_text_exp_pet_full")
end


function UIPetIconCellEx:OnShow(param)
end

function UIPetIconCellEx:OnOpened(param)
end

function UIPetIconCellEx:OnClose(param)
end

function UIPetIconCellEx:OnFeedData(param)
	if (not param) then return end
	if (self._comp) then
		self._comp:FeedData(param.data)
	end
	-- if (param.onGetSlider) then
	-- 	param.onGetSlider(param.index, self._slider)
	-- end
	self._slider.gameObject:SetActive(param.showExp == true)
	self._slider.value = param.expPercent
	self._expGroup:SetActive(param.showExp == true)
	self._expText.text = param.expText
	self._expNumText.text = param.expNumText
	self._expFullText.text = param.expFullText
	self._expFullText.gameObject:SetActive(param.showExp == false)
end

return UIPetIconCellEx;
