local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require("ModuleRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local I18N = require("I18N")
local ClientDataKeys = require("ClientDataKeys")
local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")
---@class ChatQuickReplyRecruitCell : BaseTableViewProCell
local ChatQuickReplyRecruitCell = class("ChatQuickReplyRecruitCell", BaseTableViewProCell)

function ChatQuickReplyRecruitCell:ctor()
    self.info = nil
    self.cdTimerStart = false
    self.cdEndTime = 0
end

function ChatQuickReplyRecruitCell:OnCreate()
    self.textTitle = self:Text("p_title_league_recruit", "alliance_recruit_Shout_chat_title")
    self.textLanguage = self:Text("p_text_league_language")
    self.textMember = self:Text("p_text_league_member")
    self.textContent = self:Text("p_text_league_welcome")
    self.btn = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtn))
    self.goBaseCD = self:GameObject("p_base_colddown")
    self.textCD = self:Text("p_text_colddwon_recruit")
end

function ChatQuickReplyRecruitCell:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.CoolDownTick))
end

function ChatQuickReplyRecruitCell:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.CoolDownTick))
end

function ChatQuickReplyRecruitCell:OnFeedData()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    self.info = allianceData.AllianceBasicInfo
    self.textLanguage.text = I18N.Get("alliance_recruit_Shout_chat_title2") .. ": " .. AllianceModuleDefine.GetConfigLangaugeStr(self.info.Language)
    self.textMember.text = I18N.Get("alliance_recruit_Shout_chat_title3") .. ": " .. self.info.MemberCountCur
    self.textContent.text = ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.AllianceRecruitMsg)
    local cd = (ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.AllianceRecruitMsgCD) or 0) - g_Game.ServerTime:GetServerTimestampInSeconds()
    self:SetCoolDown(cd, false)
end

function ChatQuickReplyRecruitCell:OnClickBtn()
    if self.cdTimerStart then return end
    local sessionId = ModuleRefer.ChatModule:GetWorldSession().SessionId
    ---@type AllianceRecruitMsgParam
    local data = {}
    data.allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    data.content = self.textContent.text
    ModuleRefer.ChatModule:SendAllianceRecruitMsg(sessionId, data)
    self:SetCoolDown(180, true)
end

---@param sec number
---@param serverSave boolean
function ChatQuickReplyRecruitCell:SetCoolDown(sec, serverSave)
    if sec <= 0 then
        self.cdTimerStart = false
        self.cdEndTime = 0
        self.goBaseCD:SetActive(false)
        self.textCD.gameObject:SetActive(false)
        self.textCD.text = ""
        ModuleRefer.ClientDataModule:RemoveData(ClientDataKeys.GameData.AllianceRecruitMsgCD)
    else
        self.cdTimerStart = true
        self.goBaseCD:SetActive(true)
        self.textCD.gameObject:SetActive(true)
        self.textCD.text = I18N.GetWithParams("alliance_summon_fighting1", TimeFormatter.SimpleFormatTimeWithoutHour(sec))
        self.cdEndTime = g_Game.ServerTime:GetServerTimestampInSeconds() + sec
        if serverSave then
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.AllianceRecruitMsgCD, self.cdEndTime)
        end
    end
end

function ChatQuickReplyRecruitCell:CoolDownTick()
    if not self.cdTimerStart then return end
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    if curTimeSec >= self.cdEndTime then
        self:SetCoolDown(0, true)
    else
        self:SetCoolDown(self.cdEndTime - curTimeSec, false)
    end
end
return ChatQuickReplyRecruitCell