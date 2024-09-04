local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimeFormatter = require('TimeFormatter')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')

---@class UIPlayerPortraitSelectMediator : BaseUIMediator
local UIPlayerPortraitSelectMediator = class('UIPlayerPortraitSelectMediator', BaseUIMediator)

local I18N_CONFIRM = "skincollection_avatar_change"
local I18N_IN_USE = "skincollection_avatar_change"
local I18N_UPLOAD = "skincollection_avatar_upload_btn"
local UPLOAD_CELL_ID = 999

function UIPlayerPortraitSelectMediator:ctor()
	self.selectedId = 0
	self.inUseId = 0
	self.tableData = {}
end

function UIPlayerPortraitSelectMediator:OnCreate()
    self:InitObjects()
end

function UIPlayerPortraitSelectMediator:InitObjects()
	---@type CommonPopupBackComponent
	self.backComp = self:LuaObject("child_popup_base_s")
	self.titleLabel = self:Text("p_text_title", "playerinfo_chooseprofile")
	self.table = self:TableViewPro("p_table_icon")
	self.goUploadBtn = self:GameObject("p_btn_uploading")
	self.luagoUpLoadButton = self:LuaObject("p_btn_uploading")
	self.luagoTime = self:LuaObject("child_time")
	self.goCDTime = self:GameObject("child_time")
	---@type BistateButton
	self.confirmButton = self:LuaObject("p_comp_btn_confirm")
end

function UIPlayerPortraitSelectMediator:OnShow(param)
	self.confirmButton:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnConfirmButtonClick),
		buttonText = I18N.Get(I18N_CONFIRM),
	})
	self.luagoUpLoadButton:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnUpLoadButtonClick),
		buttonText = I18N.Get(I18N_UPLOAD),
	})
    self:RefreshUI()
end

function UIPlayerPortraitSelectMediator:OnHide(param)

end

function UIPlayerPortraitSelectMediator:OnOpened(param)
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.PortraitInfo.MsgPath, Delegate.GetOrCreate(self, self.RefreshUI))
end

function UIPlayerPortraitSelectMediator:OnClose(param)
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.PortraitInfo.MsgPath, Delegate.GetOrCreate(self, self.RefreshUI))
end

function UIPlayerPortraitSelectMediator:RefreshUI()
	self.confirmButton:SetEnabled(false)

	self.isInUploadCD = false
	self.inUseId = ModuleRefer.PlayerModule:GetSelfPortraitId()
	self.selectedId = self.inUseId
	
	---@type wds.PlayerBasicInfo
	local playerBaseInfo = ModuleRefer.PlayerModule:GetPlayer().Basics
	local upLoadType = playerBaseInfo.CustomAvatarStatus
	g_Logger.Error("========upLoadType=========:"..upLoadType)
	self.goUploadBtn:SetActive(self.inUseId == UPLOAD_CELL_ID)
	self:CheckUploadBtnStatus(upLoadType)
	local curCustomAvatar = playerBaseInfo.ReviewingAvatar
	g_Logger.Error("========curCustomAvatar=========:"..curCustomAvatar)


	self.tableData = {}
	self.table:Clear()
	---@type UIPlayerPortraitTableCellParam
	local uploadData = {
		id = UPLOAD_CELL_ID,
		selected = (UPLOAD_CELL_ID == self.selectedId),
		inUse = (UPLOAD_CELL_ID == self.inUseId),
		status = upLoadType,
		customAvatar = curCustomAvatar,
		onClick = Delegate.GetOrCreate(self, self.OnUpLoadClick),
	}
	self.tableData[UPLOAD_CELL_ID] = uploadData
	self.table:AppendData(uploadData)
	for id, _ in ConfigRefer.PlayerIcon:ipairs() do
		---@type UIPlayerPortraitTableCellParam
		local data = {
			id = id,
			selected = (id == self.selectedId),
			inUse = (id == self.inUseId),
			onClick = Delegate.GetOrCreate(self, self.OnItemClick),
		}
		self.tableData[id] = data
		self.table:AppendData(data)
	end
	self:OnItemClick(self.selectedId)
end

function UIPlayerPortraitSelectMediator:OnUpLoadButtonClick()
	---@type CommonConfirmPopupMediatorParameter
        local dialogParam = {}
        local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("skincollection_avatar_upload_title")
		local uploadCD = ConfigRefer.ConstMain:AvatarUploadCD()
		local cdStr = nil
		if uploadCD < 60 then
			cdStr = string.format("%dmin", uploadCD)
		else
			cdStr = string.format("%0.1fh", uploadCD / 60)
		end
        dialogParam.content = I18N.GetWithParams("skincollection_avatar_upload_desc", cdStr)
		dialogParam.confirmLabel = I18N.Get("skincollection_avatar_upload_local_btn")
		dialogParam.cancelLabel = I18N.Get("skincollection_avatar_upload_takephoto_btn")
        dialogParam.onCancel = function()
            self:OnUpLoadAvatar(1)
            return true
        end
        dialogParam.onClose = function()
            return true
        end
        dialogParam.onConfirm = function()
            self:OnUpLoadAvatar(0)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

function UIPlayerPortraitSelectMediator:OnUpLoadAvatar(type)
	if self.isInUploadCD then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_avatar_upload_cd_toast"))
		self.luagoUpLoadButton:SetEnabled(false)
		return
	end
	if UNITY_EDITOR then
		ModuleRefer.ToastModule:AddSimpleToast("[*o*]上传头像 -- 需要真机 SDK 环境")
		return
	end
	local sendCmd = require("CheckUploadAvatarCDParameter").new()
    sendCmd:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, rsp)
		if isSuccess then
			ModuleRefer.FPXSDKModule:ChooseUploadCustomHeadIcon(type)
		else
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_avatar_upload_cd_toast"))
			self.luagoUpLoadButton:SetEnabled(false)
		end
	end)
end

function UIPlayerPortraitSelectMediator:OnConfirmButtonClick()
	local msg = require("ModifyPlayerIconParameter").new()
	msg.args.IconId = self.selectedId
	msg.args.UseCustomAvatar = (self.selectedId == UPLOAD_CELL_ID)
	msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, success, resp)
		if (success) then
			self:CloseSelf()
		end
	end)
end

function UIPlayerPortraitSelectMediator:OnItemClick(newId)
	local oldData = self.tableData[self.selectedId]
	local newData = self.tableData[newId]
	self.selectedId = newId
	if (oldData) then
		oldData.selected = false
	end
	if (newData) then
		newData.selected = true
	end
	self.table:RefreshAllShownItem()
	if (self.selectedId == self.inUseId) then
		self.confirmButton:SetButtonText(I18N.Get(I18N_IN_USE))
		self.confirmButton:SetEnabled(false)
	else
		self.confirmButton:SetButtonText(I18N.Get(I18N_CONFIRM))
		self.confirmButton:SetEnabled(true)
	end
	self.goUploadBtn:SetActive(newId == UPLOAD_CELL_ID)
	if newId ~= UPLOAD_CELL_ID then
		self.goCDTime:SetActive(false)
	end
end

function UIPlayerPortraitSelectMediator:OnUpLoadClick(type)
	g_Logger.Error("========OnUpLoadClick===type==:"..type)
	if type == wds.enum.AvatarStatus.AvatarStatusReviewing then
		--审核中
		self:OnItemClick(UPLOAD_CELL_ID)
		self.luagoUpLoadButton:SetEnabled(false)
		self.confirmButton:SetEnabled(false)

	elseif type == wds.enum.AvatarStatus.AvatarStatusPass then
		--冷却中/可上传
		self:OnItemClick(UPLOAD_CELL_ID)
		self:CheckUploadCD()
	else
		if self:CheckUploadCD() then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_avatar_upload_cd_toast"))
			return
		end
		local playerBaseInfo = ModuleRefer.PlayerModule:GetPlayer().Basics
		local curCustomAvatar = playerBaseInfo.ReviewingAvatar
		if not string.IsNullOrEmpty(curCustomAvatar) then
			self:OnItemClick(UPLOAD_CELL_ID)
			self.luagoUpLoadButton:SetEnabled(true)
			return
		end
		--待上传
		self.goUploadBtn:SetActive(false)
		self:OnUpLoadButtonClick()
	end
end


function UIPlayerPortraitSelectMediator:CheckUploadCD()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	local nextUploadTime = player.PlayerWrapper3.Appearance.NextUpdateAvatarTime.timeSeconds
	local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
	--冷却中
	if curTime < nextUploadTime then
		self.goCDTime:SetActive(true)
		self.luagoUpLoadButton:SetEnabled(false)
		-- local remainTime = nextUploadTime - curTime
		---@type CommonTimerData
		local timerData = {}
		timerData.endTime = nextUploadTime
		timerData.needTimer = true
		timerData.callBack = function()
			self.luagoUpLoadButton:SetEnabled(true)
			self.goCDTime:SetActive(false)
			self.isInUploadCD = false
		end
		self.luagoTime:FeedData(timerData)
		return true
	else
		self.goCDTime:SetActive(false)
		self.luagoUpLoadButton:SetEnabled(true)
		return false
	end
end

function UIPlayerPortraitSelectMediator:CheckUploadBtnStatus(upLoadType)
	if upLoadType == wds.enum.AvatarStatus.AvatarStatusReviewing then
		--审核中
		self.goCDTime:SetActive(false)
		self.luagoUpLoadButton:SetEnabled(false)
		self.confirmButton:SetEnabled(false)
	elseif upLoadType == wds.enum.AvatarStatus.AvatarStatusPass then
		--冷却中/可上传
		self.isInUploadCD = self:CheckUploadCD()
		self.confirmButton:SetEnabled(true)
	elseif upLoadType == wds.enum.AvatarStatus.AvatarStatusReject then
		--审核失败
		self.goCDTime:SetActive(false)
		self.luagoUpLoadButton:SetEnabled(true)
		self.confirmButton:SetEnabled(true)
	else
		--待上传
		self.luagoUpLoadButton:SetEnabled(true)
		self.confirmButton:SetEnabled(true)
	end
end

return UIPlayerPortraitSelectMediator
