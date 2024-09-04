local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageGroupListInfoPanel:BaseUIComponent
---@field new fun():AllianceManageGroupListInfoPanel
---@field super BaseUIComponent
local AllianceManageGroupListInfoPanel = class('AllianceManageGroupListInfoPanel', BaseUIComponent)

function AllianceManageGroupListInfoPanel:ctor()
    BaseUIComponent.ctor(self)
    self._allianceId = nil
    self._allianceName = nil
    self._allianceLeaderId = nil
    self._allianceLeaderPortrait = 0
    self._allianceLeaderName = string.Empty
    self._delayHide = nil
    self._translateStatus = 0
    self._originDeclaimContent = nil
    self._translatedDeclaimContent = nil
    self._inTranslateDeclaimContent = nil
end

function AllianceManageGroupListInfoPanel:OnCreate(param)
    self._selfGo = self:GameObject("")
    self._p_text_leader = self:Text('p_text_leader')
    self._p_text_player_name = self:Text('p_text_player_name')
    self._p_btn_chat = self:Button('p_btn_chat', Delegate.GetOrCreate(self, self.OnBtnChatClicked))
    self._p_text_detail_content = self:Text('p_text_detail_content')
    self._child_btn_detail = self:Button('child_btn_detail', Delegate.GetOrCreate(self, self.OnBtnChildDetailClicked))
    self._p_text_detail = self:Text('p_text_detail', "alliance_setting_member_details")
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_wait_loading = self:GameObject("p_wait_loading")
    self._p_text_language = self:Text("p_text_language")
    --optional
    self._p_text_power = self:Text("p_text_power")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_text_area = self:Text("p_text_area")
    if Utils.IsNotNull(self._p_text_area) then
        self._p_text_area:SetVisible(false)
    end
    self._p_icon_area = self:GameObject("p_icon_area")
    self._self_ani = self:AnimTrigger("")
    if Utils.IsNotNull(self._p_icon_area) then
        self._p_icon_area:SetVisible(false)
    end
    self._p_btn_group_translate = self:Button("p_btn_group_translate", Delegate.GetOrCreate(self, self.OnClickTranslate))
    self._p_group_translating = self:GameObject("p_group_translating")
    self._p_btn_group_revert = self:Button("p_btn_group_revert", Delegate.GetOrCreate(self, self.OnClickRevertTranlate))
end

function AllianceManageGroupListInfoPanel:AddEvents()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceMembersInfoUpdate))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function AllianceManageGroupListInfoPanel:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceMembersInfoUpdate))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@param data wrpc.AllianceBriefInfo
function AllianceManageGroupListInfoPanel:OnFeedData(data)
    self._delayHide = nil
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
        if Utils.IsNotNull(self._self_ani) then
            self._self_ani:FinishAll(CS.FpAnimation.CommonTriggerType.Custom2)
            self._self_ani:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
            self._self_ani:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    else
        self._allianceId = nil
        self._allianceLeaderId = nil
        self._allianceLeaderPortrait = 0
        self._allianceLeaderName = string.Empty
        if Utils.IsNotNull(self._self_ani) then
            self._selfGo:SetVisible(true)
            self._delayHide = self._self_ani:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
            self._self_ani:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
            self._self_ani:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
            self._self_ani:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        else
            self._selfGo:SetVisible(false)
        end
    end
end

function AllianceManageGroupListInfoPanel:OnBtnChatClicked()
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

function AllianceManageGroupListInfoPanel:OnBtnChildDetailClicked()
    if not self._allianceId then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceInfoPopupMediator, {allianceId = self._allianceId, tab = 2})
end

---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceManageGroupListInfoPanel:UpdateUI(allianceBasicInfo)
    if allianceBasicInfo then
        if allianceBasicInfo.Notice ~= self._originDeclaimContent then
            self._translateStatus = 0
            self._inTranslateDeclaimContent = nil
        end
        self._originDeclaimContent = allianceBasicInfo.Notice
        self._p_text_leader:SetVisible(true)
        self._p_text_player_name:SetVisible(true)
        self._p_btn_chat:SetVisible(true)
        self._child_ui_head_player:SetVisible(true)
        self._p_text_player_name.text = allianceBasicInfo.LeaderName
        self._allianceLeaderId = allianceBasicInfo.LeaderID
        -- self._p_text_detail_content.text = allianceBasicInfo.Notice
        self:UpdateAllianceDeclaim()
        local langId = allianceBasicInfo.Language
        self._p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(langId)
        local membersInfoCache = ModuleRefer.AllianceModule:RequestAllianceMembersInfo(self._allianceId)
        if membersInfoCache then
            if not membersInfoCache.leader or membersInfoCache.leader.PlayerID ~= self._allianceLeaderId then
                self._allianceLeaderId = nil
                self._p_wait_loading:SetVisible(true)
                ModuleRefer.AllianceModule:RequestAllianceMembersInfo(self._allianceId, true)
            else
                self._p_wait_loading:SetVisible(false)
                self:UpdateLeader(membersInfoCache.leader)
            end
        end
        if Utils.IsNotNull(self._p_text_power) then
            self._p_text_power.text = I18N.GetWithParams("alliance_main_label2" , tostring(math.floor(allianceBasicInfo.Power + 0.5)))
        end
        if Utils.IsNotNull(self._p_text_quantity) then
            self._p_text_quantity.text = I18N.GetWithParams("alliance_main_label3", tostring(allianceBasicInfo.MemberCount), tostring(allianceBasicInfo.MemberMax))
        end
        --if Utils.IsNotNull(self._p_text_area) then
        --    self._p_text_area.text = I18N.GetWithParams("alliance_main_label4", "?")
        --end
    else
        self._originDeclaimContent = nil
        self._translateStatus = 0
        self._inTranslateDeclaimContent = nil
        self:UpdateAllianceDeclaim()
        self._allianceLeaderId = nil
        self._p_text_leader:SetVisible(false)
        self._p_text_player_name:SetVisible(false)
        self._p_btn_chat:SetVisible(false)
    end
end

---@param leaderInfo wrpc.AllianceMemberInfo
function AllianceManageGroupListInfoPanel:UpdateLeader(leaderInfo)
    self._p_wait_loading:SetVisible(false)
    self._allianceLeaderId = leaderInfo.PlayerID
    self._allianceLeaderPortrait = leaderInfo.Portrait or 0
    self._allianceLeaderName = leaderInfo.Name or string.Empty
    leaderInfo.PlayerId = leaderInfo.PlayerID
    self._child_ui_head_player:FeedData(leaderInfo)
end

---@param allianceId number
---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceManageGroupListInfoPanel:OnAllianceBasicInfoUpdate(allianceId, allianceBasicInfo)
    if allianceId ~= self._allianceId then
        return
    end
    self:UpdateUI(allianceBasicInfo)
end

---@param allianceId number
---@param allianceMembersInfoCache AllianceMembersInfoCache
function AllianceManageGroupListInfoPanel:OnAllianceMembersInfoUpdate(allianceId, allianceMembersInfoCache)
    if allianceId ~= self._allianceId then
        return
    end
    self:UpdateLeader(allianceMembersInfoCache.leader)
end

function AllianceManageGroupListInfoPanel:Tick(dt)
    if not self._delayHide then
        return
    end
    self._delayHide = self._delayHide - dt
    if self._delayHide <= 0 then
        self._delayHide = nil
        self._selfGo:SetVisible(false)
    end
end

function AllianceManageGroupListInfoPanel:OnClickTranslate()
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

function AllianceManageGroupListInfoPanel:OnClickRevertTranlate()
    if self._translateStatus ~= 2 then
        return
    end
    self._translateStatus = 0
    self:UpdateAllianceDeclaim()
end

function AllianceManageGroupListInfoPanel:UpdateAllianceDeclaim()
    self._p_btn_group_translate:SetVisible(self._translateStatus == 0)
    self._p_group_translating:SetVisible(self._translateStatus == 1)
    self._p_btn_group_revert:SetVisible(self._translateStatus == 2)
    if self._translateStatus == 2 then
        self._p_text_detail_content.text = self._translatedDeclaimContent
    else
        self._p_text_detail_content.text = self._originDeclaimContent
    end
end

return AllianceManageGroupListInfoPanel