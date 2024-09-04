local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
local NM = ModuleRefer.NotificationModule

---@class UIPetTypeIconTableViewCell : BaseTableViewProCell
local UIPetTypeIconTableViewCell = class('UIPetTypeIconTableViewCell', BaseTableViewProCell)

---@class UIPetTypeIconData
---@field id number
---@field icon number
---@field selected boolean
---@field hasPet boolean
---@field onClick fun(id: number)
---@field heroList table

function UIPetTypeIconTableViewCell:ctor()

end

function UIPetTypeIconTableViewCell:OnCreate()
	self._button = self:Button("p_btn_pet", Delegate.GetOrCreate(self, self.OnClick))
	self._selected = self:GameObject("p_base_select")
	self._icon = self:Image("p_pet_head")
	self._mask1 = self:Image("head_shine")
	self._mask2 = self:Image("head_bitmap")
	self._mask3 = self:Image("head_glitch")
    self.goHead = self:GameObject('p_head')
    self.imgIconHint = self:Image('p_icon_hint')
	self.goImgMask = self:GameObject('p_img_mask')
    self.compChildCardHeroSEx1 = self:LuaObject('child_card_hero_s_ex1')
    self.compChildCardHeroSEx2 = self:LuaObject('child_card_hero_s_ex2')
    self.compChildCardHeroSEx3 = self:LuaObject('child_card_hero_s_ex3')
	--self._selected:SetActive(false)
	if self.goHead then
		self.goIconHint = self:GameObject('p_icon_hint')
		self.goHead1 = self:GameObject('p_head_1')
		self.compChildCardHeroSEx1 = self:LuaObject('child_card_hero_s_ex1')
		self.goHead2 = self:GameObject('p_head_2')
		self.compChildCardHeroSEx2 = self:LuaObject('child_card_hero_s_ex2')
		self.goHead3 = self:GameObject('p_head_3')
		self.compChildCardHeroSEx3 = self:LuaObject('child_card_hero_s_ex3')
		self.goHead:SetActive(false)
		self.goHeads = {self.goHead1, self.goHead2, self.goHead3}
		self.compHeads = {self.compChildCardHeroSEx1, self.compChildCardHeroSEx2, self.compChildCardHeroSEx3}
	end
	---@type NotificationNode
	self.redDot = self:LuaObject("child_reddot_default")
end


function UIPetTypeIconTableViewCell:OnShow(param)
end

function UIPetTypeIconTableViewCell:OnOpened(param)
end

function UIPetTypeIconTableViewCell:OnClose(param)
end

---@param param UIPetTypeIconData
function UIPetTypeIconTableViewCell:OnFeedData(param)
	if (param) then
		self.id = param.id
		self.onClick = param.onClick
		self.selected = param.selected
		self.icon = param.icon
		self.hasPet = param.hasPet
		self.heroList = param.heroList or {}
		self.forbidCarry = param.forbidCarry
	end
	if (self.icon and self.icon > 0) then
		self:LoadSprite(self.icon, self._icon)
		-- if self._mask1 then
		-- 	self:LoadSprite(self.icon, self._mask1)
		-- end
		-- if self._mask2 then
		-- 	self:LoadSprite(self.icon, self._mask2)
		-- end
		if (self._mask1) then
			self._mask1.gameObject:SetActive(false)
		end
		if (self._mask2) then
			self._mask2.gameObject:SetActive(false)
		end
		if (self._mask3) then
			self._mask3.gameObject:SetActive(false)
		end
	end
	if self.selected ~= nil then
		self._selected:SetActive(self.selected == true)
	end
	UIHelper.SetGray(self._icon.gameObject, not self.hasPet)
	if Utils.IsNotNull(self.goImgMask) then
		self.goImgMask:SetActive(self.forbidCarry)
	end
	if self.goHead then
		local isShow = #self.heroList > 0
		self.goHead:SetActive(isShow)
		if isShow then
			local isConflict = #self.heroList > 1
			self.goIconHint:SetActive(isConflict)
			for index, goHead in ipairs(self.goHeads) do
				local isShowHead = index <= #self.heroList
				goHead:SetActive(isShowHead)
				if isShowHead then
					local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(self.heroList[index])
					self.compHeads[index]:FeedData({heroData = heroData})
				end
			end
		end
	end

	-- 红点
	if (self.redDot) then
		-- local node = ModuleRefer.PetModule:GetRedDotType(self.id)
		local node = nil -- 红点不再有类型
		if (node) then
			self.redDot.go:SetActive(true)
			NM:AttachToGameObject(node, self.redDot.go)
		else
			self.redDot.go:SetActive(false)
		end
	end
end

function UIPetTypeIconTableViewCell:Select(param)
	if self.selected == nil then
		self._selected:SetActive(true)
	end
end

function UIPetTypeIconTableViewCell:UnSelect(param)
	if self.selected == nil then
		self._selected:SetActive(false)
	end
end

function UIPetTypeIconTableViewCell:OnClick(args)
	if self.selected == nil then
		self:SelectSelf()
	end
	if (self.onClick) then
		self.onClick(self.id)
	end
end

return UIPetTypeIconTableViewCell;
