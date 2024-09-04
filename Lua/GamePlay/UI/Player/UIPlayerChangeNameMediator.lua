---scene: scene_common_popup_change_name
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local InputFieldWithCheckStatus = require("InputFieldWithCheckStatus")
local UIHelper = require("UIHelper")

---@class UIPlayerChangeNameMediator : BaseUIMediator
local UIPlayerChangeNameMediator = class('UIPlayerChangeNameMediator', BaseUIMediator)

---@class UIPlayerChangeNameMediatorParameter
---@field changeName boolean
---@field pvpDefenceWord boolean

local __self
local __invalid = true
local __inCd = false

local NAME_LENGTH_MIN = 3
local NAME_LENGTH_MAX = 14
local SIGNATURE_LENGTH_MIN = 0
local SIGNATURE_LENGTH_MAX = 100
local DEFENCE_LENGTH_MIN = 0
local DEFENCE_LENGTH_MAX = 100
local CD_NAME_CHANGE = 10
local CD_SIGNATURE_CHANGE = 10
local CD_DEFENCE_CHANGE = 0

function UIPlayerChangeNameMediator:ctor()
	self.changeName = true	-- false为修改签名
	self.oldValue = nil
	self.resourceItemId = -1
	self.resourceItemNeed = 0
	self.onResourceItemChangeHandle = nil
end

function UIPlayerChangeNameMediator:OnCreate()
	__self = self

	NAME_LENGTH_MIN = ConfigRefer.ConstMain.PlayerNameLenMin and ConfigRefer.ConstMain:PlayerNameLenMin() or NAME_LENGTH_MIN
	NAME_LENGTH_MAX = ConfigRefer.ConstMain.PlayerNameLenMax and ConfigRefer.ConstMain:PlayerNameLenMax() or NAME_LENGTH_MAX
	SIGNATURE_LENGTH_MIN = ConfigRefer.ConstMain.PlayerNoticeLenMin and ConfigRefer.ConstMain:PlayerNoticeLenMin() or SIGNATURE_LENGTH_MIN
	SIGNATURE_LENGTH_MAX = ConfigRefer.ConstMain.PlayerNoticeLenMax and ConfigRefer.ConstMain:PlayerNoticeLenMax() or SIGNATURE_LENGTH_MAX
	CD_NAME_CHANGE = ConfigRefer.ConstMain.PlayerModifyNameCD and ConfigRefer.ConstMain:PlayerModifyNameCD() / 1000000000 or CD_NAME_CHANGE
	CD_SIGNATURE_CHANGE = ConfigRefer.ConstMain.PlayerModifyNoticeCD and ConfigRefer.ConstMain:PlayerModifyNoticeCD() / 1000000000 or CD_SIGNATURE_CHANGE

    self:InitObjects()
end

function UIPlayerChangeNameMediator:InitObjects()
	---@type CommonPopupBackComponent
	self.backComp = self:LuaObject("child_popup_base_s")
	self.hintLabel = self:Text("p_text_confirm_detail")

	self.inputNameNode = self:GameObject("p_input")
	self.inputName = InputFieldWithCheckStatus.new(self, "p_input")
	self.inputName:SetStatusTrans("p_status_a", "p_status_b", "p_status_c")
	self.inputName:SetAllowEmpty(true)
	self.inputNameInvalidButton = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnNameInvalidDetailButtonClick))

	self.inputSignatureNode = self:GameObject("p_input_say")
	self.inputSignature = InputFieldWithCheckStatus.new(self, "p_input_say")
	self.inputSignature:SetStatusTrans("p_status_a_say", "p_status_b_say", "p_status_c_say")
	self.inputSignature:SetAllowEmpty(true)
	self.inputSignatureInvalidButton = self:Button("p_btn_detail_abbr", Delegate.GetOrCreate(self, self.OnSloganInvalidDetailButtonClick))

	self.inputDefenceNode = self:GameObject("p_input_defence")
	self.inputDefence = InputFieldWithCheckStatus.new(self, "p_input_defence")
	self.inputDefence:SetStatusTrans("p_status_a_defence", "p_status_b_defence", "p_status_c_defence")
	self.inputDefence:SetAllowEmpty(true)
	self.inputDefenceInvalidButton = self:Button("p_btn_detail_defence", Delegate.GetOrCreate(self, self.OnDefenceInvalidDetailButtonClick))

	self.cancelButton = self:Button("p_btn_cancel", Delegate.GetOrCreate(self, self.OnCancelButtonClick))
	self.cancelButtonText = self:Text("p_btn_cancel_lb", "playerinfo_cancel")

	---@type BistateButton
	self.confirmButton = self:LuaObject("p_btn_confirm_a")
	--UIHelper.SetGray(self.confirmButton.gameObject, true)
	--self.confirmButtonText = self:Text("p_text", "playerinfo_modifyname_button")
	self.timeNode = self:GameObject("p_time")
	---@type CommonTimer
	self.timeController = self:LuaObject("child_time")
	self.resourceNode = self:GameObject("p_resource")
	---@type CommonPairsQuantity
	self.resourceController = self:LuaObject("child_common_quantity")
end


function UIPlayerChangeNameMediator:OnShow(param)
	if (param and param.changeName == false) then
		self.changeName = false
	end

	if (param and param.pvpDefenceWord) then
		self.pvpDefenceWord = true
		self.changeName = false
	end

	self.confirmButton:FeedData({
		buttonText = I18N.Get("playerinfo_modifyname_button"),
		onClick = Delegate.GetOrCreate(self, self.OnConfirmButtonClick),
	})
	self.confirmButton:SetEnabled(false)

	local player = ModuleRefer.PlayerModule:GetPlayer()
	if (self.changeName) then
		self.oldValue = player.Basics.Name
		self.backComp.textTitle.text = I18N.Get("playerinfo_modifyname_titile")
		self.hintLabel.text = I18N.Get("playerinfo_modifyname_titile")
	elseif (param and param.pvpDefenceWord) then
		self.oldValue = player.PlayerWrapper3.PlayerReplicaPvp.DefendAnnounce or string.empty
		self.backComp.textTitle.text = I18N.Get("se_pvp_fightmessage_name")
		self.hintLabel.text = I18N.Get("se_pvp_fightmessage_message")
	else
		self.oldValue = player.Basics.Notice
		self.backComp.textTitle.text = I18N.Get("playerinfo_modify")
		self.hintLabel.text = I18N.Get("playerinfo_modify")
	end

	self.inputName:SetCheckFunction(UIPlayerChangeNameMediator.CheckPlayerName)
	self.inputName:AddEvents()
	self.inputSignature:SetCheckFunction(UIPlayerChangeNameMediator.CheckPlayerSignature)
	self.inputSignature:AddEvents()
	self.inputDefence:SetCheckFunction(UIPlayerChangeNameMediator.CheckDefenceWord)
	self.inputDefence:AddEvents()

	self.inputName:InitContent(self.oldValue)
	self.inputName._input.characterLimit = NAME_LENGTH_MAX
	self.inputSignature:InitContent(self.oldValue)
	self.inputSignature._input.characterLimit = SIGNATURE_LENGTH_MAX
	self.inputDefence:InitContent(self.oldValue)
	self.inputDefence._input.characterLimit = DEFENCE_LENGTH_MAX

    self:RefreshUI()

	self:SetConfirmEnabled(false)
end

function UIPlayerChangeNameMediator:OnHide(param)
	self.inputName:RemoveEvents()
	self.inputName:SetCheckFunction(nil)
	self.inputSignature:RemoveEvents()
	self.inputSignature:SetCheckFunction(nil)
	self.inputDefence:RemoveEvents()
	self.inputDefence:SetCheckFunction(nil)
	if (self.onResourceItemChangeHandle) then
		self.onResourceItemChangeHandle()
		self.onResourceItemChangeHandle = nil
	end
end

function UIPlayerChangeNameMediator:OnOpened(param)
end

function UIPlayerChangeNameMediator:OnClose(param)
	self.inputName:Release()
	self.inputSignature:Release()
	self.inputDefence:Release()
	__self = nil
end

function UIPlayerChangeNameMediator:RefreshUI()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	local cdElapsed, cdTime, modifyTime
	---@type CS.UnityEngine.UI.InputField
	local input

	if (self.changeName) then
		input = self.inputName._input
		self.inputNameNode.gameObject:SetActive(true)
		self.inputSignatureNode.gameObject:SetActive(false)
		self.inputDefenceNode.gameObject:SetActive(false)
		modifyTime = player.Basics.ModifyNameTime.Seconds
		cdElapsed = g_Game.ServerTime:GetServerTimestampInSeconds() - modifyTime
		cdTime = CD_NAME_CHANGE
		self.resourceNode:SetActive(false)
		local itemGroup = ConfigRefer.ItemGroup:Find(ConfigRefer.ConstMain:PlayerModifyNameItemGroup())
		if (itemGroup and itemGroup:ItemGroupInfoListLength() > 0) then
			local infoList = itemGroup:ItemGroupInfoList(1)
			if (infoList and infoList:Items() > 0 and infoList:Nums() > 0) then
				local itemCfg = ConfigRefer.Item:Find(infoList:Items())
				if (itemCfg) then
					self.resourceNode:SetActive(true)
					local count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfg:Id())
					self.resourceController:FeedData({
						itemId = itemCfg:Id(),
						num1 = count,
						num2 = infoList:Nums(),
						compareType = require("CommonItemDetailsDefine").COMPARE_TYPE.LEFT_OWN_RIGHT_COST,
					})
					self.resourceItemId = itemCfg:Id()
					self.resourceItemNeed = infoList:Nums() - count
					if (not self.onResourceItemChangeHandle) then
						self.onResourceItemChangeHandle = ModuleRefer.InventoryModule:AddCountChangeListener(self.resourceItemId, Delegate.GetOrCreate(self, self.OnResourceItemChange))
					end
				end
			end
		end
	elseif self.pvpDefenceWord then
		input = self.inputDefence._input
		self.inputNameNode.gameObject:SetActive(false)
		self.inputSignatureNode.gameObject:SetActive(false)
		self.inputDefenceNode.gameObject:SetActive(true)
		self.resourceNode:SetActive(false)
		modifyTime = 0
		cdElapsed = 0
		cdTime = CD_DEFENCE_CHANGE
	else
		input = self.inputSignature._input
		self.inputNameNode.gameObject:SetActive(false)
		self.inputSignatureNode.gameObject:SetActive(true)
		self.inputDefenceNode.gameObject:SetActive(false)
		modifyTime = player.Basics.ModifyNoticeTime.Seconds
		cdElapsed = g_Game.ServerTime:GetServerTimestampInSeconds() - modifyTime
		cdTime = CD_SIGNATURE_CHANGE
	end

	if (cdElapsed < cdTime) then
		__inCd = true
		self:SetConfirmEnabled(false)
		input.interactable = false
		self.resourceNode:SetActive(false)
		self.timeNode:SetActive(true)
		self.timeController:FeedData({
			needTimer = true,
			endTime = modifyTime + CD_NAME_CHANGE,
			callBack = function()
				self:RefreshUI()
			end
		})
	else
		__inCd = false
		input.interactable = true
		self.timeNode:SetActive(false)
		self:SetConfirmEnabled(true, true)
	end
end

function UIPlayerChangeNameMediator:OnCancelButtonClick()
	self:CloseSelf()
end

function UIPlayerChangeNameMediator:OnConfirmButtonClick()
	if (__invalid) then return end

	-- 道具检查
	if (self.resourceItemId > 0 and self.resourceItemNeed > 0) then
		ModuleRefer.InventoryModule:OpenExchangePanel({{
			id = self.resourceItemId,
			num = self.resourceItemNeed,
		}})
		return
	end

	local msg
	if (self.changeName) then
		msg = require("ModifyPlayerNameParameter").new()
		msg.args.NewName = self.inputName._input.text
	elseif self.pvpDefenceWord then
		msg = require("ReplicaPvpSetDefendAnnounceParameter").new()
		msg.args.Announce = self.inputDefence._input.text
	else
		msg = require("ModifyPlayerNoticeParameter").new()
		msg.args.NewNotice = self.inputSignature._input.text
	end
	msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, success, resp)
		if (success) then
			self:CloseSelf()
		end
	end)
end

function UIPlayerChangeNameMediator:OnNameInvalidDetailButtonClick()
	self:CheckAndShowErrorTip(self.inputName, self.inputNameInvalidButton)
end

function UIPlayerChangeNameMediator:OnSloganInvalidDetailButtonClick()
	self:CheckAndShowErrorTip(self.inputSignature, self.inputSignatureInvalidButton)
end

function UIPlayerChangeNameMediator:OnDefenceInvalidDetailButtonClick()
	self:CheckAndShowErrorTip(self.inputDefence, self.inputDefenceInvalidButton)
end

---@param input InputFieldWithCheckStatus
---@param target CS.UnityEngine.UI.Button
function UIPlayerChangeNameMediator:CheckAndShowErrorTip(input, target)
    local lastErrorCode, lastError = input:GetLastError()
    if (not lastErrorCode or lastErrorCode == 0) then
        return
    end
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = target:GetComponent(typeof(CS.UnityEngine.RectTransform))
    tipParameter.text = I18N.Get(lastError)
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

---@param name string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function UIPlayerChangeNameMediator.CheckPlayerName(name, callback, err)
	if (not __self) then return end
    local parameter = require("ModifyPlayerNameParameter").new()
    parameter.args.NewName = name
	parameter.args.OnlyCheck = true
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
		if (not __self) then return end
		__self:SetConfirmEnabled(isSuccess)
        if (callback) then
            callback(name, isSuccess)
        end
    end, err)
end

---@param name string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function UIPlayerChangeNameMediator.CheckPlayerSignature(name, callback, err)
	if (not __self) then return end
    local parameter = require("ModifyPlayerNoticeParameter").new()
    parameter.args.NewNotice = name
	parameter.args.OnlyCheck = true
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
		if (not __self) then return end
		__self:SetConfirmEnabled(isSuccess)
        if callback then
            callback(name, isSuccess)
        end
    end, err)
end

---@param name string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function UIPlayerChangeNameMediator.CheckDefenceWord(name, callback, err)
	if (not __self) then return end
	local parameter = require("ReplicaPvpSetDefendAnnounceParameter").new()
	parameter.args.Announce = name
	parameter.args.OnlyCheck = true
	parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
		if (not __self) then return end
		__self:SetConfirmEnabled(isSuccess)
		if callback then
			callback(name, isSuccess)
		end
	end, err)
end

function UIPlayerChangeNameMediator:SetConfirmEnabled(enabled, checkSame)
	__invalid = not enabled or __inCd or (checkSame == true and self:GetCurrentText() == self.oldValue)
	--UIHelper.SetGray(self.confirmButton.gameObject, __invalid)
	self.confirmButton:SetEnabled(not __invalid)
end

function UIPlayerChangeNameMediator:GetCurrentText()
	if (self.changeName) then
		return self.inputName._input.text
	elseif self.pvpDefenceWord then
		return self.inputDefence._input.text
	else
		return self.inputSignature._input.text
	end
end

function UIPlayerChangeNameMediator:OnResourceItemChange()
	self:RefreshUI()
end

return UIPlayerChangeNameMediator
