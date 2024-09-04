local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceNoticePopupCellData
---@field Id number
---@field info wds.AllianceInform
---@field canShowDelete boolean
---@field translateStatus number
---@field translated boolean
---@field tTitle string
---@field tContext string

---@class AllianceNoticePopupCell:BaseTableViewProCell
---@field new fun():AllianceNoticePopupCell
---@field super BaseTableViewProCell
local AllianceNoticePopupCell = class('AllianceNoticePopupCell', BaseTableViewProCell)

function AllianceNoticePopupCell:OnCreate(param)
    self._p_text_title = self:Text("p_text_title")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_date = self:Text("p_text_date")
    
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_btn_deleted = self:Button("p_btn_deleted", Delegate.GetOrCreate(self, self.OnClickDelete))
    self._p_btn_group_translate = self:Button("p_btn_group_translate", Delegate.GetOrCreate(self, self.OnClickTranslate))
    self._p_group_translating = self:GameObject("p_group_translating")
    self._p_btn_group_revert = self:Button("p_btn_group_revert", Delegate.GetOrCreate(self, self.OnClickRevertTranslate))
end

---@param data AllianceNoticePopupCellData
function AllianceNoticePopupCell:OnFeedData(data)
    self._data = data
    self._p_btn_deleted:SetVisible(data.canShowDelete)
    local info = data.info
    self:UpdateTitleContext()
    self._p_text_name.text = info.SourceName
    self._p_text_date.text = TimeFormatter.TimeToDateTimeStringUseFormat(info.Time.ServerSecond, "yyyy.MM.dd")
    local notificationModule = ModuleRefer.NotificationModule
    notificationModule:RemoveFromGameObject(self._child_reddot_default.go, false)
    local node = notificationModule:GetDynamicNode(AllianceModuleDefine.GetNotifyKeyForNotice(data.Id), NotificationType.ALLIANCE_NOTICE_NEW)
    if node then
        notificationModule:AttachToGameObject(node, self._child_reddot_default.go, self._child_reddot_default.redNew,  self._child_reddot_default.redNewText, AllianceModuleDefine.NotifyCountAsNew)
    end
    self:UpdateTranslateBtn()
end

function AllianceNoticePopupCell:UpdateTitleContext()
    local data = self._data
    local info = data.info
    self._p_text_title.text = data.translateStatus == 2 and data.tTitle or info.Title
    self._p_text_detail.text = data.translateStatus == 2 and data.tContext or info.Content
end

function AllianceNoticePopupCell:UpdateTranslateBtn()
    local data = self._data
    self._p_btn_group_translate:SetVisible(not data.translateStatus or data.translateStatus == 0)
    self._p_group_translating:SetVisible(data.translateStatus == 1)
    self._p_btn_group_revert:SetVisible(data.translateStatus == 2)
end

function AllianceNoticePopupCell:OnRecycle(param)
    local notificationModule = ModuleRefer.NotificationModule
    notificationModule:RemoveFromGameObject(self._child_reddot_default.go, false)
end

function AllianceNoticePopupCell:OnClickDelete()
    if not self._data then
        return
    end
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    parameter.content = I18N.Get("alliance_notice_delete")
    parameter.confirmLabel = I18N.Get("confirm")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.context = self._data.Id
    parameter.onConfirm = function(context)
        ModuleRefer.AllianceModule:SendRemoveAllianceInfo(context, self._p_btn_deleted.transform)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

function AllianceNoticePopupCell:OnClickTranslate()
    if self._data.translated then
        self._data.translateStatus = 2
        self:UpdateTitleContext()
        self:UpdateTranslateBtn()
        return
    end
    if not self._data.translateStatus or self._data.translateStatus == 0 then
        ---@type AllianceNoticePopupMediator
        local mediator = self:GetParentBaseUIMediator()
        if not mediator then return end
        self._data.translateStatus = 1
        mediator:TranslateCell(self._data)
        self:UpdateTranslateBtn()
    end
end

function AllianceNoticePopupCell:OnClickRevertTranslate()
    self._data.translateStatus = 0
    self:UpdateTitleContext()
    self:UpdateTranslateBtn()
    return
end

return AllianceNoticePopupCell