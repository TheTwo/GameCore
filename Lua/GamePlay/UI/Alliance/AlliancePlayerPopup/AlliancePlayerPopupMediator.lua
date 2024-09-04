--- scene:scene_league_popup_player

local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require("DBEntityPath")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AlliancePlayerPopupMediatorData
---@field playerData wds.AllianceMember
---@field allowAllianceOperation boolean

---@class AlliancePlayerPopupMediator:BaseUIMediator
---@field new fun():AlliancePlayerPopupMediator
---@field super BaseUIMediator
local AlliancePlayerPopupMediator = class('AlliancePlayerPopupMediator', BaseUIMediator)

function AlliancePlayerPopupMediator:ctor()
    BaseUIMediator.ctor(self)
    self._allowAllianceOperation = false
end

function AlliancePlayerPopupMediator:OnCreate(param)
    self._p_text_name = self:Text("p_text_name")
    self._p_text_state = self:Text("p_text_state")
    self._p_text_power = self:Text("p_text_power")
    self._p_btn_chat = self:Button("p_btn_chat", Delegate.GetOrCreate(self, self.OnClickBtnChat))
    self._p_text_chat = self:Text("p_text_chat", "chat")
    self._p_btn_friend = self:Button("p_btn_friend", Delegate.GetOrCreate(self, self.OnClickBtnFriend))
    self._p_text_friend = self:Text("p_text_friend", "add_friend")
    self._p_btn_appoint = self:Button("p_btn_appoint", Delegate.GetOrCreate(self, self.OnClickBtnAppoint))
    self._p_text_appoint = self:Text("p_text_appoint", "official_appoint")
    self._p_btn_rank = self:Button("p_btn_rank", Delegate.GetOrCreate(self, self.OnClickBtnRank))
    self._p_text_rank = self:Text("p_text_rank", "position_appoint")
    self._p_btn_kick = self:Button("p_btn_kick", Delegate.GetOrCreate(self, self.onClickBtnKick))
    self._p_text_kick = self:Text("p_text_kick", "alliance_tiren")
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
end

---@param param AlliancePlayerPopupMediatorData
function AlliancePlayerPopupMediator:OnOpened(param)
    self._allowAllianceOperation = param.allowAllianceOperation
    ---@type wds.AllianceMember
    self._player = param.playerData
    self._playerId = param.playerData.PlayerID
    self._playerFacebookId = param.playerData.FacebookID
    self._isSelf = self._playerId == ModuleRefer.PlayerModule.playerId
    self:RefreshUI()
end

function AlliancePlayerPopupMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerDataChanged))
end

function AlliancePlayerPopupMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerDataChanged))
end

function AlliancePlayerPopupMediator:RefreshUI()
    local selfRank = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank
    local inAlliance = ModuleRefer.AllianceModule:IsInAlliance()
    self._canChat = true
    self._canAddFriend = false
    self._canAppoint = false--self._allowAllianceOperation and inAlliance and self._player.Rank == AllianceModuleDefine.OfficerRank and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SetMemberTitle)
    self._canChangeRank = self._allowAllianceOperation and inAlliance and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SetMemberRank) and selfRank > self._player.Rank
    self._canKick = self._allowAllianceOperation and inAlliance and self._player.Rank < selfRank and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.KickMember)
    self._p_btn_chat:SetVisible(not self._isSelf and self._canChat)
    self._p_btn_friend:SetVisible(not self._isSelf and self._canAddFriend)
    self._p_btn_appoint:SetVisible(not self._isSelf and self._canAppoint)
    self._p_btn_rank:SetVisible(not self._isSelf and self._canChangeRank)
    self._p_btn_kick:SetVisible(not self._isSelf and self._canKick)

    self._p_text_name.text = self._player.Name
    self._p_text_power.text = tostring(math.floor(self._player.Power + 0.5))
    self._p_text_state.text = TimeFormatter.AlliancePlayerLastOnlineTime(self._player)
    self._child_ui_head_player:FeedData(self._player.PortraitInfo)
end

function AlliancePlayerPopupMediator:OnClickBtnPlayerHead()
    g_Logger.Log("OnClickBtnPlayerHead %s", self._playerId)
end

function AlliancePlayerPopupMediator:OnClickBtnChat()
    g_Logger.Log("OnClickBtnChat %s", self._playerId)
    ---@type UIChatMediatorOpenContext
    local openContext = {}
    openContext.openMethod = 1
    openContext.privateChatUid = self._playerId
    openContext.extInfo = {
        p = self._player.PortraitInfo.PlayerPortrait,
        fp = self._player.PortraitInfo.PortraitFrameId,
        ca = self._player.PortraitInfo.CustomAvatar or string.Empty,
        n = self._player.Name
    }
    g_Game.UIManager:Open(UIMediatorNames.UIChatMediator, openContext)
end

function AlliancePlayerPopupMediator:OnClickBtnFriend()
    g_Logger.Log("OnClickBtnFriend %s", self._playerId)
end

function AlliancePlayerPopupMediator:OnClickBtnAppoint()
    if not self._allowAllianceOperation then
        return
    end
    g_Logger.Log("OnClickBtnAppoint %s fb:%s", self._playerId, self._playerFacebookId)
    g_Game.UIManager:Open(UIMediatorNames.AllianceAppointmentPositionMediator, self._player)
end

function AlliancePlayerPopupMediator:OnClickBtnRank()
    if not self._allowAllianceOperation then
        return
    end
    g_Logger.Log("OnClickBtnRank %s fb:%s", self._playerId, self._playerFacebookId)
    g_Game.UIManager:Open(UIMediatorNames.AllianceAppointmentMediator, self._player)
end

function AlliancePlayerPopupMediator:onClickBtnKick()
    if not self._allowAllianceOperation then
        return
    end
    g_Logger.Log("onClickBtnKick %s fb:%s", self._playerId, self._playerFacebookId)
    local runtimeId = self:GetRuntimeId()
    local fbId = self._playerFacebookId
    local lockTrans = self._p_btn_kick.transform
    ---@type CommonConfirmPopupMediatorParameter
    local confirmParameter = {}
    confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.WarningAndCancel
    confirmParameter.content = I18N.GetWithParams("alliance_tirenqueren", self._player.Name)
    confirmParameter.onConfirm = function() 
        g_Game.UIManager:Close(runtimeId)
        ModuleRefer.AllianceModule:KickAllianceMember(lockTrans, fbId)
        return true
    end
    confirmParameter.confirmLabel = I18N.Get("confirm")
    confirmParameter.cancelLabel = I18N.Get("cancle")
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
end

---@param entity wds.Alliance
---@param changedData table
function AlliancePlayerPopupMediator:OnPlayerDataChanged(entity, changedData)
    if not self._player or not entity then
        return
    end
    if changedData[self._player.FacebookID] then
        local player = entity.AllianceMembers.Members[self._player.FacebookID]
        if player then
            self._player = player
            self:RefreshUI()
        else
            self:CloseSelf()
        end
    end
end

return AlliancePlayerPopupMediator