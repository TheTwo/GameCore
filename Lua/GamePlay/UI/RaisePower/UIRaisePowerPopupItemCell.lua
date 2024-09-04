local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local GuideUtils = require('GuideUtils')
local ModuleRefer = require('ModuleRefer')

---@class UIRaisePowerPopupItemCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIRaisePowerPopupItemCell = class('UIRaisePowerPopupItemCell', BaseTableViewProCell)

---@class UIRaisePowerPopupItemCellData
---@field iconId number
---@field text string
---@field gotoId number
---@field gotoCallback fun()
---@field showAsFinished boolean

function UIRaisePowerPopupItemCell:ctor()

end

function UIRaisePowerPopupItemCell:OnCreate()
	self.icon = self:Image("p_icon")
	self.text = self:Text("p_text_detail")
	self.gotoBtn = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClick))
    self.groupIcon = self:GameObject("p_group_icon")
    self.iconFinish = self:GameObject("p_icon_finish")
	self.iconLock = self:GameObject("p_icon_lock")
end


function UIRaisePowerPopupItemCell:OnShow(param)
end

function UIRaisePowerPopupItemCell:OnOpened(param)
end

function UIRaisePowerPopupItemCell:OnClose(param)

end

---@param param UIRaisePowerPopupItemCellData
function UIRaisePowerPopupItemCell:OnFeedData(param)
	local iconId = param and param.iconId or 0
	local text = param and param.text or ""
	self.gotoId = param and param.gotoId or 0
	self.gotoCallback = param and param.gotoCallback or nil
    self.showFinished = param and param.showAsFinished or false
	self.groupIcon:SetActive(iconId > 0)
	if (iconId > 0) then
		self:LoadSprite(iconId, self.icon)
	end
	self.text.text = text
	self.gotoBtn.gameObject:SetActive(self.gotoId > 0)
    self.iconFinish:SetVisible(self.gotoId <= 0 and self.showFinished)
	if param.systemEntryId then
		local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(param.systemEntryId)
		self.gotoBtn.gameObject:SetActive(unlocked)
		self.iconLock:SetActive(not unlocked)
	end
end

function UIRaisePowerPopupItemCell:OnClick(args)
	if (self.gotoId > 0) then
		if (self.gotoCallback) then
			self.gotoCallback()
		end
		GuideUtils.GotoByGuide(self.gotoId)
	end
end

return UIRaisePowerPopupItemCell;
