--- scene:scene_league_popup_appointment_position

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local TimerUtility = require("TimerUtility")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceAppointmentPositionMediator:BaseUIMediator
---@field new fun():AllianceAppointmentPositionMediator
---@field super BaseUIMediator
local AllianceAppointmentPositionMediator = class('AllianceAppointmentPositionMediator', BaseUIMediator)

function AllianceAppointmentPositionMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type number
    self._playerFacebookId = nil
end

function AllianceAppointmentPositionMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_m = self:LuaObject("child_popup_base_m")
    self._p_table = self:TableViewPro("p_table")
end

---@param player wds.AllianceMember
function AllianceAppointmentPositionMediator:OnOpened(player)
    self._playerFacebookId = player.FacebookID
    self._playerHasTitle = player.Title > 0
    self._p_table:Clear()

    if self:OnAllianceRankChanged() then
        return
    end
    
    local onClick = Delegate.GetOrCreate(self, self.OnClickAssignOrReplace)
    local titleMemberMap = ModuleRefer.AllianceModule:QueryTitlesMember()
    local targetPlayerTile = ModuleRefer.AllianceModule:MemberHasTitle(player.FacebookID)
    for _, v in ConfigRefer.AllianceTitle:ipairs() do
        ---@type AllianceAppointmentPositionTileCellData
       local cellData = {}
        cellData.player = titleMemberMap[v:Id()]
        cellData.targetPlayer = player
        cellData.title = v
        cellData.onclick = onClick
        cellData.targetPlayerHasTitle = targetPlayerTile 
        self._p_table:AppendData(cellData)
    end
end

---@param cellData AllianceAppointmentPositionTileCellData
function AllianceAppointmentPositionMediator:OnClickAssignOrReplace(cellData)
    local title
    if cellData.player and cellData.player.FacebookID == self._playerFacebookId then
        title = 0
    else
        title = cellData.title:Id()
        --if cellData.player or self._playerHasTitle then
        --    ---@type CommonConfirmPopupMediatorParameter
        --    local popupParameter = {}
        --    popupParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        --    popupParameter.content = I18N.Get("official_cancel_appoint")
        --    popupParameter.confirmLabel = I18N.Get("confirm")
        --    popupParameter.cancelLabel = I18N.Get("cancle")
        --    popupParameter.onConfirm = function()
        --        self:SetAllianceTitle(title)
        --        return true
        --    end
        --    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, popupParameter)
        --    return
        --end
    end
    self:SetAllianceTitle(title, cellData)
end

---@param title number
---@param cellData AllianceAppointmentPositionTileCellData
function AllianceAppointmentPositionMediator:SetAllianceTitle(title, cellData)
    ModuleRefer.AllianceModule:SetAllianceTitle(self._playerFacebookId, title, function(cmd, isSuccess, rsp)
        if isSuccess then
            if title == 0 then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_member_dismissal"))
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_member_appoint", I18N.Get(cellData.title:KeyId())))
            end
            self:CloseSelf()
        end
    end)
end

function AllianceAppointmentPositionMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_RANK_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRankChanged))
end

function AllianceAppointmentPositionMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_RANK_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRankChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
end

function AllianceAppointmentPositionMediator:OnAllianceRankChanged(_, _)
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SetMemberTitle) then
        TimerUtility.DelayExecuteInFrame(function()
            self:CloseSelf()
        end)
        return true
    end
    return false
end

return AllianceAppointmentPositionMediator