local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local CityAttrType = require("CityAttrType")
local TimeFormatter = require("TimeFormatter")
local ReplyToAllianceInvitationParameter = require("ReplyToAllianceInvitationParameter")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceJoinSelectedDetailComponent:BaseUIComponent
---@field new fun():AllianceJoinSelectedDetailComponent
---@field super BaseUIComponent
local AllianceJoinSelectedDetailComponent = class('AllianceJoinSelectedDetailComponent', BaseUIComponent)

function AllianceJoinSelectedDetailComponent:ctor()
    BaseUIComponent.ctor(self)
    self._allianceId = nil
    self._allianceName = nil
    self._needApply = nil
    self._allianceLeaderId = nil
    self._allianceLeaderPortrait = 0
    self._allianceLeaderName = string.Empty
    self._eventAdd = false
    self._tickJoinCdTime = nil
    ---@type wrpc.AllianceBasicInfo
    self._allianceBasicInfo = nil
    self._translateStatus = 0
    self._originDeclaimContent = nil
    self._translatedDeclaimContent = nil
    self._inTranslateDeclaimContent = nil
end

function AllianceJoinSelectedDetailComponent:OnCreate(param)
    self._selfGo = self:GameObject("")
    self._p_text_leader = self:Text("p_text_leader", "league_leader")
    self._p_text_player_name = self:Text("p_text_player_name")
    self._p_btn_chat = self:Button("p_btn_chat", Delegate.GetOrCreate(self, self.OnClickChatBtn))
    self._p_detail = self:GameObject("p_detail")
    self._p_text_detail = self:Text("p_text_detail")
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")

    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")

    self._p_frame_head = self:Image("p_frame_head")

    self._p_wait_data_ani = self:Transform("p_wait_data_ani")

    self._p_btn_group_translate = self:Button("p_btn_group_translate", Delegate.GetOrCreate(self, self.OnClickTranslate))
    self._p_group_translating = self:GameObject("p_group_translating")
    self._p_btn_group_revert = self:Button("p_btn_group_revert", Delegate.GetOrCreate(self, self.OnClickRevertTranlate))
end

---@param data wrpc.AllianceBriefInfo
function AllianceJoinSelectedDetailComponent:OnFeedData(data)
    if data then
        self._allianceId = data.ID
        self._allianceName = data.Name
        self._needApply = data.JoinSetting
        self._allianceLeaderId = nil
        self._allianceLeaderPortrait = 0
        self._allianceLeaderName = string.Empty
        self._selfGo:SetVisible(true)
        local cachedInfo = ModuleRefer.AllianceModule:RequestAllianceBriefInfo(self._allianceId)
        self:UpdateUI(cachedInfo)
    else
        self._needApply = nil
        self._allianceId = nil
        self._allianceLeaderId = nil
        self._allianceLeaderPortrait = 0
        self._allianceLeaderName = string.Empty
        self._selfGo:SetVisible(false)
    end
end

function AllianceJoinSelectedDetailComponent:AddEvents(param)
    self:SetupEvents(true)
end

function AllianceJoinSelectedDetailComponent:RemoveEvents(param)
    self:SetupEvents(false)
end

function AllianceJoinSelectedDetailComponent:OnClickChatBtn()
    if self._allianceLeaderId then
        g_Logger.Log("click chat with leader:%s", self._allianceLeaderId)
        ---@type UIChatMediatorOpenContext
        local openContext = {}
        openContext.openMethod = 1
        openContext.privateChatUid = self._allianceLeaderId
        openContext.extInfo = {
            p = self._allianceLeaderPortrait,
            n = self._allianceLeaderName,
        }
        g_Game.UIManager:Open(UIMediatorNames.UIChatMediator, openContext)
    else
        g_Logger.Error("click chat with leader nil!")
    end
end

function AllianceJoinSelectedDetailComponent:OnClickJoinOrApply()
    if not self._allianceId then
        return
    end
    local needApply = self._needApply
    local allianceName = self._allianceName

    --被邀请入盟
    if self.isInvited then
        ModuleRefer.AllianceModule:AcceptRecruitAlliance(self._child_comp_btn_b:Transform("") ,self._allianceId, function(cmd, isSuccess, rsp)
            -- if isSuccess then
            --     ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("apply_toast", allianceName))
            -- end
        end)
        return
    end

    ModuleRefer.AllianceModule:JoinOrApplyAlliance(self._child_comp_btn_b:Transform("") ,self._allianceId, function(cmd, isSuccess, rsp)
        if needApply == AllianceModuleDefine.JoinNeedApply then
            if isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("apply_toast", allianceName))
            end
        end
    end)
end

---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceJoinSelectedDetailComponent:UpdateUI(allianceBasicInfo)
    self._allianceBasicInfo = allianceBasicInfo
    self._tickJoinCdTime = nil
    if allianceBasicInfo then
        self._allianceLeaderId = allianceBasicInfo.LeaderID
        if allianceBasicInfo.Notice ~= self._originDeclaimContent then
            self._translateStatus = 0
            self._inTranslateDeclaimContent = nil
        end
        self._originDeclaimContent = allianceBasicInfo.Notice
        self._p_wait_data_ani:DOKill(false)
        self._p_wait_data_ani:SetVisible(false)

        self._p_text_leader:SetVisible(true)
        self._p_text_player_name:SetVisible(true)
        self._p_btn_chat:SetVisible(true)
        self._p_detail:SetVisible(true)
        self._child_comp_btn_b:SetVisible(true)
        self._child_ui_head_player:SetVisible(true)

        self._p_text_player_name.text = allianceBasicInfo.LeaderName

        self._allianceLeaderId = allianceBasicInfo.LeaderID
        -- self._p_text_detail.text = allianceBasicInfo.Notice
        self:UpdateAllianceDeclaim()

        self:RefreshJoinButton(allianceBasicInfo)
        self:OnSecTick()

        local membersInfoCache = ModuleRefer.AllianceModule:RequestAllianceMembersInfo(self._allianceId)
        if membersInfoCache then
            if not membersInfoCache.leader or membersInfoCache.leader.PlayerID ~= self._allianceLeaderId then
                self._allianceLeaderId = nil
                ModuleRefer.AllianceModule:RequestAllianceMembersInfo(self._allianceId, true)
            else
                self:UpdateLeader(membersInfoCache.leader)
            end
        end
    else
        self._originDeclaimContent = nil
        self._translateStatus = 0
        self._inTranslateDeclaimContent = nil
        self:UpdateAllianceDeclaim()
        self._allianceLeaderId = nil
        self._p_text_leader:SetVisible(false)
        self._p_text_player_name:SetVisible(false)
        self._p_btn_chat:SetVisible(false)
        self._p_detail:SetVisible(false)
        self._child_comp_btn_b:SetVisible(false)
        self._child_ui_head_player:SetVisible(false)

        self._p_wait_data_ani:DOKill(false)
        self._p_wait_data_ani:SetVisible(true)
        self._p_wait_data_ani:DOLocalRotate(CS.UnityEngine.Vector3(0,0, 360), 0.5):SetLoops(-1)
    end
end

function AllianceJoinSelectedDetailComponent:RefreshJoinButton(allianceBasicInfo)
    local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
    local isApplied = false
    if playerAlliance and playerAlliance.AppliedAllianceIDs then
        if playerAlliance.AppliedAllianceIDs[allianceBasicInfo.ID] then
            isApplied = true
        end
    end
    if isApplied then
        self._child_comp_btn_b:SetButtonText(I18N.Get("applied"))
        self._child_comp_btn_b:SetEnabled(false)
    else
        if allianceBasicInfo.JoinSetting == AllianceModuleDefine.JoinNeedApply then
            self._child_comp_btn_b:SetButtonText(I18N.Get("apply"))
        else
            self._child_comp_btn_b:SetButtonText(I18N.Get("join"))
        end

        local playerData = ModuleRefer.PlayerModule:GetPlayer()
        local lastLeaveTime = playerData and playerData.PlayerAlliance and playerData.PlayerAlliance.LastJoinAllianceTime and playerData.PlayerAlliance.LastJoinAllianceTime.Seconds or 0
        local inJoinCd = false
        if lastLeaveTime > 0 then
            local tickCdTime = lastLeaveTime + ModuleRefer.AllianceModule:GetJoinAllianceCD()
            if tickCdTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
                self._tickJoinCdTime = tickCdTime
                inJoinCd = true
            end
        end
        self._child_comp_btn_b:SetEnabled(not inJoinCd)
    end
end

---@param leaderInfo wrpc.AllianceMemberInfo
function AllianceJoinSelectedDetailComponent:UpdateLeader(leaderInfo)
    self._allianceLeaderId = leaderInfo.PlayerID
    self._allianceLeaderPortrait = leaderInfo.Portrait or 0
    self._allianceLeaderName = leaderInfo.Name or string.Empty
    self._child_ui_head_player:FeedData(leaderInfo)
end

---@param allianceId number
---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceJoinSelectedDetailComponent:OnAllianceBasicInfoUpdate(allianceId, allianceBasicInfo)
    if allianceId ~= self._allianceId then
        return
    end
    self:UpdateUI(allianceBasicInfo)
end

---@param allianceId number
---@param allianceMembersInfoCache AllianceMembersInfoCache
function AllianceJoinSelectedDetailComponent:OnAllianceMembersInfoUpdate(allianceId, allianceMembersInfoCache)
    if allianceId ~= self._allianceId then
        return
    end
    self:UpdateLeader(allianceMembersInfoCache.leader)
end

function AllianceJoinSelectedDetailComponent:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        ---@type BistateButtonParameter
        local btnData = {}
        btnData.onClick = Delegate.GetOrCreate(self, self.OnClickJoinOrApply)

        self._child_comp_btn_b:FeedData(btnData)
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceMembersInfoUpdate))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceMembersInfoUpdate))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
    end
end

function AllianceJoinSelectedDetailComponent:OnSecTick()
    if not self._tickJoinCdTime then
        return
    end
    local leftTime = self._tickJoinCdTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    if leftTime >= 0 then
        self._child_comp_btn_b:SetButtonText(TimeFormatter.SimpleFormatTime(leftTime))
        return
    end
    self._tickJoinCdTime = nil
    self:RefreshJoinButton(self._allianceBasicInfo)
end

function AllianceJoinSelectedDetailComponent:OnClickTranslate()
    if self._translateStatus ~= 0 then
        return
    end
    if self._originDeclaimContent == self._inTranslateDeclaimContent and self._translatedDeclaimContent then
        self._translateStatus = 2
        self:UpdateAllianceDeclaim()
        return
    end
    self._translateStatus = 1
    self:UpdateAllianceDeclaim()
    self._inTranslateDeclaimContent = self._originDeclaimContent
    local chatSdk = CS.FunPlusChat.FPChatSdk
    chatSdk.Translate(self._inTranslateDeclaimContent, CS.FunPlusChat.FunLang.unknown, ModuleRefer.ChatSDKModule:GetUserLanguage(), function(result)
        if self._inTranslateDeclaimContent ~= self._originDeclaimContent then
            return
        end
        self._translatedDeclaimContent = result and result.data and result.data.targetText
        self._translateStatus = 2
        self:UpdateAllianceDeclaim()
    end, "Livedata")
end

function AllianceJoinSelectedDetailComponent:OnClickRevertTranlate()
    if self._translateStatus ~= 2 then
        return
    end
    self._translateStatus = 0
    self:UpdateAllianceDeclaim()
end

function AllianceJoinSelectedDetailComponent:UpdateAllianceDeclaim()
    self._p_btn_group_translate:SetVisible(self._translateStatus == 0)
    self._p_group_translating:SetVisible(self._translateStatus == 1)
    self._p_btn_group_revert:SetVisible(self._translateStatus == 2)
    if self._translateStatus == 2 then
        self._p_text_detail.text = self._translatedDeclaimContent
    else
        self._p_text_detail.text = self._originDeclaimContent
    end
end

--是否接受邀请
function AllianceJoinSelectedDetailComponent:SetIsInvited(isInvited)
    self.isInvited = isInvited
end

return AllianceJoinSelectedDetailComponent