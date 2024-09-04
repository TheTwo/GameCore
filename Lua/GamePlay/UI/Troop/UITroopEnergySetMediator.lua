local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local CommonDropDown = require("CommonDropDown")
local ConfigRefer = require("ConfigRefer")
local TimerUtility = require("TimerUtility")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local Screen = CS.UnityEngine.Screen
local AttackDistanceType = require("AttackDistanceType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

---@class UITroopEnergySetMediator : BaseUIMediator
local UITroopEnergySetMediator = class('UITroopEnergySetMediator', BaseUIMediator)

local MAX_VALUE = 100
local MIN_VALUE = 0
local DEFAULT_VALUE = MAX_VALUE
local WARNING_THRESHOLD = 30
local DEFAULT_AUTO_FULFILL_HP_RATIO = 100
function UITroopEnergySetMediator:ctor()
	---@type fun(value: number)
	self._setCallback = nil	
end

function UITroopEnergySetMediator:OnCreate()
	self:InitObjects()
end

function UITroopEnergySetMediator:InitObjects()
	self.numberText = self:Text("p_text_number")
	---@type CommonNumberSlider
	self.slider = self:LuaObject("child_set_bar")
	self.titleText = self:Text("p_text_title", "NewFormation_EnergyUsingTitle")
	self.detailButton = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnDetailButtonClicked))
	self.hintText = self:Text("p_text_hint", "NewFormation_LowProportionWarning")
	self.setButton = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnSetButtonClicked))
	self.setButtonText = self:Text("p_text", "NewFormation_EnergyUsingSave")

	self.autoAddEnergyText = self:Text("p_text_add", "NewFormation_EnergyButton")
	self.autoAddNumber = self:Text("p_text_number")
	self.energyRestoreText = self:Text("p_text_hint")

	self.autoFillButton = self:Button("p_pading", Delegate.GetOrCreate(self, self.OnAutoFillButtonClick))
	self.autoFillOff = self:GameObject("p_base_off")
	self.autoFillOn = self:GameObject("p_base_on")
	self:Text('p_text_switch',"formation_autorecoer")
end

function UITroopEnergySetMediator:OnShow(param)	
	self._autoFillOn = param and param.autoFulfillHp or false
	self._autoFillRatio = param and param.autoFillHpRatio or DEFAULT_AUTO_FULFILL_HP_RATIO		
	self._setCallback = param and param.setCallback
    self:RefreshUI()
end

function UITroopEnergySetMediator:OnHide(param)
end

function UITroopEnergySetMediator:OnOpened(param)
end

function UITroopEnergySetMediator:OnClose(param)
	if (self._setCallback) then
		self._setCallback(self._autoFillOn,self._autoFillRatio)
	end	
end

--- 刷新UI
---@param self UITroopEnergySetMediator
function UITroopEnergySetMediator:RefreshUI()

	self.autoAddNumber.text = tostring(self._autoFillRatio) .. "%"	
	self.autoFillOff:SetActive(not self._autoFillOn)
	self.autoFillOn:SetActive(self._autoFillOn)
	self.slider:FeedData({
		minNum = MIN_VALUE,
		maxNum = MAX_VALUE,
		curNum = self._autoFillRatio,
		callBack = Delegate.GetOrCreate(self, self.OnSliderValueChanged),
	})
	self:OnSliderValueChanged(self._autoFillRatio)
end

function UITroopEnergySetMediator:OnDetailButtonClicked()
	local content = I18N.Get("NewFormation_EnergyFillIntroduction")
	ModuleRefer.ToastModule:ShowTextToast({
		content = content,
		clickTransform = self.detailButton.transform,
	})
end

function UITroopEnergySetMediator:OnSetButtonClicked()	
	self:CloseSelf()
end

function UITroopEnergySetMediator:OnSliderValueChanged(value)	
	self.numberText.text = value .. "%"
	self._autoFillRatio = value
	self.hintText.gameObject:SetActive(value < WARNING_THRESHOLD)
end

---@param self UITroopMediator
function UITroopEnergySetMediator:OnAutoFillButtonClick()	
	self._autoFillOn = not self._autoFillOn
	self.autoFillOff:SetActive(not self._autoFillOn)
	self.autoFillOn:SetActive(self._autoFillOn)
end




return UITroopEnergySetMediator
