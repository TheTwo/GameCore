local BaseUIComponent = require("BaseUIComponent")
local AllianceModuleDefine = require("AllianceModuleDefine")
local Delegate = require("Delegate")
local I18N = require("I18N")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
---@class ChatAllianceRecruitItem : BaseUIComponent
local ChatAllianceRecruitItem = class("ChatAllianceRecruitItem", BaseUIComponent)

---@class ChatAllianceRecruitItemParam
---@field allianceId number
---@field text string

function ChatAllianceRecruitItem:ctor()
    self.allianceId = 0
    ---@type wrpc.AllianceBriefInfo
    self.allianceInfo = nil
end

function ChatAllianceRecruitItem:OnCreate()
    self.textTitle = self:Text("p_title_league_recruit_l") or self:Text("p_title_league_recruit_r")
    ---@type CommonAllianceLogoComponent
    self.luaLogo = self:LuaObject("child_league_logo")
    self.textName = self:Text("p_text_league_name_l") or self:Text("p_text_league_name_r")
    self.textLanguage = self:Text("p_text_league_language_l") or self:Text("p_text_league_language_r")
    self.textMember = self:Text("p_text_league_member_l") or self:Text("p_text_league_member_r")
    self.textWelcome = self:Text("p_text_league_welcome_l") or self:Text("p_text_league_welcome_r")
    self.btnGoto = self:Button("child_comp_btn_share_league_recruit_l", Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    or self:Button("child_comp_btn_share_world_event_l", Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
end

function ChatAllianceRecruitItem:OnShow()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoCacheUpdate))
end

function ChatAllianceRecruitItem:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoCacheUpdate))
end

---@param param ChatAllianceRecruitItemParam
function ChatAllianceRecruitItem:OnFeedData(param)
    self.allianceId = param.allianceId
    self.textTitle.text = I18N.Get("alliance_recruit_Shout_chat_title")
    self.textWelcome.text = param.text
    self.allianceInfo = ModuleRefer.AllianceModule:RequestAllianceBriefInfo(self.allianceId)
    if self.allianceInfo then
        self:UpdateContent()
    end
end

function ChatAllianceRecruitItem:UpdateContent()
    self.textName.text = string.format("[%s]%s", self.allianceInfo.Abbr, self.allianceInfo.Name)
    self.textLanguage.text = I18N.Get("alliance_create_language") .. ": " .. AllianceModuleDefine.GetConfigLangaugeStr(self.allianceInfo.Language)
    self.textMember.text = I18N.Get("alliance_recruit_Shout_chat_title3") .. ": " .. self.allianceInfo.MemberCount
    self.luaLogo:FeedData(self.allianceInfo.Flag)
end

function ChatAllianceRecruitItem:OnBtnGotoClicked()
    local allianceSysId = NewFunctionUnlockIdDefine.Global_alliance
    if not self.allianceInfo then return end
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(allianceSysId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_click_totle_desc2"))
        return
    end
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        ---@type AllianceJoinMediatorData
        local data = {}
        data.targetAllianceName = self.allianceInfo.Name
        g_Game.UIManager:Open(UIMediatorNames.AllianceJoinMediator, data)
    elseif ModuleRefer.AllianceModule:GetMyAllianceData().ID == self.allianceId then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_recruit_Shout_clickTips"))
    else
        ---@type AllianceManageMediatorParameter
        local data = {}
        data.entryTab = 3
        data.entryTabParam = {
            targetAllianceName = self.allianceInfo.Name
        }
        g_Game.UIManager:Open(UIMediatorNames.AllianceManageMediator, data)
    end
end

---@param id number
---@param info wrpc.AllianceBriefInfo
function ChatAllianceRecruitItem:OnAllianceBasicInfoCacheUpdate(id, info)
    if id ~= self.allianceId then
        return
    end
    self.allianceInfo = info
    self:UpdateContent()
end

return ChatAllianceRecruitItem