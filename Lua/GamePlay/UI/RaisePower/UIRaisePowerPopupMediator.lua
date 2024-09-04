local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local UIRaisePowerPopupMediatorContentProvider = require("UIRaisePowerPopupMediatorContentProvider")

---@class UIRaisePowerPopupMediator : BaseUIMediator
local UIRaisePowerPopupMediator = class('UIRaisePowerPopupMediator', BaseUIMediator)

---@class RaisePowerPopupParam
---@field overrideDefaultProvider UIRaisePowerPopupMediatorContentProvider
---@field type number RPPType
---@field continueCallback fun()
---@field hideButtons boolean

function UIRaisePowerPopupMediator:ctor()
    ---@type UIRaisePowerPopupMediatorContentProvider
    self.contentProvider = nil
	---@type RaisePowerPopupParam
	self.param = nil
end

function UIRaisePowerPopupMediator:OnCreate()
    self:InitObjects()
end

function UIRaisePowerPopupMediator:InitObjects()
	---@type CommonPopupBackComponent
	self.backComp = self:LuaObject("child_popup_base_s")
	self.textHint = self:Text("p_text_hint")
	self.continueButton = self:Button("p_btn_continue", Delegate.GetOrCreate(self, self.OnContinueButtonClick))
	self.continueText = self:Text("p_text_continue", "rpp_btn_battle")
	self.cancelButton = self:Button("p_btn_cancel", Delegate.GetOrCreate(self, self.OnCancelButtonClick))
	self.cancelText = self:Text("p_text_cancel", "rpp_btn_cancel")
	self.table = self:TableViewPro("p_table_way")
    self.btnRoot = self:GameObject("p_btns")
end

---@param param RaisePowerPopupParam
function UIRaisePowerPopupMediator:InitData(param)
	self.backComp:FeedData({
		title = self.contentProvider:GetTitle(),
	})
    self.textHint.text = self.contentProvider:GetHintText()
end

---@param param RaisePowerPopupParam
function UIRaisePowerPopupMediator:OnOpened(param)
	self.param = param
	if param.overrideDefaultProvider then
		self.contentProvider = param.overrideDefaultProvider
	else
		self.contentProvider = UIRaisePowerPopupMediatorContentProvider.new()
	end
	self.contentProvider:SetDefault(param, self)
	self.btnRoot:SetVisible(self.contentProvider:ShowBottomBtnRoot())
	if (param and param.hideButtons) then
		self.continueButton.gameObject:SetActive(false)
		self.cancelButton.gameObject:SetActive(false)
	end
	self:InitData(param)
	self:RefreshUI(param)
end

---@param param RaisePowerPopupParam
function UIRaisePowerPopupMediator:RefreshUI(param)
	self.table:Clear()
    local cellsData = self.contentProvider:GenerateTableCellData()
	for _, cell in ipairs(cellsData) do
        self.table:AppendData(cell)
	end
end

function UIRaisePowerPopupMediator:OnContinueButtonClick()
    local continue = self.contentProvider:GetContinueCallback()
	if (continue) then
		self:CloseSelf()
        continue()
	end
end

function UIRaisePowerPopupMediator:OnCancelButtonClick()
	self:CloseSelf()
end

return UIRaisePowerPopupMediator
