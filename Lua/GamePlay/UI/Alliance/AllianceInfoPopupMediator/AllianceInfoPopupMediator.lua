--- scene:scene_league_popup_info

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local BaseUIMediator = require("BaseUIMediator")
local AllianceMemberListRankCellData = require("AllianceMemberListRankCellData")

---@class AllianceInfoPopupMediator:BaseUIMediator
---@field new fun():AllianceInfoPopupMediator
---@field super BaseUIMediator
local AllianceInfoPopupMediator = class('AllianceInfoPopupMediator', BaseUIMediator)

function AllianceInfoPopupMediator:ctor()
    BaseUIMediator.ctor(self)
    self._mode = nil
    ---@type number
    self._allianceId = nil
    ---@type number
    self._allianceLeaderId = nil
    ---@type wrpc.AllianceBriefInfo
    self._allianceInfo = nil
    ---@type wrpc.AllianceMemberInfo
    self._allianceMemberInfo = nil
end

function AllianceInfoPopupMediator:OnCreate(param)
    ---@type CommonResourceBtn
    self._child_btn_capsule = self:LuaObject("child_btn_capsule")
    
    self._p_group_detail = self:GameObject("p_group_detail")
    
    self._p_group_member = self:GameObject("p_group_member")
    
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetailTab))
    self._p_base_select_detail = self:GameObject("p_base_select_detail")
    self._p_base_nomal_detail = self:GameObject("p_base_nomal_detail")
    self._p_text_detail = self:Text("p_text_detail", I18N.Temp().text_alliance_info)
    
    self._p_btn_member = self:Button("p_btn_member", Delegate.GetOrCreate(self, self.OnClickMemberTab))
    self._p_base_select_member = self:GameObject('p_base_select_member')
    self._p_base_nomal_member = self:GameObject('p_base_nomal_member')
    self._p_text_member = self:Text("p_text_member", I18N.Temp().text_alliance_info_member)

    ---detail page
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_abbr = self:Text("p_text_abbr")
    self._p_text_name = self:Text('p_text_name')
    self._p_text_player_name = self:Text("p_text_player_name")
    self._p_text_power = self:Text("p_text_power")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_text_area = self:Text("p_text_area")
    self._p_text_declaim = self:Text("p_text_declaim")
    self._p_text_language = self:Text("p_text_language")
    
    ---member page
    self._p_table_member = self:TableViewPro("p_table_member")
    self._p_text_active = self:Text("p_text_active", "daily_info_activation")
    self._p_text_active_level = self:Text("p_text_active_level")
    self._p_icon_active_level = self:Image("p_icon_active_level")
    self._p_btn_active_level = self:Button("p_btn_active_level", Delegate.GetOrCreate(self, self.OnClickAllianceActive))

    self.p_text_apply = self:Text("p_text_apply","join_league")
    self.p_btn_chat_leader = self:Button("p_btn_chat_leader", Delegate.GetOrCreate(self, self.OnClickChatBtn))
    self.p_btn_apply = self:Button("p_btn_apply", Delegate.GetOrCreate(self, self.OnClickApplyBtn))
end

function AllianceInfoPopupMediator:OnShow(param)
    self:AddEVents()

    local IsInAlliance = ModuleRefer.AllianceModule:IsInAlliance()
    self.p_btn_apply:SetVisible(not IsInAlliance)
end

function AllianceInfoPopupMediator:OnHide(param)
    self:RemoveEvents()
end

function AllianceInfoPopupMediator:OnClickDetailTab()
    if self._mode == 1 then
        return
    end
    self._mode = 1
    self._p_group_detail:SetVisible(true)
    self._p_group_member:SetVisible(false)
    self:UpdateSelectedTab()
    if self._allianceInfo then
        return
    end
    self._allianceInfo = ModuleRefer.AllianceModule:RequestAllianceBriefInfo(self._allianceId)
    self:UpdateDetailUI(self._allianceInfo)
end

function AllianceInfoPopupMediator:OnClickMemberTab()
    if self._mode == 2 then
        return
    end
    self._mode = 2
    self._p_group_detail:SetVisible(false)
    self._p_group_member:SetVisible(true)
    self:UpdateSelectedTab()
    if self._allianceMemberInfo then
        return
    end
    self._allianceMemberInfo = ModuleRefer.AllianceModule:RequestAllianceMembersInfo(self._allianceId)
    self:UpdateMemberUI(self._allianceMemberInfo)
end

function AllianceInfoPopupMediator:UpdateSelectedTab()
    self._p_base_select_detail:SetVisible(self._mode == 1)
    self._p_base_nomal_detail:SetVisible(self._mode ~= 1)
    self._p_base_select_member:SetVisible(self._mode == 2)
    self._p_base_nomal_member:SetVisible(self._mode ~= 2)
end

function AllianceInfoPopupMediator:OnClickChatBtn()
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

function AllianceInfoPopupMediator:OnClickApplyBtn()
    ModuleRefer.AllianceModule:JoinOrApplyAlliance(self.p_btn_apply.gameObject.transform ,self._allianceId, function(cmd, isSuccess, rsp)
    if self.allianceBasicInfo.JoinSetting == AllianceModuleDefine.JoinNeedApply then
            if isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("apply_toast", self.allianceBasicInfo.Name))
            end
        end
    end)
    self:CloseSelf()
end

---@param allianceId number @allianceId
function AllianceInfoPopupMediator:OnOpened(param)
    self._allianceId = param.allianceId
    self._mode = nil
    if param.tab and param.tab == 2 then
        self:OnClickMemberTab()
    else
        self:OnClickDetailTab()
    end
end

---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceInfoPopupMediator:UpdateDetailUI(allianceBasicInfo)
    if not allianceBasicInfo then
        return
    end
    self.allianceBasicInfo = allianceBasicInfo
    self._allianceLeaderId = allianceBasicInfo.LeaderID
    self._p_text_abbr.text = string.IsNullOrEmpty(allianceBasicInfo.Abbr) and '' or string.format("[%s]", allianceBasicInfo.Abbr)
    self._p_text_name.text = allianceBasicInfo.Name
    self._p_text_player_name.text = allianceBasicInfo.LeaderName
    self._p_text_power.text = tostring(math.floor(allianceBasicInfo.Power + 0.5))
    self._p_text_quantity.text = ("%s/%s"):format(allianceBasicInfo.MemberCount, allianceBasicInfo.MemberMax)
    self._p_text_area.text = tostring(allianceBasicInfo.OccupyTerritoryNum)
    self._p_text_declaim.text = allianceBasicInfo.Notice
    self._p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(allianceBasicInfo.Language)
    self._child_league_logo:FeedData(allianceBasicInfo.Flag)
    self:UpdateAllianceActive()
end

---@param allianceMembersInfoCache AllianceMembersInfoCache
function AllianceInfoPopupMediator:UpdateMemberUI(allianceMembersInfoCache)
    if not allianceMembersInfoCache then
        return
    end
    self._p_table_member:Clear()
    local allMembers = allianceMembersInfoCache.members
    if table.isNilOrZeroNums(allMembers) then
        return
    end
    ---@type table<number, wds.AllianceMember[]>
    local rankMap = {}
    local ranks = {}
    for _, v in pairs(allMembers) do
        if not rankMap[v.Rank] then
            rankMap[v.Rank] = {}
        end
        table.insert(rankMap[v.Rank], v)
        table.insert(ranks, v.Rank)
    end
    ranks = table.unique(ranks, true)
    table.sort(ranks)
    local sortMembers = function(a, b)
        if a.LatestLogoutTime and b.LatestLogoutTime then
            if a.LatestLogoutTime.ServerSecond < b.LatestLogoutTime.ServerSecond then
                return true
            end
        elseif a.LatestLogoutTime then
            return false
        elseif b.LatestLogoutTime then
            return true
        end
        return a.Power < b.Power
    end
    repeat
        local rank = table.remove(ranks)
        local rankMembers = rankMap[rank]
        table.sort(rankMembers, sortMembers)
        ---@type AllianceMemberListRankCellData
        local rankCellData = AllianceMemberListRankCellData.new()
        rankCellData.Rank = rank
        rankCellData.count = #rankMembers
        rankCellData.max = ModuleRefer.AllianceModule:GetRankNumberLimit(rank)
        rankCellData:SetExpanded(true)
        table.addrange(rankCellData.__childCellsData, rankMembers)
        self._p_table_member:AppendData(rankCellData, 0, 0)
        for i = #rankMembers, 1, -1 do
            self._p_table_member:AppendData(rankMembers[i], 1, 0)
        end
        if #ranks > 0 then
            self._p_table_member:AppendData({}, 2, 0)
        end
    until #ranks <= 0
end

function AllianceInfoPopupMediator:AddEVents()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceMembersInfoUpdate))
end

function AllianceInfoPopupMediator:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceMembersInfoUpdate))
end

---@param allianceId number
---@param allianceBasicInfo wrpc.AllianceBasicInfo
function AllianceInfoPopupMediator:OnAllianceBasicInfoUpdate(allianceId, allianceBasicInfo)
    if allianceId ~= self._allianceId then
        return
    end
    if self._mode ~= 1 then
        return
    end
    self._allianceInfo = allianceBasicInfo
    self:UpdateDetailUI(allianceBasicInfo)
end

---@param allianceId number
---@param allianceMembersInfoCache AllianceMembersInfoCache
function AllianceInfoPopupMediator:OnAllianceMembersInfoUpdate(allianceId, allianceMembersInfoCache)
    if allianceId ~= self._allianceId then
        return
    end
    if self._mode ~= 2 then
        return
    end
    self._allianceMemberInfo = allianceMembersInfoCache
    self:UpdateMemberUI(allianceMembersInfoCache)
end

function AllianceInfoPopupMediator:OnClickAllianceActive()
    local allianceData = self._allianceInfo
    local score = allianceData.Active
    ---@type AllianceActiveTipMediatorParameter
    local param = {}
    param.activeValue = score
    param.clickTrans = self._p_btn_active_level.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    g_Game.UIManager:Open(UIMediatorNames.AllianceActiveTipMediator, param)
end

function AllianceInfoPopupMediator:UpdateAllianceActive()
    local allianceData = self._allianceInfo
    local score = allianceData.Active
    local config = AllianceModuleDefine.GetAllianceActiveScoreLevelConfig(score)
    self._p_text_active_level.text = I18N.Get(config:Name())
    local success,color = CS.UnityEngine.ColorUtility.TryParseHtmlString(config:Color())
    self._p_text_active_level.color = success and color or CS.UnityEngine.Color.white
    g_Game.SpriteManager:LoadSprite(config:Icon(), self._p_icon_active_level)
end

return AllianceInfoPopupMediator