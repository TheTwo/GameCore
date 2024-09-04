local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")
local AllianceModuleDefine = require('AllianceModuleDefine')

local AllianceRecommendMediator = class('AllianceRecommendMediator', BaseUIMediator)
function AllianceRecommendMediator:ctor()
end

function AllianceRecommendMediator:OnCreate()
    ---@type CommonPopupBackSmallComponent
    self.child_popup_base_s = self:LuaObject('child_popup_base_s')
    --- @type CommonAllianceLogoComponent
    self.child_league_logo = self:LuaObject('child_league_logo')

    self.p_text_hint = self:Text("p_text_hint", 'alliance_invite_tips1')
    self.p_text_name_league = self:Text("p_text_name_league")
    self.p_text_language = self:Text("p_text_language")
    self.p_text_league_leader = self:Text('p_text_league_leader')
    self.p_text_league_member = self:Text('p_text_league_member')
    self.p_text_chat = self:Text('p_text_chat', 'alliance_invite_button1')
    self.p_text_chat = self:Text('p_text_quit', 'alliance_invite_button5')

    self.p_btn_chat = self:Button('p_btn_chat', Delegate.GetOrCreate(self, self.OnClickChat))
    self.p_btn_quit = self:Button('p_btn_quit', Delegate.GetOrCreate(self, self.OnClickQuit))
end

function AllianceRecommendMediator:OnShow(allianceId)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))

    local baseData = {}
    baseData.title = I18N.Get("alliance_invite_button6")
    self.child_popup_base_s:FeedData(baseData)

    self._allianceInfo = ModuleRefer.AllianceModule:RequestAllianceBriefInfo(allianceId)
    self:UpdateDetailUI(self._allianceInfo)
end

function AllianceRecommendMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))

end

function AllianceRecommendMediator:OnAllianceBasicInfoUpdate(allianceId, allianceBasicInfo)
    self._allianceInfo = allianceBasicInfo
    self:UpdateDetailUI(allianceBasicInfo)
end

---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceRecommendMediator:UpdateDetailUI(allianceBasicInfo)
    if not allianceBasicInfo then
        return
    end
    local abbr = string.IsNullOrEmpty(allianceBasicInfo.Abbr) and '' or string.format("[%s]", allianceBasicInfo.Abbr)
    self.p_text_name_league.text = abbr .. allianceBasicInfo.Name
    self.p_text_league_leader.text = I18N.Get("leaderboard_ElementName_3") .. ": " .. allianceBasicInfo.LeaderName
    self.p_text_league_member.text = I18N.Get("league_hud_member") .. ": " .. ("%s/%s"):format(allianceBasicInfo.MemberCount, allianceBasicInfo.MemberMax)
    self.p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(allianceBasicInfo.Language)
    self.child_league_logo:FeedData(allianceBasicInfo.Flag)
end

-- 私聊
function AllianceRecommendMediator:OnClickChat()
    local selfId = ModuleRefer.PlayerModule:GetPlayer().ID
    if self._allianceInfo.LeaderID == selfId then
        return
    end
    ---@type UIChatMediatorOpenContext
    local openContext = {}
    openContext.openMethod = 1
    openContext.privateChatUid = self._allianceInfo.LeaderID
    openContext.extInfo = {p = 0, n = self._allianceInfo.LeaderName}
    g_Game.UIManager:Open(UIMediatorNames.UIChatMediator, openContext)
    self:CloseSelf()
end

function AllianceRecommendMediator:OnClickQuit()
    local msg = require("AllianceClearInactiveRecommendParameter").new()
    msg:SendOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then
            ModuleRefer.AllianceModule:OnRecommendAllianceChanged()
            self:CloseSelf()
        else
            return
        end
    end)
end

return AllianceRecommendMediator
