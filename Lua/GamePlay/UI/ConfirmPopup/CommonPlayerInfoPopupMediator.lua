local BaseUIMediator = require("BaseUIMediator")
local I18N = require('I18N')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require('ModuleRefer')
local ClientDataKeys = require("ClientDataKeys")
local EventConst = require('EventConst')
local Utils = require("Utils")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

local CommonPlayerInfoPopupMediator = class("CommonPlayerInfoPopupMediator", BaseUIMediator)
function CommonPlayerInfoPopupMediator:OnCreate()
    self.anchor = self:GameObject("ui_common_content")
    self.Rect = self:RectTransform("ui_common_content")
    -- 头像
    --- @type PlayerInfoComponent
    self.child_ui_head_player = self:LuaObject('child_ui_head_player')

    self.p_text_name = self:Text("p_text_name")
    self.p_text_power = self:Text("p_text_power")
    self.p_text_league_name = self:Text("p_text_league_name")
    self.p_text_chat = self:Text('p_text_chat', 'chat')
    self.p_text_view = self:Text('p_text_view', 'alliance_invite_button2')
    self.p_text_invite = self:Text('p_text_invite', 'alliance_invite_button3')
    self.p_text_apply = self:Text('p_text_apply', 'alliance_invite_button4')

    self.p_btn_chat = self:Button('p_btn_chat', Delegate.GetOrCreate(self, self.OnClickChat))
    self.p_btn_view = self:Button('p_btn_view', Delegate.GetOrCreate(self, self.OnClickView))
    self.p_btn_invite = self:Button('p_btn_invite', Delegate.GetOrCreate(self, self.OnClickInvite))
    self.p_btn_apply = self:Button('p_btn_apply', Delegate.GetOrCreate(self, self.OnClickJoin))
end

function CommonPlayerInfoPopupMediator:OnOpened(playerInfo)
    self.playerInfo = playerInfo
    self.isManager = playerInfo.isManager
    self.child_ui_head_player:FeedData(playerInfo.PortraitInfo)
    self.p_text_name.text = playerInfo.PlayerName
    self.p_text_power.text = playerInfo.PlayerPower
    self.p_text_league_name.text = I18N.GetWithParams("alliance_invite_button7", playerInfo.AllianceAbbr, playerInfo.AllianceName)

    self.hasAlliance = playerInfo.AllianceName ~= ''
    self.p_text_league_name:SetVisible(self.hasAlliance)

    -- 是否有权限邀请
    self.isR4Above = ModuleRefer.AllianceModule:IsAllianceR4Above()
    -- 调整位置
    self:SetPos(playerInfo.anchorObj)

    if self.isManager then
        self.p_text_invite.text = I18N.Get("assign")
        self.p_text_apply.text = I18N.Get("pet_tip_btn_sent")
    else
        self.p_text_invite.text = I18N.Get("alliance_invite_button3")
        self.p_text_apply.text = I18N.Get("alliance_invite_button4")
    end
end

function CommonPlayerInfoPopupMediator:SetPos(anchorObj)
    if (Utils.IsNull(anchorObj)) then
        return
    end

    -- 定位到目标
    local camera = g_Game.UIManager:GetUICamera()
    ---@type CS.UnityEngine.RectTransform
    local rt = anchorObj.transform
    local center = rt:GetScreenCenter(camera)

    -- 判断弹出位置
    local isUp = center.y >= CS.UnityEngine.Screen.height / 2
    local isLeft = center.x <= CS.UnityEngine.Screen.width / 2
    local offset_v = isUp and -self.Rect.rect.height / 2 or self.Rect.rect.height / 2
    local offset_h = isLeft and self.Rect.rect.width / 2 or -self.Rect.rect.width / 2

    local finalPos = camera:ScreenToWorldPoint(center)
    self.Rect.transform.position = finalPos
    self.Rect.transform.localPosition = self.Rect.transform.localPosition + CS.UnityEngine.Vector3(0, offset_v, 0) + CS.UnityEngine.Vector3(offset_h, 0, 0)
end

-- 私聊
function CommonPlayerInfoPopupMediator:OnClickChat()
    ---@type UIChatMediatorOpenContext
    local openContext = {}
    openContext.openMethod = 1
    openContext.privateChatUid = self.playerInfo.PlayerId
    openContext.extInfo = {p = self.playerInfo.PortraitInfo.Portrait, n = self.playerInfo.PlayerName}

    local mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIChatMediator)
    if mediator and mediator:IsShow() then
        mediator:OnOpened(openContext)
        -- mediator:OnShow(openContext)
    else
        g_Game.UIManager:Open(UIMediatorNames.UIChatMediator, openContext)
    end
    self:CloseSelf()
end

-- 查看联盟
function CommonPlayerInfoPopupMediator:OnClickView()
    if not self.hasAlliance then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips2"))
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceInfoPopupMediator, {allianceId = self.playerInfo.AllianceId, tab = 1})
end

-- 申请入盟
function CommonPlayerInfoPopupMediator:OnClickJoin()
    -- 踢人
    if self.isManager then
        self:onClickBtnKick()
        return
    end

    if not self.hasAlliance then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips2"))
        return
    end
    local myAlliance = ModuleRefer.AllianceModule:GetMyAllianceData()
    if myAlliance then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips3"))
        return
    end

    g_Game.UIManager:Open(UIMediatorNames.AllianceJoinMediator, {targetAllianceName = self.playerInfo.AllianceName})
end

-- 邀请加盟
function CommonPlayerInfoPopupMediator:OnClickInvite()
    if not self.isR4Above then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips6"))
        return
    end

    -- 任命职级
    if self.isManager then
        self:OnClickBtnAppoint()
        return
    end

    if self.hasAlliance then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_target_54"))
        return
    end

    local canAdd = ModuleRefer.AllianceModule:AddInviteTimer(self.playerInfo.PlayerId)
    if not canAdd then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips6"))
        return
    end

    local session = ModuleRefer.ChatModule:GetPrivateSessionByUid(self.playerInfo.PlayerId)
    if not session then
        ---@type UIChatMediatorOpenContext
        local openContext = {}
        openContext.openMethod = 1
        openContext.extInfo = {p = self.playerInfo.PortraitInfo.Portrait, n = self.playerInfo.PlayerName}
        -- g_Game.UIManager:Open(UIMediatorNames.UIChatMediator, openContext)

        local nickname = ModuleRefer.ChatModule:GetNicknameFromExtInfo(openContext.extInfo, self.playerInfo.PlayerId)
        local userInfo = CS.FunPlusChat.Models.UserInfo()
        userInfo.Avatar = string.format("{p:%s, fp:%s, ca:%s}", openContext.extInfo.p, openContext.extInfo.fp, openContext.extInfo.ca)
        userInfo.Nickname = nickname
        userInfo.Uid = self.playerInfo.PlayerId
        CS.ChatSdkWrapper.CreateP2P(userInfo, function(newSession)
            ModuleRefer.ChatModule:SetNextGotoSessionId(newSession.SessionId)
            self:Invite(newSession)
        end)
    else
        self:Invite(session)
    end
    self:CloseSelf()
end

function CommonPlayerInfoPopupMediator:Invite(session)
    ---@type AllianceRecruitMsgParam
    local data = {}
    data.allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    data.content = I18N.Get("alliance_invite_button8")
    ModuleRefer.ChatModule:SendAllianceRecruitMsg(session.SessionId, data)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_button9"))
end

function CommonPlayerInfoPopupMediator:OnClickBtnAppoint()
    local memebers = ModuleRefer.AllianceModule:GetMyAllianceMemberComp().Members
    local data
    for k, v in pairs(memebers) do
        if v.PlayerID == self.playerInfo.PlayerId then
            data = v
            break
        end
    end
    if data then
        ---@type wds.AllianceMember
        g_Game.UIManager:Open(UIMediatorNames.AllianceAppointmentMediator, data)
    else
        ModuleRefer.ToastModule:AddSimpleToast("#Can't find the player")
    end
end

function CommonPlayerInfoPopupMediator:onClickBtnKick()
    local memebers = ModuleRefer.AllianceModule:GetMyAllianceMemberComp().Members
    local data
    for k, v in pairs(memebers) do
        if v.PlayerID == self.playerInfo.PlayerId then
            data = v
            break
        end
    end
    if data then
        local runtimeId = self:GetRuntimeId()
        local fbId = data.FacebookID
        local lockTrans = self.p_btn_apply.transform
        ---@type CommonConfirmPopupMediatorParameter
        local confirmParameter = {}
        confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.WarningAndCancel
        confirmParameter.content = I18N.GetWithParams("alliance_tirenqueren", self.playerInfo.PlayerName)
        confirmParameter.onConfirm = function()
            g_Game.UIManager:Close(runtimeId)
            ModuleRefer.AllianceModule:KickAllianceMember(lockTrans, fbId)
            return true
        end
        confirmParameter.confirmLabel = I18N.Get("confirm")
        confirmParameter.cancelLabel = I18N.Get("cancle")
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
    else
        ModuleRefer.ToastModule:AddSimpleToast("#Can't find the player")
        return
    end
end

return CommonPlayerInfoPopupMediator
