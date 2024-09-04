--- scene:scene_league_main

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require("DBEntityPath")
local GotoUtils = require('GotoUtils')
local BaseUIMediator = require("BaseUIMediator")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local ConfigRefer = require("ConfigRefer")
local AllianceTaskItemDataProvider = require("AllianceTaskItemDataProvider")

---@class AllianceMainMediatorParameter
---@field showJoinAni boolean

---@class AllianceMainMediator:BaseUIMediator
---@field new fun():AllianceMainMediator
---@field super BaseUIMediator
local AllianceMainMediator = class('AllianceMainMediator', BaseUIMediator)

function AllianceMainMediator:ctor()
    BaseUIMediator.ctor(self)
    self._allianceId = nil
    self._showStartImpeach = false
    self._showImpeach = false
    self._declaimTranslationStatus = 0
    self._declaimIsTranslation = false
    self._declaimTranslation = string.Empty
    self._inTranslateDeclaim = nil
end

function AllianceMainMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")
    -----@type CS.UnityEngine.Animation
    self._p_content_ani = self:BindComponent("p_content", typeof(CS.UnityEngine.Animation))
    
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_abbr = self:Text("p_text_abbr")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_player_name = self:Text("p_text_player_name")
    self._p_text_player_name_1 = self:Text("p_text_player_name_1")
    self._p_text_power = self:Text("p_text_power")
    self._p_text_power_1 = self:Text("p_text_power_1")
    self._p_icon_power = self:Button("p_icon_power", Delegate.GetOrCreate(self, self.OnClickPowerIcon))
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_icon_quantity = self:Button("p_icon_quantity", Delegate.GetOrCreate(self, self.OnClickQuantityIcon))
    self._p_text_online = self:Text("p_text_online")
    self._p_text_area = self:Text("p_text_area")
    self._p_text_area_1 = self:Text("p_text_area_1")
    self._p_icon_area = self:Button("p_icon_area", Delegate.GetOrCreate(self, self.OnClickAreaIcon))
    self._p_text_declaim_title = self:Text("p_text_declaim_title", "league_declaim")
    self._p_text_declaim = self:Text("p_text_declaim")
    self._p_icon_language = self:Button("p_icon_language", Delegate.GetOrCreate(self, self.OnClickLanguageIcon))
    self._p_text_language = self:Text("p_text_language")
    self._p_text_language_1 = self:Text("p_text_language_1")
    self._p_text_active = self:Text("p_text_active", "daily_info_activation")
    self._p_icon_active_level = self:Image("p_icon_active_level")
    self._p_text_active_level = self:Text("p_text_active_level")
    self._p_btn_active_level = self:Button("p_btn_active_level", Delegate.GetOrCreate(self, self.OnClickAllianceActive))

    self._p_btn_aboratory = self:Button("p_btn_aboratory", Delegate.GetOrCreate(self, self.OnClickAboratoryBtn))
    self._p_text_aboratory = self:Text("p_text_aboratory", "league_hud_lab")
    ---@type NotificationNode
    self._child_reddot_default_aboratory = self:LuaObject("child_reddot_default")
    self._p_icon_update = self:Image("p_icon_update")

    ---@type AllianceMainCampaignEntry
    self._p_btn_campaign = self:LuaObject("p_btn_campaign")
    --self._p_btn_campaign = self:Button("p_btn_campaign", Delegate.GetOrCreate(self, self.OnClickWarCampaignBtn))
    --self._p_text_campaign = self:Text("p_text_campaign", "league_hud_battle")
    self._p_btn_territory = self:Button("p_btn_territory", Delegate.GetOrCreate(self, self.OnClickTerritoryBtn))
    self._p_text_territory = self:Text("p_text_territory", "league_hud_territory")
    self._p_construction = self:GameObject("p_construction")
    self._p_btn_science = self:Button("p_btn_science", Delegate.GetOrCreate(self, self.OnClickScienceBtn))
    self._p_text_science = self:Text("p_text_science", "league_hud_technology")
    
    self._p_btn_war = self:Button("p_btn_war", Delegate.GetOrCreate(self, self.OnClickBtnWar))
    ---@type NotificationNode
    self._child_reddot_default_btn_war = self:LuaObject("child_reddot_default_btn_war")
    self._p_text_war = self:Text("p_text_war", "alliance_assemble_title_name")
    
    self._p_btn_member = self:Button("p_btn_member", Delegate.GetOrCreate(self, self.OnClickBtnMember))
    ---@type NotificationNode
    self._child_reddot_default_btn_number = self:LuaObject("child_reddot_default_btn_number")
    self._p_text_member = self:Text("p_text_member", "league_hud_member")
    
    -- self._p_btn_resources = self:Button("p_btn_resources", Delegate.GetOrCreate(self, self.OnClickBtnResource))
    -- self._p_text_resources = self:Text("p_text_resources", "league_hud_resource")
    
    self._p_btn_other = self:Button("p_btn_other", Delegate.GetOrCreate(self, self.OnClickBtnOther))
    self._p_text_other = self:Text("p_text_other", "league_hud_set")
    ---@type NotificationNode
    self._child_reddot_default_btn_other = self:LuaObject("child_reddot_default_btn_other")
    
    self._p_btn_convene = self:Button("p_btn_convene", Delegate.GetOrCreate(self, self.OnClickBtnConvene))
    self._p_text_convene = self:Text("p_text_convene", "alliance_gathering_point_8")
    ---@type NotificationNode
    self._child_reddot_default_btn_convene = self:LuaObject("child_reddot_default_btn_convene")

    self._p_btn_territory_entry = self:Button("p_btn_territory_entry", Delegate.GetOrCreate(self, self.OnClickBtnTerritoryEntry))
    self._p_text_other = self:Text("p_text_territory_entry", "league_hud_territory")
    ---@type NotificationNode
    self._child_reddot_default_btn_territory_entry = self:LuaObject("child_reddot_default_btn_territory_entry")
    
    self._p_btn_gift = self:Button("p_btn_gift", Delegate.GetOrCreate(self, self.OnClickBtnGift))
    self._p_text_gift = self:Text("p_text_gift", "league_hud_gift")
    ---@type NotificationNode
    self._child_reddot_default_btn_gift = self:LuaObject("child_reddot_default_btn_gift")
    
    self._p_btn_shop = self:Button("p_btn_shop", Delegate.GetOrCreate(self, self.OnClickBtnShop))
    ---@type NotificationNode
    self._child_reddot_default_btn_shop = self:LuaObject("child_reddot_default_btn_shop")
    self._p_text_shop = self:Text("p_text_shop", "league_hud_store")
    self._p_btn_shop:SetVisible(true)
    
    ---@type AllianceMainNotifyPopupComponent
    self._p_popup = self:LuaObject("p_popup")    
    self._p_vx_trigger = self:AnimTrigger("p_vx_trigger")
    
    self._p_btn_impeach = self:Button("p_btn_impeach", Delegate.GetOrCreate(self, self.OnClickJoinImpeachment))
    self._p_text_impeach = self:Text("p_text_impeach", "alliance_retire_impeach_entrybutton")
    self._p_impeach = self:GameObject("p_impeach")
    self._p_text_hint = self:Text("p_text_hint", "alliance_retire_impeach_unlockmail_content")
    ---@type NotificationNode
    self._child_reddot_impeach = self:LuaObject("child_reddot_impeach")

    self._p_text_recruit = self:Text("p_text_recruit", "alliance_recruit_title_member")
    self._p_btn_recruit = self:Button("p_btn_recruit", Delegate.GetOrCreate(self, self.OnClickBtnRecruit))
    self._p_btn_group_translate = self:Button("p_btn_group_translate", Delegate.GetOrCreate(self, self.OnClickBtnRecuritTranslate))
    self._p_group_translating = self:GameObject("p_group_translating")
    self._p_btn_group_revert = self:Button("p_btn_group_revert", Delegate.GetOrCreate(self, self.OnClickBtnCancelRecuritTranslate))


    --联盟限时任务
    self._p_time_limited_task = self:GameObject('p_time_limited_task')
    self._p_text_title_task =self:Text('p_text_title_task','alliance_target_3')
    ---@type CommonTimer
    self._child_time = self:LuaObject('child_time')
    self._p_text_task_content =self:Text('p_text_task_content')
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickTimeLimitedTask))
    self._child_reddot_default_limited_time_task = self:LuaObject('child_reddot_default_limited_time_task')
    --联盟帮助
    self._p_btn_help = self:Button("p_btn_help", Delegate.GetOrCreate(self, self.OnClickHelp))
    self._p_text_help = self:Text("p_text_help", "league_hud_request")
    ---@type NotificationNode
    self._child_reddot_default_help = self:LuaObject("child_reddot_default_help")

    --联盟成就
    self._p_btn_achievement = self:Button("p_btn_achievement", Delegate.GetOrCreate(self, self.OnClickAchievement))
    self._p_text_achievement = self:Text("p_text_achievement", "alliance_target_1")
    ---@type NotificationNode
    self._child_reddot_default_achievement = self:LuaObject("child_reddot_default_achievement")

    self._child_reddot_default_btn_convene:SetVisible(false)
    self._p_btn_notice = self:Button("p_btn_notice", Delegate.GetOrCreate(self, self.OnClickBtnNotice))
    self.child_reddot_default_notice = self:LuaObject("child_reddot_default_notice")
    self._p_text_notice = self:Text("p_text_notice")
end

function AllianceMainMediator:SetNotificationReddot()
    ModuleRefer.NotificationModule:RemoveFromGameObject(self.child_reddot_default_notice.go, false)
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Notice, NotificationType.ALLIANCE_MAIN_NOTICE)
    ModuleRefer.NotificationModule:AttachToGameObject(node, self.child_reddot_default_notice.go, self.child_reddot_default_notice.redTextGo, self.child_reddot_default_notice.redText)

    local isR4Above = ModuleRefer.AllianceModule:IsAllianceR4Above()
    if isR4Above then
        self._p_text_notice.text = I18N.Get("Alliance_notice_release")
    else
        self._p_text_notice.text = I18N.Get("league_hud_notice")
    end
end

function AllianceMainMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    self:SetupTrackNotify(true)
    if self._allianceId then
        self:UpdateUI()
        ModuleRefer.AllianceModule:UpdateAllianceTechUpdateNotify(ModuleRefer.NotificationModule, ModuleRefer.AllianceModule:GetMyAllianceData())
    end
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LIMITED_TIME_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshLimitedTask))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceBasicInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBriefInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsAFK.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActiveOrAFKChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsNoActive.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActiveOrAFKChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.BuilderRuinRebuild.Buildings.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceRebuildChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMessage.Informs.MsgPath, Delegate.GetOrCreate(self, self.UpdateDeclaim))
end

---@param param AllianceMainMediatorParameter
function AllianceMainMediator:OnOpened(param)
    ModuleRefer.AllianceJourneyModule:RefreshRedDot(true)
    ---@type CommonBackButtonData
    local btnData = {}
    btnData.title = I18N.Get("league")
    self._child_common_btn_back:FeedData(btnData)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    ---@type AllianceMainCampaignEntryData
    -- local allianceMainCampaignEntryData = {}
    -- allianceMainCampaignEntryData.onClick = Delegate.GetOrCreate(self, self.OnClickWarCampaignBtn)
    -- self._p_btn_campaign:FeedData(allianceMainCampaignEntryData)
    if self._p_btn_campaign then
        self._p_btn_campaign:SetVisible(false)
    end
    self:UpdateUI()
    ModuleRefer.AllianceModule:UpdateAllianceTechUpdateNotify(ModuleRefer.NotificationModule, ModuleRefer.AllianceModule:GetMyAllianceData())
    ModuleRefer.GuideModule:CheckAllianceLeaderGuide()
    --if param and param.showJoinAni then
    --    self._child_common_btn_back:SetVisible(false)
    --    self._p_content_ani.enabled = true
    --    self._p_content_ani:SetAnimationTime(self._p_content_ani.clip.name, 0)
    --    self._p_content_ani:Sample()
    --    self._p_content_ani:Play()
    --else
    --    self._child_common_btn_back:SetVisible(true)
    --    self._p_content_ani:SetAnimationTime(self._p_content_ani.clip.name, self._p_content_ani.clip.length)
    --    self._p_content_ani:Sample()
    --end
    self._showImpeach = false
    self._showStartImpeach = false
    self._p_btn_impeach:SetVisible(false)
    self._p_impeach:SetVisible(false)
    local showEntryAni = false
    local impeachInfo = ModuleRefer.AllianceModule:GetMyAllianceImpeachInfo()
    if impeachInfo.IsImpeach then
        self._p_btn_impeach:SetVisible(true)
        self._p_impeach:SetVisible(true)
        self._showImpeach = true
        if ModuleRefer.AllianceModule:IsInImpeachmentVote() then
            self._p_vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            showEntryAni = true
        end
    else
        if ModuleRefer.AllianceModule:IsAllianceLeaderAFKorNoActive() then
            self._p_btn_impeach:SetVisible(true)
            self._p_impeach:SetVisible(true)
            showEntryAni = true
            self._showStartImpeach = true
        end
    end
    if showEntryAni then
        local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        local lastFlag = TimeFormatter.ToDateTime(g_Game.PlayerPrefsEx:GetIntByUid("IMPEACH_LAST_SHOW", 0))
        local toDay = TimeFormatter.ToDateTime(nowTime)
        if TimeFormatter.InSameDay(lastFlag, toDay) then
            self._p_vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            g_Game.PlayerPrefsEx:SetIntByUid("IMPEACH_LAST_SHOW", nowTime)
            self._p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    elseif ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance.IsNeedReadAllianceLeaderChangeInfo then
        local info = ModuleRefer.AllianceModule:GetLeaderChangeInfo()
        if info then
            g_Game.UIManager:Open(UIMediatorNames.AllianceNewLeaderMediator, info)
        end
    end
    
    self:OnAllianceRebuildChanged()
    self:RefreshLimitedTask()
    self:SetNotificationReddot()
end

function AllianceMainMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LIMITED_TIME_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshLimitedTask))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceBasicInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBriefInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsAFK.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActiveOrAFKChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsNoActive.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActiveOrAFKChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.BuilderRuinRebuild.Buildings.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceRebuildChanged))
    self:SetupTrackNotify(false)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMessage.Informs.MsgPath, Delegate.GetOrCreate(self, self.UpdateDeclaim))
end

function AllianceMainMediator:OnClose(data)
    self._inTranslateDeclaim = nil
    self._allianceId = nil
end

---@param entity wds.Alliance
function AllianceMainMediator:OnAllianceBriefInfoChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:UpdateUI()
end

---@param entity wds.Alliance
function AllianceMainMediator:OnAllianceImpeachStatusChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:RefreshShowImpeach()
end

---@param entity wds.Alliance
function AllianceMainMediator:OnAllianceActiveOrAFKChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local v = ModuleRefer.AllianceModule:IsAllianceLeaderAFKorNoActive()
    if v ~= self._showStartImpeach then
        self:RefreshShowImpeach()
    end
end

function AllianceMainMediator:OnAllianceRebuildChanged(entity)
    local hasRebuild = ModuleRefer.VillageModule:HasRebuildVillage()
    self._p_construction:SetVisible(hasRebuild)
end

function AllianceMainMediator:RefreshShowImpeach()
    self._showStartImpeach = false
    self._showImpeach = false
    self._p_btn_impeach:SetVisible(false)
    self._p_impeach:SetVisible(false)
    local impeachInfo = ModuleRefer.AllianceModule:GetMyAllianceImpeachInfo()
    if impeachInfo.IsImpeach then
        self._p_btn_impeach:SetVisible(true)
        self._p_impeach:SetVisible(true)
        self._p_vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self._showImpeach = true
    elseif ModuleRefer.AllianceModule:IsAllianceLeaderAFKorNoActive() then
        self._p_btn_impeach:SetVisible(true)
        self._p_impeach:SetVisible(true)
        self._p_vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self._showStartImpeach = true
    end
end
    
function AllianceMainMediator:UpdateUI()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceData == nil then
        return
    end
    local basicInfo = allianceData.AllianceBasicInfo
    self._child_league_logo:FeedData(basicInfo.Flag)
    self._p_text_abbr.text = string.IsNullOrEmpty(basicInfo.Abbr) and '' or string.format("[%s]", basicInfo.Abbr)
    self._p_text_name.text = basicInfo.Name
    self._p_text_player_name.text = I18N.GetWithParams("alliance_main_label1", "")
    self._p_text_player_name_1.text = basicInfo.LeaderName
    self._p_text_power.text = I18N.GetWithParams("alliance_main_label2" ,"")
    self._p_text_power_1.text = tostring(math.floor(basicInfo.Power + 0.5))
    self._p_text_quantity.text = I18N.GetWithParams("alliance_main_label3", "","")
    local quantityText = tostring(basicInfo.MemberCountCur).."/"..tostring(basicInfo.MemberCountMax)
    local onlineText = I18N.GetWithParams("alliance_number_online", ModuleRefer.AllianceModule:GetMyAllianceMemberOnlineCount())
    if ModuleRefer.AllianceModule:IsAllianceR4Above() then
        self._p_text_online.text = quantityText .. " ".. onlineText
    else
        self._p_text_online.text = quantityText
    end
    local isLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    self._p_btn_recruit.gameObject:SetActive(isLeader)
    self._p_btn_convene:SetVisible(isLeader)

    local langId = basicInfo.Language
    self._p_text_language.text = I18N.Get("game_settings_language")
    self._p_text_language_1.text = AllianceModuleDefine.GetConfigLangaugeStr(langId)

    local territoryCount = allianceData.MapBuildingBriefs.OccupyTerritoryNum
    self._p_text_area.text = I18N.GetWithParams("alliance_main_label4", "")
    self._p_text_area_1.text = tostring(territoryCount)
    self:UpdateDeclaim()
    self:UpdateAllianceActive()
end

function AllianceMainMediator:UpdateDeclaim()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local basicInfo = allianceData.AllianceBasicInfo

    local notice
    local index = -1
    local message = ModuleRefer.AllianceModule:GetMyAllianceInforms()
    for k,v in pairs(message) do
        if k > index then
            notice = v.Content
            index = k
        end
    end

    if notice then
        self._displayText = notice
    else
        self._displayText = basicInfo.Notice
    end

    if self._declaimTranslationStatus == 2 then
        self._p_text_declaim.text = self._declaimTranslation
    else
        self._p_text_declaim.text = self._displayText
    end

    self._p_btn_group_translate:SetVisible(self._declaimTranslationStatus == 0)
    self._p_group_translating:SetVisible(self._declaimTranslationStatus == 1)
    self._p_btn_group_revert:SetVisible(self._declaimTranslationStatus == 2)
end

function AllianceMainMediator:UpdateAllianceActive()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local score = allianceData.AllianceActive.Week.SumScore
    local config = AllianceModuleDefine.GetAllianceActiveScoreLevelConfig(score)
    self._p_text_active_level.text = I18N.Get(config:Name())
    local success,color = CS.UnityEngine.ColorUtility.TryParseHtmlString(config:Color())
    self._p_text_active_level.color = success and color or CS.UnityEngine.Color.white
    g_Game.SpriteManager:LoadSprite(config:Icon(), self._p_icon_active_level)
end

function AllianceMainMediator:SetupTrackNotify(add)
    local notificationModule = ModuleRefer.NotificationModule
    
    local member = self._child_reddot_default_btn_number
    local war = self._child_reddot_default_btn_war
    local other = self._child_reddot_default_btn_other
    local shop = self._child_reddot_default_btn_shop
    local territory = self._child_reddot_default_btn_territory_entry
    local tech = self._child_reddot_default_aboratory
    local impeach = self._child_reddot_impeach
    local gift = self._child_reddot_default_btn_gift
    local help = self._child_reddot_default_help
    local achievement = self._child_reddot_default_achievement

    if add then
        local warNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.War, NotificationType.ALLIANCE_MAIN_WAR)
        local memberNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.Member, NotificationType.ALLIANCE_MAIN_MEMBER)
        local otherNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.Other, NotificationType.ALLIANCE_MAIN_OTHER)
        local shopNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.Shop, NotificationType.ALLIANCE_MAIN_SHOP)
        local territoryNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.Territory, NotificationType.ALLIANCE_MAIN_TERRITORY)
        local techNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.Tech, NotificationType.ALLIANCE_MAIN_TECH_ENTRY)
        local techUpdateNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TechUpdate, NotificationType.ALLIANCE_MAIN_TECH_ENTRY_UPDATE)
        local impeachNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.ImpeachmentEntry, NotificationType.ALLIANCE_MAIN_IMPEACHMENT_ENTRY)
        local giftNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.GiftEntry, NotificationType.ALLIANCE_MAIN_GIFT_ENTRY)
        local helpNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.HelpEntry, NotificationType.ALLIANCE_MAIN_HELP_ENTRY)
        local achievementNode = notificationModule:GetDynamicNode("AllianceAchievement_Main",NotificationType.ALLIANCE_ACHIEVEMENT)

        notificationModule:AttachToGameObject(warNode, war.go, war.redTextGo ,war.redText)
        notificationModule:AttachToGameObject(memberNode, member.go, member.redTextGo, member.redText)
        notificationModule:AttachToGameObject(otherNode, other.go, other.redDot)
        notificationModule:AttachToGameObject(shopNode, shop.go, shop.redNew, shop.redNewText)
        notificationModule:AttachToGameObject(territoryNode, territory.go, territory.redDot)
        notificationModule:AttachToGameObject(techNode, tech.go, tech.redTextGo, tech.redText)
        notificationModule:AttachToGameObject(techUpdateNode, self._p_btn_aboratory.gameObject, self._p_icon_update.gameObject)
        notificationModule:AttachToGameObject(impeachNode, impeach.go, impeach.redDot)
        notificationModule:AttachToGameObject(giftNode, gift.go, gift.redTextGo, gift.redText)
        notificationModule:AttachToGameObject(helpNode, help.go, help.redTextGo,help.redText)
        notificationModule:AttachToGameObject(achievementNode, achievement.go, achievement.redTextGo, achievement.redText)
    else
        notificationModule:RemoveFromGameObject(war.go, false)
        notificationModule:RemoveFromGameObject(member.go, false)
        notificationModule:RemoveFromGameObject(other.go, false)
        notificationModule:RemoveFromGameObject(shop.go, false)
        notificationModule:RemoveFromGameObject(territory.go, false)
        notificationModule:RemoveFromGameObject(tech.go, false)
        notificationModule:RemoveFromGameObject(self._p_btn_aboratory.gameObject, true)
        notificationModule:RemoveFromGameObject(impeach.go, false)
        notificationModule:RemoveFromGameObject(gift.go, false)
        notificationModule:RemoveFromGameObject(help.go, false)
        notificationModule:RemoveFromGameObject(achievement.go, false)
    end
end

function AllianceMainMediator:OnClickPowerIcon()
    g_Logger.Log("click OnClickPowerIcon")
end

function AllianceMainMediator:OnClickQuantityIcon()
    g_Logger.Log("click OnClickQuantityIcon")
end

function AllianceMainMediator:OnClickAreaIcon()
    g_Logger.Log("click OnClickAreaIcon")
end

function AllianceMainMediator:OnClickLanguageIcon()
    g_Logger.Log("click OnClickLanguageIcon")
end

function AllianceMainMediator:OnClickAllianceActive()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local score = allianceData.AllianceActive.Week.SumScore
    ---@type AllianceActiveTipMediatorParameter
    local param = {}
    param.activeValue = score
    param.clickTrans = self._p_btn_active_level.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    g_Game.UIManager:Open(UIMediatorNames.AllianceActiveTipMediator, param)
end

function AllianceMainMediator:OnClickAboratoryBtn()
    g_Logger.Log("click OnClickAboratoryBtn")
    ---@type AllianceTechResearchMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceTechResearchMediator, param)
end

function AllianceMainMediator:OnClickWarCampaignBtn()
    if not ModuleRefer.AllianceModule:CheckBehemothUnlock(true) then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothListMediator)
end

function AllianceMainMediator:OnClickTerritoryBtn()
    g_Logger.Log("click OnClickTerritoryBtn")
end

function AllianceMainMediator:OnClickScienceBtn()
    g_Logger.Log("click OnClickScienceBtn")
end

-- group btn
function AllianceMainMediator:OnClickBtnWar()
    g_Logger.Log("click OnClickBtnWar")
    ---@type AllianceWarMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, param)
end

function AllianceMainMediator:OnClickBtnMember()
    ---@type AllianceMemberMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceMemberMediator, param)
end

function AllianceMainMediator:OnClickBtnOther()
    ---@type AllianceManageMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceManageMediator, param)
end

function AllianceMainMediator:OnClickBtnConvene()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    local lastConveneTime = allianceInfo.AllianceBasicInfo.LastConveneTime.Seconds
    local conveneCD = ConfigRefer.AllianceConsts:AllianceConveneCoolDown() / 1000000000
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local canSend
    local remainT
    if lastConveneTime > 0 then
        remainT = lastConveneTime + conveneCD - curT
        canSend = remainT <= 0
    else
        canSend = true
    end

    if canSend then
        ModuleRefer.AllianceModule:SendAllianceConvene()
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_gathering_point_7",TimeFormatter.SimpleFormatTime(remainT)))
    end
end

function AllianceMainMediator:OnClickBtnTerritoryEntry()
    ---@type AllianceTerritoryMainMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainMediator, param)
end

function AllianceMainMediator:OnClickBtnGift()
    g_Game.UIManager:Open(UIMediatorNames.AllianceGiftMediator)
end

function AllianceMainMediator:OnClickBtnShop()
    ---@type UIShopMeidatorParameter
    local param = {}
    param.tabIndex = 4
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator, param)
end

function AllianceMainMediator:OnClickJoinImpeachment()
    local impeachInfo = ModuleRefer.AllianceModule:GetMyAllianceImpeachInfo()
    if impeachInfo.IsImpeach then
        g_Game.UIManager:Open(UIMediatorNames.AllianceImpeachmentVoteMediator)
    else
        ModuleRefer.AllianceModule:RequestImpeachNewLeader(self._p_btn_impeach.transform, function(cmd, isSuccess, rsp)
            if isSuccess then
                ModuleRefer.AllianceModule:StartImpeachmentVote(rsp.NewLeaderName)
            end
        end)
    end
end

function AllianceMainMediator:OnClickBtnRecruit()
    g_Game.UIManager:Open(UIMediatorNames.AllianceRecruitSettingMediator)
end

function AllianceMainMediator:OnClickBtnRecuritTranslate()
    if self._declaimTranslationStatus ~= 0 then return end
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local basicInfo = allianceData.AllianceBasicInfo
    if self._inTranslateDeclaim == self._displayText then
        self._declaimTranslationStatus = 2
        self:UpdateDeclaim()
        return
    end
    self._declaimTranslationStatus = 1
    self:UpdateDeclaim()
    self._inTranslateDeclaim = self._displayText
    local chatSdk = CS.FunPlusChat.FPChatSdk
    chatSdk.Translate(self._inTranslateDeclaim, CS.FunPlusChat.FunLang.unknown, ModuleRefer.ChatSDKModule:GetUserLanguage(), function(result)
        -- local tmpAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
        -- local tmpBasicInfo = tmpAllianceData.AllianceBasicInfo
        if self._inTranslateDeclaim ~= self._displayText then
            return
        end
        self._declaimTranslation = result and result.data and result.data.targetText
        self._declaimTranslationStatus = 2
        self:UpdateDeclaim()
    end, "Livedata")
end

function AllianceMainMediator:OnClickBtnCancelRecuritTranslate()
    if self._declaimTranslationStatus ~= 2 then return end
    self._declaimTranslationStatus = 0
    self:UpdateDeclaim()
end

function AllianceMainMediator:OnLeaveAlliance(allianceId)
    if self._allianceId and self._allianceId == allianceId then
        self:CloseSelf()
        self._inTranslateDeclaim = nil
    end
end

function AllianceMainMediator:OnClickAchievement(allianceId)
    g_Game.UIManager:Open(UIMediatorNames.AllianceAchievementMediator)
end

function AllianceMainMediator:OnClickHelp(allianceId)
    g_Game.UIManager:Open(UIMediatorNames.AllianceHelpMediator)
end

function AllianceMainMediator:OnClickTimeLimitedTask(allianceId)
    g_Game.UIManager:Open(UIMediatorNames.AllianceTimeLimitedTaskMediator)
end

function AllianceMainMediator:RefreshLimitedTask()
    ModuleRefer.AllianceJourneyModule:LoadAllianceShortTermTasks()
    local task = ModuleRefer.AllianceJourneyModule:GetFirstAllianceShortTermTask()
    if not task or task.State == wds.TaskState.TaskStateFinished or task.State == wds.TaskState.TaskStateExpired then
        self._p_time_limited_task:SetVisible(false)
        return
    end
    self._p_time_limited_task:SetVisible(true)
    local provider = AllianceTaskItemDataProvider.new(task.TID)
    self._p_text_task_content.text = provider:GetTaskStr()
    self:SetCountDown(task)

    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_ShortTerm", NotificationType.ALLIANCE_ACHIEVEMENT_SHORT)
    ModuleRefer.NotificationModule:AttachToGameObject(node, self._child_reddot_default_limited_time_task.go, self._child_reddot_default_limited_time_task.redTextGo, self._child_reddot_default_limited_time_task.redText)
end

function AllianceMainMediator:SetCountDown(task)
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()

    -- 解锁倒计时
    local isWaitUnlock = curTime < task.UnlockTimeStamp
    -- 过期倒计时
    local isWaitExpire = curTime >= task.UnlockTimeStamp and curTime < task.ExpireTimeStamp

    local endT
    if isWaitUnlock then
        endT = task.UnlockTimeStamp
    elseif isWaitExpire then
        endT = task.ExpireTimeStamp
    else
        self._child_time:SetVisible(false)
        return
    end

    local timerData = {}
    timerData.endTime = endT
    timerData.needTimer = true
    timerData.callBack = Delegate.GetOrCreate(self,self.RefreshLimitedTask)
    self._child_time:FeedData(timerData)
    self._child_time:SetVisible(true)
end

function AllianceMainMediator:OnClickBtnNotice()
    ---@type AllianceNoticePopupMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceNoticePopupMediator, param)
end

return AllianceMainMediator