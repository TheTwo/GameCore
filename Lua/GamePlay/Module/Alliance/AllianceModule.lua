local EventConst = require("EventConst")
local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local AllianceParameters = require("AllianceParameters")
local AllianceBasicInfoCacheHelper = require("AllianceBasicInfoCacheHelper")
local AllianceMembersInfoCacheHelper = require("AllianceMembersInfoCacheHelper")
local NotificationType = require("NotificationType")
local ProtocolId = require("ProtocolId")
local I18N = require("I18N")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local GotoUtils = require("GotoUtils")
local AllianceCurrencyType = require("AllianceCurrencyType")
local OnChangeHelper = require("OnChangeHelper")
local AllianceAttr = require("AllianceAttr")
local AllianceTechnologyType = require("AllianceTechnologyType")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ServiceDynamicDescHelper = require("ServiceDynamicDescHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local AllianceModule_Behemoth = require("AllianceModule_Behemoth")
local AllianceActivityDataProvider = require("AllianceActivityDataProvider")
local CityAttrType = require("CityAttrType")
local AllianceBattleType = require("AllianceBattleType")
local ToastFuncType = require("ToastFuncType")
local TimerUtility = require("TimerUtility")
local SlgUtils = require("SlgUtils")
local MapBuildingSubType = require("MapBuildingSubType")
local BattleSignalConfig = require("BattleSignalConfig")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local ColorConsts = require("ColorConsts")
local KingdomMapUtils = require("KingdomMapUtils")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local TimeFormatter = require("TimeFormatter")
local CommonDailyGiftState = require('CommonDailyGiftState')
local BaseModule = require("BaseModule")

---@class AllianceModuleCreateAllianceParameter
---@field name string
---@field abbr string
---@field notice string
---@field flag wds.AllianceFlag
---@field lang number
---@field joinSetting number

---@alias CurrencyAttrPair {base:number, multi:number, point:number}
---@alias VillageWarCountDownInfo {typeHash:number, id:number, startCountdonwTime:number, warInfo:wds.VillageAllianceWarInfo}

---注意！！ 和服务端交互 用于表示联盟成员的id 使用其FacebookId， 问就是这玩意标识一个跨服身份 但是名字有误导
---@class AllianceModule:BaseModule
---@field new fun():AllianceModule
---@field super BaseModule
local AllianceModule = class('AllianceModule', BaseModule)

---@return table<number, {speed:number|nil, limit:number|nil}>
local function GenerateCurrencyAttrMap()
    local ret = {}
    
    local Fund = {}
    Fund.speed = AllianceAttr.Currency_Fund_Speed
    Fund.limit = nil
    ret[AllianceCurrencyType.Fund] = Fund
    
    local Wood = {}
    Wood.speed = AllianceAttr.Currency_Wood_Speed
    Wood.limit = AllianceAttr.Currency_Wood_Limit
    ret[AllianceCurrencyType.Wood] = Wood
    
    local Iron = {}
    Iron.speed = AllianceAttr.Currency_Iron_Speed
    Iron.limit = AllianceAttr.Currency_Iron_Limit
    ret[AllianceCurrencyType.Iron] = Iron
    
    local Food = {}
    Food.speed = AllianceAttr.Currency_Food_Speed
    Food.limit = AllianceAttr.Currency_Food_Limit
    ret[AllianceCurrencyType.Food] = Food

    local WarCard = {}
    WarCard.speed = AllianceAttr.Currency_WarCard_Speed
    WarCard.limit = AllianceAttr.Currency_WarCard_Limit
    ret[AllianceCurrencyType.WarCard] = WarCard

    local BuildCard = {}
    BuildCard.speed = AllianceAttr.Currency_BuildCard_Speed
    BuildCard.limit = AllianceAttr.Currency_BuildCard_Limit
    ret[AllianceCurrencyType.BuildCard] = BuildCard
    
    return ret
end

function AllianceModule:ctor()
    BaseModule.ctor(self)
    ---@private
    ---@type number
    self._playerId = nil
    ---@private
    ---@type number
    self._allianceId = nil
    ---@private
    ---@type number
    self._cachedAllianceRank = nil
    ---@private
    ---@type AllianceBasicInfoCacheHelper
    self._allianceBasicInfoCacheHelper = nil
    ---@private
    ---@type AllianceMembersInfoCacheHelper
    self._allianceMembersInfoCacheHelper = nil
    self._allianceAuthorityMatrix = {}
    self.HasbehemothCageEnterMinR = 5
    self._triggerJoinAllianceNewEntityId = nil
    ---@type table<number, CS.Notification.NotificationDynamicNode>
    self._noticeNodes = {}
    self._onlineCount = 1
    self._totalCount = 1
    self._memberCountDirty = false
    ---@type table<number, number>
    self._currencyId2Type = {}
    ---@type table<number, table<number, boolean>>
    self._currencyType2IdSet = {}
    ---@type table<number, {speed:number|nil, limit:number|nil}>
    self._currencyType2Attr = GenerateCurrencyAttrMap()
    ---@type table<number, number> @value 1-AllianceCurrencyAutoAddTimeInterval,2-global  AutoAddTimeInterval
    self._speedAttrIdSet = {}
    ---@type table<number, number>
    self._speedAttrId2CurrencyTypeSet = {}
    
    self._canUpTechCount = 0
    self._selfDonateLeftCount = 0
    self._canUpTechGroupIds = {}
    
    ---@type table<number, CS.Notification.NotificationDynamicNode>
    self._allianceLabelUnreadNode = {}
    ---@type table<number, wds.AllianceMapLabel>
    self._cachedAllianceLabel = {}
    
    ---@type table<number, AllianceEnergyBoxConfigCell>
    self._allianceEnergyBoxLevelConfig = {}
    ---@type AllianceEnergyBoxConfigCell
    self._maxAllianceEnergyBoxLevelConfig = nil
    ---@type AllianceEnergyBoxConfigCell
    self._minAllianceEnergyBoxLevelConfig = nil
    ---@type table<number, AllianceGiftLevelConfigCell>
    self._allianceGiftLevelConfig = {}
    ---@type AllianceGiftLevelConfigCell
    self._maxAllianceGiftLevelConfig = nil
    ---@type AllianceGiftLevelConfigCell
    self._minAllianceGiftLevelConfig = nil
    self._setGreyHelpRequestBubbleTimeCd = 1 * 60 * 60
    self._lastSetGreyHelpRequestBubbleTime = 0
    self.Behemoth = AllianceModule_Behemoth.new(self)
    self._allianceEntryUnlockId = nil
    self.ActivityDataProvider = AllianceActivityDataProvider.new(self)

    self._tickCheckBehemothCageWarStart = nil
    ---@type VillageWarCountDownInfo[]
    self._tickVillageWarStartCountDownQueue = {}
    ---@type AllianceVillageWarInfoTipMediatorParameter[]
    self._tickVillageWarStartNotifyTipCountQueue = {}
end

function AllianceModule:OnRegister()
    self._allianceEntryUnlockId = nil
    self.invitePlayerCDs = {}
    for i, v in ConfigRefer.HudRightdown:ipairs() do
        if v:ClickThrough() == AllianceModuleDefine.UIEntry.ALLIANCE_HUD_ENTRY_CLICK then
            self._allianceEntryUnlockId = v:SystemSwitch()
        end
    end
    self._allianceBasicInfoCacheHelper = AllianceBasicInfoCacheHelper.new(120, 32)
    self._allianceMembersInfoCacheHelper = AllianceMembersInfoCacheHelper.new(120, 32)
    self:SetupEvents(true)
    self._allianceBasicInfoCacheHelper:AddEvents()
    self._allianceMembersInfoCacheHelper:AddEvents()
    table.clear(self._allianceAuthorityMatrix)
    local RKeys = AllianceModuleDefine.RKeys
    local config = ConfigRefer.AllianceAuthority
    for id, cellData in config:ipairs() do
        local keyString = cellData:KeyString()
        if not self._allianceAuthorityMatrix[keyString] then
            self._allianceAuthorityMatrix[keyString] = {}
        end
        local rs = self._allianceAuthorityMatrix[keyString]
        for rId, Rkey in pairs(RKeys) do
            local valueCell = cellData[Rkey]
            if valueCell and valueCell(cellData) then
                rs[rId] = true
            end
        end
    end
    local configCurrency = ConfigRefer.AllianceCurrency
    for _, v in configCurrency:ipairs() do
        local id = v:Id()
        local type = v:CurrencyType()
        self._currencyId2Type[id] = type
        local set = self._currencyType2IdSet[type]
        if not set then
            set = {}
            self._currencyType2IdSet[type] = set
        end
        set[id] = true
    end
    table.clear(self._speedAttrIdSet)
    table.clear(self._speedAttrId2CurrencyTypeSet)
    for currencyType, v in pairs(self._currencyType2Attr) do
        if v.speed then
            local displayAttr = ConfigRefer.AttrDisplay:Find(v.speed)
            if displayAttr then
                local id = displayAttr:BaseAttrTypeId()
                if id ~= 0 then
                    self._speedAttrIdSet[id] = 1
                    self._speedAttrId2CurrencyTypeSet[id] = currencyType
                end
                id = displayAttr:PointAttrTypeId()
                if id ~= 0 then
                    self._speedAttrIdSet[id] = 1
                    self._speedAttrId2CurrencyTypeSet[id] = currencyType
                end
            end
        end
    end
    self._speedAttrIdSet[90002] = 2
    self._speedAttrIdSet[90004] = 2
    self._speedAttrIdSet[90005] = 2
    self._speedAttrIdSet[90007] = 2
    self._speedAttrIdSet[90009] = 2
    self._speedAttrIdSet[90011] = 2
    
    table.clear(self._allianceEnergyBoxLevelConfig)
    table.clear(self._allianceGiftLevelConfig)
    self._maxAllianceEnergyBoxLevelConfig = nil
    self._minAllianceEnergyBoxLevelConfig = nil
    self._maxAllianceGiftLevelConfig = nil
    self._minAllianceGiftLevelConfig = nil
    for _, v in ConfigRefer.AllianceEnergyBox:ipairs() do
        if not self._maxAllianceEnergyBoxLevelConfig or self._maxAllianceEnergyBoxLevelConfig:Level() <= v:Level() then
            self._maxAllianceEnergyBoxLevelConfig = v
        end
        if not self._minAllianceEnergyBoxLevelConfig or self._maxAllianceEnergyBoxLevelConfig:Level() > v:Level() then
            self._minAllianceEnergyBoxLevelConfig = v
        end
        self._allianceEnergyBoxLevelConfig[v:Level()] = v
    end
    for _, v in ConfigRefer.AllianceGiftLevel:ipairs() do
        if not self._maxAllianceGiftLevelConfig or self._maxAllianceGiftLevelConfig:Level() <= v:Level() then
            self._maxAllianceGiftLevelConfig = v
        end
        if not self._minAllianceGiftLevelConfig or self._minAllianceGiftLevelConfig:Level() <= v:Level() then
            self._minAllianceGiftLevelConfig = v
        end
        self._allianceGiftLevelConfig[v:Level()] = v
    end
    self._setGreyHelpRequestBubbleTimeCd = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:HelpGreyBubbleCD())
    self.HasbehemothCageEnterMinR = #RKeys
    local authorityEnterBehemothCage = self._allianceAuthorityMatrix[AllianceAuthorityItem.EnterBehemothCage]
    if authorityEnterBehemothCage then
        for i = #RKeys, 1, -1 do
            if authorityEnterBehemothCage[i] then
                self.HasbehemothCageEnterMinR = i
            else
                break
            end
        end
    end
    self.Behemoth:OnRegister()
end

function AllianceModule:OnRemove()
    self._tickCheckBehemothCageWarStart = nil
    self.Behemoth:OnRemove()
    self._allianceMembersInfoCacheHelper:RemoveEvents()
    self._allianceBasicInfoCacheHelper:RemoveEvents()
    self:SetupEvents(false)
    self._allianceMembersInfoCacheHelper:ClearAll()
    self._allianceBasicInfoCacheHelper:ClearAll()
    self:DestroyInviteTimer()
end

function AllianceModule:SetupEvents(isAdd)
    if isAdd then
        g_Game.EventManager:AddListener(EventConst.HUD_BOTTOM_RIGHT_SUB_BUTTON_CLICK, Delegate.GetOrCreate(self, self.OnHudButtonClick))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_FIND_NEXT_RECRUIT_TOP_INFO, Delegate.GetOrCreate(self, self.OnFindNextRecruitTopInfo))
        g_Game.ServiceManager:AddResponseCallback(ProtocolId.NotifyApplyResult, Delegate.GetOrCreate(self, self.OnNotifyApplyResult))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceChanged))
        g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Alliance, Delegate.GetOrCreate(self, self.OnNewAllianceEntity))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceApplicants.Applicants.MsgPath, Delegate.GetOrCreate(self, self.OnApplicantsChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMessage.Informs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceNoticeChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActivityBattleDataChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMemberDataChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfosChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedVillage))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedOwnVillage))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedPass))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedOwnPass))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedBehemothCage))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedOwnBehemothCage))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceCurrency.Currency.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceCurrencyUpdate))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTechnology.MarkTechnology.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTechMarkDataChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTechnology.TechnologyData.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTechDataChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.NormalDonateTimes.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerDonateTimesChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.PlayerAllianceWrapper.PlayerAllianceRecommend.RecommendAlliances.MsgPath, Delegate.GetOrCreate(self, self.OnRecommendAllianceChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMessage.MapLabels.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceLabelDataChanged))
        -- g_Game.ServiceManager:AddResponseCallback(ProtocolId.NewAllianceInvitation, Delegate.GetOrCreate(self, self.OnServerPushNewAllianceInvitation)) -- 2023.12 策划并不知道之前有这个功能，让服务器开发了一套新的，见PushCanJoinAlliances
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachStatusChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.AgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachVoteChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.DisAgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachVoteChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.NumGifts.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerGiftChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.NumHelps.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerHelpNumChanged))
        g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushCanJoinAlliances, Delegate.GetOrCreate(self, self.OnServerPushCanJoinAlliances))
        g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncAllianceHelp, Delegate.GetOrCreate(self, self.OnServerPushAllianceHelpd))
        g_Game.ServiceManager:AddResponseCallback(ProtocolId.AllianceConveneMoveCityNotify, Delegate.GetOrCreate(self, self.OnConveneNotify))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.BasicInfo.IsInAllianceCenter.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerCastleInAllianceRangeChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMapBuildingChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.NextGetDailyFactionRewardTime.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerCastleInAllianceRangeChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.InviteAllianceIDs.MsgPath, Delegate.GetOrCreate(self, self.OnInviteAllianceIDsChanged))
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    else
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMapBuildingChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.BasicInfo.IsInAllianceCenter.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerCastleInAllianceRangeChanged))
        g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncAllianceHelp, Delegate.GetOrCreate(self, self.OnServerPushAllianceHelpd))
        g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushCanJoinAlliances, Delegate.GetOrCreate(self, self.OnServerPushCanJoinAlliances))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.NumHelps.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerHelpNumChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.NumGifts.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerGiftChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.PlayerAllianceWrapper.PlayerAllianceRecommend.RecommendAlliances.MsgPath, Delegate.GetOrCreate(self, self.OnRecommendAllianceChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.DisAgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachVoteChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.AgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachVoteChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceImpeachStatusChanged))
        -- g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.NewAllianceInvitation, Delegate.GetOrCreate(self, self.OnServerPushNewAllianceInvitation))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMessage.MapLabels.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceLabelDataChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.NormalDonateTimes.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerDonateTimesChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTechnology.TechnologyData.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTechDataChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTechnology.MarkTechnology.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTechMarkDataChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceCurrency.Currency.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceCurrencyUpdate))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedVillage))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedOwnVillage))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedPass))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedOwnPass))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedBehemothCage))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarSiegeChangedOwnBehemothCage))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfosChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMemberDataChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActivityBattleDataChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMessage.Informs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceNoticeChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceApplicants.Applicants.MsgPath, Delegate.GetOrCreate(self, self.OnApplicantsChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.NextGetDailyFactionRewardTime.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerCastleInAllianceRangeChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.InviteAllianceIDs.MsgPath, Delegate.GetOrCreate(self, self.OnInviteAllianceIDsChanged))
        g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Alliance, Delegate.GetOrCreate(self, self.OnNewAllianceEntity))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceChanged))
        g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.NotifyApplyResult, Delegate.GetOrCreate(self, self.OnNotifyApplyResult))
        g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.AllianceConveneMoveCityNotify, Delegate.GetOrCreate(self, self.OnConveneNotify))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_FIND_NEXT_RECRUIT_TOP_INFO, Delegate.GetOrCreate(self, self.OnFindNextRecruitTopInfo))
        g_Game.EventManager:RemoveListener(EventConst.HUD_BOTTOM_RIGHT_SUB_BUTTON_CLICK, Delegate.GetOrCreate(self, self.OnHudButtonClick))
    end
end

---@param playerId number
function AllianceModule:SetPlayerId(playerId)
    self._allianceId = 0
    self._cachedAllianceRank = 1
    self._playerId = playerId
    self._memberCountDirty = true
end

function AllianceModule:DoUpdateAllianceId()
    self._allianceId = 0
    g_Game.DatabaseManager.SetAllianceIdForDebug(nil)
    self._triggerJoinAllianceNewEntityId = nil
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return
    end
    local owner = player.Owner
    if not owner then
        return
    end
    self._allianceId = owner.AllianceID or 0
    self._cachedAllianceRank = owner.AllianceRank or 1
    self._memberCountDirty = true
    self.Behemoth:OnAllianceDataReady()
    self:GenerateNotifyData()
    g_Game.DatabaseManager.SetAllianceIdForDebug(owner.AllianceID)
end

function AllianceModule:GetAllianceId()
    return self._allianceId or nil
end

function AllianceModule:GetNextAllianceCreationTime()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return (player.PlayerAlliance.NextCreateAllianceTime or {}).Seconds or 0
end

function AllianceModule:IsAllianceCreationInCD()
    return self:GetNextAllianceCreationTime() > g_Game.ServerTime:GetServerTimestampInSeconds()
end

function AllianceModule:IsAllianceEntryUnLocked()
    if not self._allianceEntryUnlockId or self._allianceEntryUnlockId == 0 then return true end
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(self._allianceEntryUnlockId)
end

function AllianceModule:IsAllianceHelpUnlocked()
    local id = ConfigRefer.AllianceConsts:HelpFunctionUnlockEntry()
    if not id or id <= 0 then return true end
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(id)
end

function AllianceModule:IsInAlliance()
    return self._allianceId and self._allianceId > 0
end

function AllianceModule:IsAllianceLeader()
    return self:IsInAlliance() and ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank == AllianceModuleDefine.LeaderRank
end

function AllianceModule:IsAllianceR4Above()
    return self:IsInAlliance() and ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank >= AllianceModuleDefine.OfficerRank
end

function AllianceModule:IsAtOrAboveRank(rank)
    if not rank then return false end
    return self:IsInAlliance() and ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank >= rank
end

function AllianceModule:IsInBattleActivityWar()
    if not self:IsInAlliance() then
        return false
    end
    local myAllianceData = self:GetMyAllianceData()
    if not myAllianceData then
        return false
    end
    if myAllianceData.AllianceActivityBattles and myAllianceData.AllianceActivityBattles.Battles then
        local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
        for _, v in pairs(myAllianceData.AllianceActivityBattles.Battles) do
            if v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
                if v.Members and v.Members[selfFacebookId] then
                    return true
                end
            end
        end
    end
    return false
end

---@param battleId number
---@return wds.AllianceActivityBattleInfo
function AllianceModule:GetAllianceActivityBattleData(battleId)
    if not self:IsInAlliance() then
        return nil
    end
    local data = self:GetMyAllianceData()
    return data and data.AllianceActivityBattles and data.AllianceActivityBattles.Battles and data.AllianceActivityBattles.Battles[battleId]
end

---@return wds.Alliance|nil
function AllianceModule:GetMyAllianceData()
    if not self:IsInAlliance() then
        return nil
    end
    return g_Game.DatabaseManager:GetEntity(self._allianceId, DBEntityType.Alliance)
end

local EmptyDummy = {}

---@return wds.AllianceBasicInfo
function AllianceModule:GetMyAllianceBasicInfo()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceBasicInfo or nil
end

---@return wrpc.AllianceBriefInfo
function AllianceModule:GetMyAllianceBriefInfo()
    local allianceData = self:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceBasicInfo then return nil end
    local basic = allianceData.AllianceBasicInfo
    local ret = wrpc.AllianceBriefInfo.New(basic.ID, basic.Name, basic.Abbr, basic.Notice, nil, basic.Language, basic.JoinSetting, basic.LeaderID, basic.LeaderName ,basic.MemberCountCur, basic.MemberCountMax, basic.CurDistrictId, basic.Power)
    ret.Flag.BadgeAppearance = basic.Flag.BadgeAppearance
    ret.Flag.BadgePattern = basic.Flag.BadgePattern
    ret.Flag.TerritoryColor = basic.Flag.TerritoryColor
    return ret
end

---@return wds.AllianceBasicInfo
function AllianceModule:GetMyAllianceTerritoryColor()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceBasicInfo and allianceData.AllianceBasicInfo.Flag and allianceData.AllianceBasicInfo.Flag.TerritoryColor or 0
end

---@return wds.AllianceMembers|nil
function AllianceModule:GetMyAllianceMemberComp()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceMembers or nil
end

---@return table<number, wds.AllianceMember>
function AllianceModule:GetMyAllianceMemberDic()
    local comp = self:GetMyAllianceMemberComp()
    return comp and comp.Members or EmptyDummy
end

function AllianceModule:GetMyAllianceMemberOnlineCount()
    local members = self:GetMyAllianceMemberDic()
    if not members then return 1 end
    local ret = 0
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    for _, value in pairs(members) do
        if value.PlayerID == myPlayerId then
            ret = ret + 1
        elseif (value.LatestLoginTime and not value.LatestLogoutTime) then
            ret = ret + 1
        elseif value.LatestLoginTime and value.LatestLogoutTime and value.LatestLoginTime.ServerSecond > value.LatestLogoutTime.ServerSecond then
            ret = ret + 1
        end
    end
    return ret
end

---@return table<number, wds.AllianceApplicant>
function AllianceModule:GetMyAllianceApplicants()
    local allianceData = self:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceApplicants then
        return EmptyDummy
    end
    return allianceData.AllianceApplicants.Applicants or EmptyDummy
end

---@return wds.AllianceLogs|nil
function AllianceModule:GetMyAllianceLogs()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceLogs or nil
end

---@return wds.AllianceCurrencyLog[]
function AllianceModule:GetMyAllianceCurrencyLogs()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceCurrency and allianceData.AllianceCurrency.Logs or EmptyDummy
end

---@return table<number, wds.VillageAllianceWarInfo>
function AllianceModule:GetMyAllianceGateWars()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceWrapper.AllianceWarInfo.PassWar and allianceData.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar or EmptyDummy
end

---@return table<number, wds.VillageAllianceWarInfos>
function AllianceModule:GetMyAllianceOwnGateWar()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceWrapper.AllianceWarInfo.PassWar and allianceData.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar or EmptyDummy
end

---@return table<number, wds.VillageAllianceWarInfo>
function AllianceModule:GetMyAllianceVillageWars()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceVillageWar and allianceData.AllianceVillageWar.VillageWar or EmptyDummy
end

---@return table<number, wds.VillageAllianceWarInfos>
function AllianceModule:GetMyAllianceOwnVillageWar()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceVillageWar and allianceData.AllianceVillageWar.OwnVillageWar or EmptyDummy
end

---@return table<number, wds.VillageAllianceWarInfo>
function AllianceModule:GetMyAllianceBehemothCageWar()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceVillageWar and allianceData.AllianceWrapper.AllianceWarInfo and allianceData.AllianceWrapper.AllianceWarInfo.BehemothWar and allianceData.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar or EmptyDummy
end

---@return table<number, wds.VillageAllianceWarInfos>
function AllianceModule:GetMyAllianceOwnedBehemothCageWar()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceVillageWar and allianceData.AllianceWrapper.AllianceWarInfo and allianceData.AllianceWrapper.AllianceWarInfo.BehemothWar and allianceData.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar or EmptyDummy
end

---@return table<number, wds.MapBuildingBrief>
function AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.MapBuildingBriefs and allianceData.MapBuildingBriefs.MapBuildingBriefs or EmptyDummy
end

---@return wds.AllianceActivityBattleInfo|nil
function AllianceModule:GetMyAllianceActivityBattleById(battleId)
    local allianceData = self:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceActivityBattles or not allianceData.AllianceActivityBattles.Battles then
        return nil
    end
    return allianceData.AllianceActivityBattles.Battles[battleId]
end

---@return table<number, wds.AllianceMapLabel>
function AllianceModule:GetMyAllianceMapLabels()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceMessage and allianceData.AllianceMessage.MapLabels or EmptyDummy
end

---@return wds.AllianceMapLabel
function AllianceModule:GetMyAllianceMapLabel(id)
    return self:GetMyAllianceMapLabels()[id]
end

---@return wds.AllianceMapLabel
function AllianceModule:GetMyAllianceMapLabelByCfgId(cfgId)
    local labels = self:GetMyAllianceMapLabels()
    for k,v in pairs(labels) do
        if v.ConfigId == cfgId then
            return v
        end
    end
    return nil
end

---@return table<number, wds.AllianceInform>
function AllianceModule:GetMyAllianceInforms()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceMessage and allianceData.AllianceMessage.Informs or EmptyDummy
end

---@alias AllianceImpeachInfo {IsImpeach:boolean, ImpeacherFacebookId:number, ImpeacherName:string, ImpeachEndTime:google.protobuf.Timestamp, ImpeachNewLeaderFacebookId:number, ImpeachNewLeaderName:string, AgreeFbIds:table<number, google.protobuf.Timestamp>, DisAgreeFbIds:table<number, google.protobuf.Timestamp>}

---@return AllianceImpeachInfo
function AllianceModule:GetMyAllianceImpeachInfo()
    local allianceData = self:GetMyAllianceData()
    ---@type AllianceImpeachInfo
    local ret = {}
    ret.IsImpeach = false
    ret.ImpeacherFacebookId = 0
    ret.ImpeacherName = string.Empty
    ret.ImpeachEndTime = nil
    ret.ImpeachNewLeaderFacebookId = 0
    ret.ImpeachNewLeaderName = string.Empty
    ret.AgreeFbIds = {}
    ret.DisAgreeFbIds = {}
    local info = allianceData and allianceData.AllianceLeaderCtrl and allianceData.AllianceLeaderCtrl
    if info then
        ret.IsImpeach = info.IsImpeach
        ret.ImpeacherFacebookId = info.ImpeacherFacebookId
        ret.ImpeacherName = info.ImpeacherName
        ret.ImpeachEndTime = info.ImpeachEndTime
        ret.ImpeachNewLeaderFacebookId = info.ImpeachNewLeaderFacebookId
        ret.ImpeachNewLeaderName = info.ImpeachNewLeaderName
        table.merge(ret.AgreeFbIds, info.AgreeFbIds)
        table.merge(ret.DisAgreeFbIds, info.DisAgreeFbIds)
    end
    return ret
end

---@param playerFacebookId number
---@return wds.AllianceMember
function AllianceModule:QueryMyAllianceMemberData(playerFacebookId)
    local memberDic = self:GetMyAllianceMemberDic()
    return memberDic[playerFacebookId]
end

---@param playerId number
---@return wds.AllianceMember
function AllianceModule:QueryMyAllianceMemberDataByPlayerId(playerId)
    local allianceData = self:GetMyAllianceData()
    if not allianceData then
        return nil
    end
    for i, v in pairs(allianceData.AllianceMembers.Members) do
        if v.PlayerID == playerId then
            return v
        end
    end
    return nil
end

---@return table<number, wds.AllianceMember|nil>
function AllianceModule:QueryTitlesMember()
    local allianceMembers = self:GetMyAllianceMemberComp()
    if not allianceMembers or not allianceMembers.Titles then
        return EmptyDummy
    end
    local ret = {}
    for title, memberFacebookId in pairs(allianceMembers.Titles) do
        ret[title] = allianceMembers.Members[memberFacebookId]
    end
    return ret
end

---@return number,number @onlineCount,totalCount
function AllianceModule:GetMyAllianceMemberCount()
    if not self:IsInAlliance() then
       return 0, 0
    end
    local allianceMembers = self:GetMyAllianceMemberComp()
    if not allianceMembers then return 1 end
    return table.nums(allianceMembers.Members)
end

---@return number,number @onlineCount,totalCount
function AllianceModule:GetMyAllianceOnlineMemberCount()
    if not self:IsInAlliance() then
       return 0, 0
    end
    if self._memberCountDirty then
        self:UpdateMemberCountCache()
    end
    return self._onlineCount, self._totalCount
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceMemberDataChanged(entity, changedData)
    if not self:IsInAlliance() or self._allianceId ~= entity.ID then
        return
    end
    self._memberCountDirty = true
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarInfosChanged(entity, changedData)
    if not self:IsInAlliance() or self._allianceId ~= entity.ID then
        return
    end

    self:UpdateAllianceWarNotifyTabRally(ModuleRefer.NotificationModule, self:GetMyAllianceData())
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    local add,_ ,_ = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.AllianceTeamInfo)
    if add then
        for id, v in pairs(add) do
            local captainId = v.CaptainId
            local allianceMember = self:QueryMyAllianceMemberDataByPlayerId(captainId)
            if allianceMember then
                local target = v.TargetInfo
                local targetName = SlgUtils.GetNameIconPowerByConfigId(target.ObjectType, target.CfgId)
                if not string.IsNullOrEmpty(targetName) then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_team_toast01", allianceMember.Name, targetName))
                end
            end

            if captainId == myPlayerId then
                self:CheckAddAssembleInfoToChat(id, v)
            end
        end
    end
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChangedVillage(entity, changedData)
    self:OnAllianceWarSiegeChanged(entity, changedData, DBEntityType.Village)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChangedPass(entity, changedData)
    self:OnAllianceWarSiegeChanged(entity, changedData, DBEntityType.Pass)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChangedBehemothCage(entity, changedData)
    self:OnAllianceWarSiegeChanged(entity, changedData, DBEntityType.BehemothCage)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChangedOwnVillage(entity, changedData)
    self:OnAllianceOwnWarSiegeChanged(entity, changedData, DBEntityType.Village)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChangedOwnPass(entity, changedData)
    self:OnAllianceOwnWarSiegeChanged(entity, changedData, DBEntityType.Pass)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChangedOwnBehemothCage(entity, changedData)
    self:OnAllianceOwnWarSiegeChanged(entity, changedData, DBEntityType.BehemothCage)
end

---@param info wds.VillageAllianceWarInfo
---@return AllianceVillageWarInfoTipMediatorParameter
function AllianceModule:BuildWarInfoTipData(typeHash, id, info, useEndTime, isUnderAttack)
    ---@type AllianceVillageWarInfoTipMediatorParameter
    local showTipData = {}
    showTipData.infoId = id
    showTipData.typeHash = typeHash
    showTipData.villageId = info.VillageId
    showTipData.isUnderAttack = isUnderAttack
    showTipData.zeroTimeColor = ColorConsts.army_red
    showTipData.onclickGoTo = function()
        local keyMap = FPXSDKBIDefine.ExtraKey.alliance_info_banner
        local extraData = {}
        if typeHash == DBEntityType.Village then
            extraData[keyMap.type] = 0
        elseif typeHash == DBEntityType.Pass then
            extraData[keyMap.type] = 1
        elseif typeHash == DBEntityType.BehemothCage then
            extraData[keyMap.type] = 2
        end
        extraData[keyMap.alliance_id] = self:GetAllianceId()
        ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.alliance_info_banner, extraData)

        ---@type AllianceWarMediatorParameter
        local indexParameter = {}
        indexParameter.enterTabIndex = 2
        g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, indexParameter)
    end
    local isBehemothWar = false
    local territoryConfig = ConfigRefer.Territory:Find(info.TerritoryId)
    if territoryConfig then
        local villageBuildingConfig = ConfigRefer.FixedMapBuilding:Find(territoryConfig:VillageId())
        showTipData.icon = villageBuildingConfig and villageBuildingConfig:Image() or string.Empty
        if villageBuildingConfig and (villageBuildingConfig:SubType() == MapBuildingSubType.CageSubType1 or villageBuildingConfig:SubType() == MapBuildingSubType.CageSubType2) then
            isBehemothWar = true
        end
    end
    showTipData.endTime = useEndTime and info.EndTime or info.StartTime
    if info.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder then
        showTipData.content = I18N.Get("village_info_proxy_defender")
    elseif info.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction then
        showTipData.content = I18N.Get("village_info_proxy_defense")
    else
        if isBehemothWar then
            showTipData.content = I18N.Get("alliance_behemoth_cage_wait")
        else
            showTipData.content = I18N.Get("village_info_proxy_Preparing")
            showTipData.contentStart = I18N.Get("slg_warshow")
            showTipData.conutDown = 5
        end
    end

    return showTipData
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceWarSiegeChanged(entity, changedData, typeHash)
    if not self:IsInAlliance() or self._allianceId ~= entity.ID then
        return
    end
    self:UpdateAllianceWarNotifyTabSiege(ModuleRefer.NotificationModule, self:GetMyAllianceData())
    local add,remove ,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.VillageAllianceWarInfo)
    self:CheckAndSetBehemothCageWarStartNotify()
    self:CheckAndSetVillageOrPassWarStartCountDown(typeHash)
    self:CheckAndAddVillageWarStartNotify(typeHash)
    if remove then
        for i, _ in pairs(remove) do
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_WAR_INFO_REMOVED, i)
        end
    end
    if changed then
        ---@type {id:number,info:wds.VillageAllianceWarInfo}[]
        local t = {}
        for i, v in pairs(changed) do
                if v[1].Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare and v[2].Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                table.insert(t, {id=i, info=v[2]})
            end
        end
        table.sort(t, function(a, b)
            return a.info.EndTime < b.info.EndTime
        end)
        if #t > 0 then
            local info = t[1].info
            ---@type AllianceVillageWarInfoTipMediatorParameter
            local showTipData = self:BuildWarInfoTipData(typeHash, t[1].id, info, true)
            showTipData.checkVillageNoInView = true
            ModuleRefer.ToastModule:AddJumpToast(I18N.Get("village_toast_battle_has_begun"))
            self:OpenWarInfoTipInQueue(showTipData)
        end
    end
    if add then
        ---@type {id:number,info:wds.VillageAllianceWarInfo}[]
        local t = {}
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        for i, v in pairs(add) do
            if v.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                if v.StartTime > nowTime then
                    table.insert(t, {id=i, info=v})
                end
            end
        end
        table.sort(t, function(a, b)
            return a.info.StartTime < b.info.StartTime
        end)
        if #t > 0 then
            local info = t[1].info
            ---@type AllianceVillageWarInfoTipMediatorParameter
            local showTipData = self:BuildWarInfoTipData(typeHash, t[1].id, info, false)
            showTipData.checkVillageNoInView = true
            self:OpenWarInfoTipInQueue(showTipData)
        end
    end
end

---@param queue AllianceVillageWarInfoTipMediatorParameter[]
---@param nowTime number
---@param warTable table<number, wds.VillageAllianceWarInfo>
---@param typeHash number
function AllianceModule:AppendToQueueForVillageWarInfoTipCountdown(queue, nowTime, warTable, typeHash)
    for id, warInfo in pairs(warTable) do
        if warInfo.Status ==  wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            local startTimeCountdown = warInfo.StartTime - 5
            if startTimeCountdown > nowTime then
                ---@type AllianceVillageWarInfoTipMediatorParameter
                local info = self:BuildWarInfoTipData(typeHash, id, warInfo)
                info.delayStartTime = startTimeCountdown
                table.insert(queue, info)
            end
        end
    end
end

---@param a AllianceVillageWarInfoTipMediatorParameter
---@param b AllianceVillageWarInfoTipMediatorParameter
function AllianceModule.SortForVillageWarCountDownInfoTip(a, b)
    return a.delayStartTime < b.delayStartTime
end

function AllianceModule:CheckAndAddVillageWarStartNotify(typeHash)
    if typeHash ~= DBEntityType.Village and typeHash ~= DBEntityType.Pass and typeHash ~= DBEntityType.BehemothCage then return end
    local queue = self._tickVillageWarStartNotifyTipCountQueue
    for index = #queue, 1, -1 do
        local info = queue[index]
        if info.typeHash == typeHash then
            table.remove(queue, index)
        end
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local warTable
    if typeHash == DBEntityType.Village then
        warTable = self:GetMyAllianceVillageWars()
    elseif typeHash == DBEntityType.Pass then
        warTable = self:GetMyAllianceGateWars()
    elseif typeHash == DBEntityType.BehemothCage then
        warTable = self:GetMyAllianceBehemothCageWar()
    end
    self:AppendToQueueForVillageWarInfoTipCountdown(queue, nowTime, warTable, typeHash)
    table.sort(queue, AllianceModule.SortForVillageWarCountDownInfoTip)
end

--提前两分钟提醒
AllianceModule.PreNotifyStartBehemothCageWar = 60 * 2

function AllianceModule:CheckAndSetBehemothCageWarStartNotify()
    self._tickCheckBehemothCageWarStart = nil
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local pTime = AllianceModule.PreNotifyStartBehemothCageWar 
    local behemothCageWars = self:GetMyAllianceBehemothCageWar()
    for _, value in pairs(behemothCageWars) do
        if value.EndTime > nowTime and value.StartTime > nowTime then
            local notifyTime = value.StartTime - pTime
            if notifyTime > nowTime then
                if not self._tickCheckBehemothCageWarStart or self._tickCheckBehemothCageWarStart > notifyTime then
                    self._tickCheckBehemothCageWarStart = notifyTime
                end
            end
        end
    end
end

function AllianceModule:TickOnCheckBehemothCageStart(nowTime)
    if not self._tickCheckBehemothCageWarStart then return end
    if self._tickCheckBehemothCageWarStart >= nowTime then return end
    self._tickCheckBehemothCageWarStart = nil
    local behemothCageWars = self:GetMyAllianceBehemothCageWar()
    local pTime = AllianceModule.PreNotifyStartBehemothCageWar
    ---@type wds.VillageAllianceWarInfo
    local chooseNotify = nil
    local chooseId = nil
    local chooseNotifyTime = nil
    for id, value in pairs(behemothCageWars) do
        local notifyTime = value.StartTime - pTime
        if value.EndTime > nowTime and value.StartTime > nowTime and notifyTime < nowTime then
            if not chooseNotifyTime or notifyTime > chooseNotifyTime then
                chooseNotify = value
                chooseId = id
            end
        end
    end
    if not chooseNotify then return end
    local info = chooseNotify
    ---@type AllianceVillageWarInfoTipMediatorParameter
    local showTipData = {}
    showTipData.infoId = chooseId
    showTipData.villageId = info.VillageId
    showTipData.onclickGoTo = function()
        ---@type AllianceWarMediatorParameter
        local indexParameter = {}
        indexParameter.enterTabIndex = 2
        g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, indexParameter)
    end
    local territoryConfig = ConfigRefer.Territory:Find(info.TerritoryId)
    if territoryConfig then
       local villageBuildingConfig = ConfigRefer.FixedMapBuilding:Find(territoryConfig:VillageId())
        showTipData.icon = villageBuildingConfig and villageBuildingConfig:Image() or string.Empty
    end
    showTipData.endTime = info.StartTime
    showTipData.content = I18N.Get("alliance_behemoth_cage_wait")
    self:OpenWarInfoTipInQueue(showTipData)
end

---@param a VillageWarCountDownInfo
---@param b VillageWarCountDownInfo
function AllianceModule.SortForVillageWarCountDownInfo(a, b)
    return a.startCountdonwTime < b.startCountdonwTime
end

---@param queue VillageWarCountDownInfo[]
---@param nowTime number
---@param warTable table<number, wds.VillageAllianceWarInfo>
---@param typeHash number
function AllianceModule.AppendToQueueForVillageWarCountdown(queue, nowTime, warTable, typeHash)
    for id, warInfo in pairs(warTable) do
        if warInfo.Status ==  wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            local startTimeCountdown = warInfo.StartTime - 6
            if startTimeCountdown > nowTime then
                ---@type VillageWarCountDownInfo
                local info = {}
                info.typeHash = typeHash
                info.id = id
                info.startCountdonwTime = startTimeCountdown
                info.warInfo = warInfo
                table.insert(queue, info)
            end
        end
    end
end

function AllianceModule:CheckAndSetVillageOrPassWarStartCountDown(typeHash)
    if typeHash ~= DBEntityType.Village and typeHash ~= DBEntityType.Pass then return end
    local queue = self._tickVillageWarStartCountDownQueue
    for index = #queue, 1, -1 do
        local info = queue[index]
        if info.typeHash == typeHash then
            table.remove(queue, index)
        end
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local warTable
    if typeHash == DBEntityType.Village then
        warTable = self:GetMyAllianceVillageWars()
    elseif typeHash == DBEntityType.Pass then
        warTable = self:GetMyAllianceGateWars()
    end
    AllianceModule.AppendToQueueForVillageWarCountdown(queue, nowTime, warTable, typeHash)
    table.sort(queue, AllianceModule.SortForVillageWarCountDownInfo)
end

function AllianceModule:TickOnVillageWarStart(nowTime)
    local info = self._tickVillageWarStartCountDownQueue[1]
    if not info then return end
    if info.startCountdonwTime >= nowTime then return end
    table.remove(self._tickVillageWarStartCountDownQueue, 1)
    if info.warInfo.StartTime <= nowTime then return end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene or scene:GetName() ~= "KingdomScene" or not scene:InKingdomLod() then
        return
    end
    local id,typeHash = ModuleRefer.VillageModule:GetCurrentInViewVillage()
    if info.warInfo.VillageId ~= id or info.typeHash ~= typeHash then return end
    ---@type CountdownToastMediatorParamter
    local param = {}
    param.startCountdownTime = info.startCountdonwTime
    param.countdown = info.warInfo.StartTime - param.startCountdownTime
    param.content = I18N.Get("alliance_city_fighting3")
    param.startText = I18N.Get("slg_warshow")
    ModuleRefer.ToastModule:ShowCountdownToast(param)
end

function AllianceModule:TickOnVillageWarInfoTipStart(nowTime)
    local info = self._tickVillageWarStartNotifyTipCountQueue[1]
    if not info then return end
    if info.delayStartTime >= nowTime then return end
    table.remove(self._tickVillageWarStartNotifyTipCountQueue, 1)
    if info.endTime <= nowTime then return end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene or scene:GetName() ~= "KingdomScene" or not (KingdomMapUtils.IsCityState() or KingdomMapUtils.IsMapState()) then
        return
    end
    local id,typeHash = ModuleRefer.VillageModule:GetCurrentInViewVillage()
    if info.villageId == id or info.typeHash == typeHash then return end
    self:OpenWarInfoTipInQueue(info)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceOwnWarSiegeChanged(entity, changedData, typehash)
    if not self:IsInAlliance() or self._allianceId ~= entity.ID then
        return
    end
    self:UpdateAllianceWarNotifyTabSiege(ModuleRefer.NotificationModule, self:GetMyAllianceData())
    if not changedData then
        return
    end
    local outerAdd,outerRemove,_ = OnChangeHelper.GenerateMapComponentFieldChangeMap(changedData, wds.VillageAllianceWarInfos)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if outerRemove then
        for _, infos in pairs(outerRemove) do
            if infos.WarInfo then
                for key, _ in pairs(infos.WarInfo) do
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_WAR_INFO_REMOVED, key)
                end
            end
        end
    end
    local addT = {}
    if outerAdd then
        for _, v in pairs(outerAdd) do
            if v.WarInfo then
                for i, warInfo in pairs(v.WarInfo) do
                    if warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                        if warInfo.StartTime > nowTime then
                            ---@type {id:number,info:wds.VillageAllianceWarInfo}
                            local t = {}
                            t.id = i
                            t.info = warInfo
                            table.insert(addT, t)
                        end
                    end
                end
            end
        end
    end
    for _, v in pairs(changedData) do
        if v.WarInfo then
            local add,remove,_ = OnChangeHelper.GenerateMapFieldChangeMap(v.WarInfo, wds.VillageAllianceWarInfo)
            if remove then
                for i, _ in pairs(remove) do
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_WAR_INFO_REMOVED, i)
                end
            end
            if add then
                for i, addContent in pairs(add) do
                    if (not outerAdd or (not outerAdd[i])) and addContent.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                        if addContent.StartTime > nowTime then
                            ---@type {id:number,info:wds.VillageAllianceWarInfo}[]
                            local t = {}
                            t.id = i
                            t.info = addContent
                            table.insert(addT, t)
                        end
                    end
                end
            end
        end
    end
    table.sort(addT, function(a, b)
        return a.info.StartTime < b.info.StartTime
    end)
    if #addT > 0 then
        local info = addT[1].info
        ---@type AllianceVillageWarInfoTipMediatorParameter
        local showTipData = self:BuildWarInfoTipData(typehash, addT[1].id, info, false, true)
        self:OpenWarInfoTipInQueue(showTipData)
    end
end

function AllianceModule:OpenWarInfoTipInQueue(openParam)
    g_Game.UIManager:CloseByName(UIMediatorNames.AllianceVillageWarInfoTipMediator)
    local UIAsyncDataProvider = require("UIAsyncDataProvider")
    ---@type UIAsyncDataProvider
    local provider = UIAsyncDataProvider.new()
    local mediatorName = UIMediatorNames.AllianceVillageWarInfoTipMediator
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
    provider:Init(mediatorName, nil, check, nil, false, openParam)
    provider:SetOtherMediatorCheckType(UIAsyncDataProvider.MediatorTypes.Dialog)
    g_Game.UIAsyncManager:AddAsyncMediator(provider)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceCurrencyUpdate(entity, changedData)
    if not self:IsInAlliance() or self._allianceId ~= entity.ID or not changedData then
        return
    end
    local notifyIdMap = {}
    local notifyTypeMap = {}
    if changedData.Add then
        for i, v in pairs(changedData.Add) do
            notifyIdMap[i] = true
            local type = self:GetAllianceCurrencyTypeById(i)
            if type then
                notifyTypeMap[type] = true
            end
        end
    end
    if changedData.Remove then
        for i, v in pairs(changedData.Remove) do
            notifyIdMap[i] = true
            local type = self:GetAllianceCurrencyTypeById(i)
            if type then
                notifyTypeMap[type] = true
            end
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, notifyIdMap)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_CURRENCY_UPDATED_TYPES, notifyTypeMap)
end

function AllianceModule:UpdateMemberCountCache()
    local myAlliance = self:GetMyAllianceData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not myAlliance or not player then
        return
    end
    local myFbId = player.Owner.FacebookID
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self._onlineCount = 0
    self._totalCount = 0
    local member = myAlliance.AllianceMembers.Members
    for _, v in pairs(member) do
        if v.FacebookID == myFbId then
            self._onlineCount = self._onlineCount + 1
        else
            if v.LatestLoginTime and v.LatestLoginTime.Seconds < nowTime then
                if not v.LatestLogoutTime or v.LatestLogoutTime.Seconds < v.LatestLoginTime.Seconds then
                    self._onlineCount = self._onlineCount + 1
                end
            end
        end
        self._totalCount = self._totalCount + 1
    end
    self._memberCountDirty = false
end

function AllianceModule:MemberHasTitle(memberFacebookId)
    local allianceData = self:GetMyAllianceData()
    if not allianceData then
        return nil
    end
    for _, v in pairs(allianceData.AllianceMembers.Titles) do
        if v == memberFacebookId then
            return true
        end
    end
    return nil
end

function AllianceModule:QueryChangeTitleCdEndTime()
    --todo need server impl
    return 0
end

---@return number @-1 is no limits
function AllianceModule:GetRankNumberLimit(rank)
    local cfg = ConfigRefer.AllianceRank:Find(rank)
    return cfg and cfg:NumLimit() or 0
end

---@return number,number @ cur,max -1 is no limits
function AllianceModule:GetMyAllianceRank2Number(rank)
    local allianceData = self:GetMyAllianceData()
    if not allianceData then
        return 0,0
    end
    local cfg = ConfigRefer.AllianceRank:Find(rank)
    return allianceData.AllianceMembers.Rank2MemberNum[rank] or 0, cfg and cfg:NumLimit() or 0
end

---@param param any
function AllianceModule:OnHudButtonClick(param)
    if not param then
        return
    end
    if AllianceModuleDefine.UIEntry.ALLIANCE_HUD_ENTRY_CLICK == param then
        if self:IsInAlliance() then
            g_Game.UIManager:Open(UIMediatorNames.AllianceMainMediator)
        else
            g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
        end
    end
end

function AllianceModule:OnFindNextRecruitTopInfo(index)
    if UNITY_DEBUG or UNITY_EDITOR then
        local block = (g_Game.PlayerPrefsEx:GetInt("BlockRecommandToastKey") or 0) > 0
        if block then return end
    end
    local city = ModuleRefer.CityModule:GetMyCity()
    if city and (city:IsInSingleSeExplorerMode() or city:IsInSeBattleMode() or city:IsInRecoverZoneEffectMode()) then
        return
    end
    ---@type CommonNotifyPopupMediatorParameter
    local data = {}
    ---@type AllianceRecruitTopToastParameter
    local allianceInfo = {}
    allianceInfo.index = index
    allianceInfo.infos = self._cachedAllianceRecruitTopInfos
    if not allianceInfo.infos or not allianceInfo.infos[index] then return end
    allianceInfo.allianceDetailFunc = function()
        g_Game.UIAsyncManager:CancelMediatorsByName(UIMediatorNames.CommonNotifyPopupMediator)
        if not allianceInfo.infos or not allianceInfo.infos[index] then return end
        g_Game.UIManager:Open(UIMediatorNames.AllianceJoinMediator, {targetAllianceName = allianceInfo.infos[index].Name})
        table.clear(self._cachedAllianceRecruitTopInfos)
    end
    allianceInfo.allianceJoinFunc = function (lockable)
        g_Game.UIAsyncManager:CancelMediatorsByName(UIMediatorNames.CommonNotifyPopupMediator)
        if not allianceInfo.infos or not allianceInfo.infos[index] then return end
        self:JoinOrApplyAlliance(lockable, allianceInfo.infos[index].ID, function(cmd, isSuccess, rsp)
            if isSuccess then
                if allianceInfo.infos[index].JoinSetting == AllianceModuleDefine.JoinNeedApply then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("applied"))
                else
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_add_desc"))
                end
                table.clear(self._cachedAllianceRecruitTopInfos)
            end
        end)
    end
    data.allianceInfo = allianceInfo
    data.funcType = ToastFuncType.AllianceRecruitTop
    TimerUtility.DelayExecute(function()
        if table.IsNullOrEmpty(self._cachedAllianceRecruitTopInfos) then
            return
        end
        if self:IsInAlliance() then
            table.clear(self._cachedAllianceRecruitTopInfos)
            return
        end
        local UIAsyncDataProvider = require("UIAsyncDataProvider")
        ---@type UIAsyncDataProvider
        local provider = UIAsyncDataProvider.new()
        local check = UIAsyncDataProvider.CheckTypes.CheckAll
        provider:Init(UIMediatorNames.CommonNotifyPopupMediator, nil, check, nil, false, data)
        provider:AddOtherMediatorBlackList(UIMediatorNames.CommonNotifyPopupMediator)
        provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
        provider:AddOtherMediatorBlackList(UIMediatorNames.CitySeExplorerHudUIMediator)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end, 3)
end

---@private
---@param entity wds.Player
---@param _ any
function AllianceModule:OnPlayerAllianceChanged(entity, _)
    if not entity or entity.ID ~= self._playerId then
        return
    end
    local lastAllianceId = self._allianceId
    local lastRank = self._cachedAllianceRank
    self:DoUpdateAllianceId()
    if self._allianceId ~= lastAllianceId and self._allianceId > 0 then
        self:ClearAllNoticeNodes()
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_JOINED, self._allianceId)
        local allianceData = self:GetMyAllianceData()
        if allianceData then
            self.Behemoth:OnAllianceDataReady()
            self:GenerateNotifyData()
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, self._allianceId, allianceData)
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BATTLE_HUD_REFRESH)
            ModuleRefer.GuideModule:CheckFirstJoinAllianceRelocateGuide()
        else
            self._triggerJoinAllianceNewEntityId = self._allianceId
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, self:GetAllianceId())
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BATTLE_HUD_REFRESH)
        end
    elseif lastAllianceId > 0 and self._allianceId <= 0 then
        self._tickCheckBehemothCageWarStart = nil
        table.clear(self._cachedAllianceLabel)
        table.clear(self._tickVillageWarStartCountDownQueue)
        table.clear(self._tickVillageWarStartNotifyTipCountQueue)
        self:ClearAllNoticeNodes()
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_LEAVED, lastAllianceId)
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, lastAllianceId)
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BATTLE_HUD_REFRESH)
    end
    if lastRank ~= self._cachedAllianceRank then
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_RANK_CHANGED, lastRank, self._cachedAllianceRank)
    end
end

---@param entityType number
---@param entity wds.Alliance
function AllianceModule:OnNewAllianceEntity(entityType, entity)
    if entityType ~= DBEntityType.Alliance then
        return
    end
    if not entity then
        return
    end
    if not self._triggerJoinAllianceNewEntityId or self._triggerJoinAllianceNewEntityId ~= entity.ID then
        return
    end
    self._triggerJoinAllianceNewEntityId = nil
    self:ClearAllNoticeNodes()
    self.Behemoth:OnAllianceDataReady()
    self:GenerateNotifyData()
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, self._allianceId, entity)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BATTLE_HUD_REFRESH)
    ModuleRefer.GuideModule:CheckFirstJoinAllianceRelocateGuide()
end

---@param isSuccess boolean
---@param rsp wrpc.NotifyApplyResultRequest
function AllianceModule:OnNotifyApplyResult(isSuccess, rsp)
    if isSuccess then
        if rsp then
            if string.IsNullOrEmpty(rsp.ApproverName) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("join_toast", rsp.AllianceName))
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(rsp.Agree and "apply_approve_toast" or "apply_reject_toast", rsp.ApproverName))
            end
        end
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("apply_failed_toast"))
    end
end

---@param isSuccess boolean
---@param rsp wrpc.AllianceConveneMoveCityNotifyRequest
---@field public Pos wds.Vector3F
---@field public PlayerId number
---@field public PlayerName string
function AllianceModule:OnConveneNotify(isSuccess, rsp)
    if isSuccess then
        local str = "X:"..math.floor(rsp.Pos.X)..",Y:"..math.floor(rsp.Pos.Y)
        ---@type CommonConfirmPopupMediatorParameter
        local data = {}
        data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        data.title = I18N.Get("alliance_gathering_point_8")
        data.content = I18N.GetWithParams("alliance_gathering_point_5",rsp.PlayerName,str)
        data.confirmLabel = I18N.Get("world_qianwang")
        data.onConfirm = function(context)
            --TODO: 前往查看
            local conveneLabelId = ConfigRefer.AllianceConsts:AllianceConveneLabel()
            local label = self:GetMyAllianceMapLabelByCfgId(conveneLabelId)
            if label then
                local x, z = KingdomMapUtils.ParseCoordinate(label.X, label.Y)
                local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, z, KingdomMapUtils.GetMapSystem())
                g_Game.UIManager:CloseByName(UIMediatorNames.AllianceMainMediator)
                local scene = g_Game.SceneManager.current
                if scene:IsInCity() then
                    local callback = function()
                        ModuleRefer.WorldEventModule:GotoPos(pos)
                    end
                    scene:LeaveCity(callback)
                else
                    ModuleRefer.WorldEventModule:GotoPos(pos)
                end
            else

            end
            return true
        end

        local UIAsyncDataProvider = require("UIAsyncDataProvider")
        local provider = UIAsyncDataProvider.new()
		local name = UIMediatorNames.CommonConfirmPopupMediator
		local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
		local checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
		provider:Init(name, nil, check, checkFailedStrategy, false, data)
		provider:SetOtherMediatorCheckType(0)
		provider:AddOtherMediatorBlackList(UIMediatorNames.SEPetSettlementMediator)
		g_Game.UIAsyncManager:AddAsyncMediator(provider)
        end
end

---@private
function AllianceModule:GenerateNotifyData()
    local notificationModule = ModuleRefer.NotificationModule
    local root = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Main, NotificationType.ALLIANCE_ENTRANCE)
    local warNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.War, NotificationType.ALLIANCE_MAIN_WAR)
    local memberNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Member, NotificationType.ALLIANCE_MAIN_MEMBER)
    local otherNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Other, NotificationType.ALLIANCE_MAIN_OTHER)
    local shopNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Shop, NotificationType.ALLIANCE_MAIN_SHOP)
    local needJoinNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.NeedJoin, NotificationType.ALLIANCE_MAIN_ENTRANCE_NEED_JOIN)
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Notice, NotificationType.ALLIANCE_MAIN_NOTICE)
    local territoryNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Territory, NotificationType.ALLIANCE_MAIN_TERRITORY)
    local techNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Tech, NotificationType.ALLIANCE_MAIN_TECH_ENTRY)
    local techNode_update = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechUpdate, NotificationType.ALLIANCE_MAIN_TECH_ENTRY_UPDATE)
    local impeachNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.ImpeachmentEntry, NotificationType.ALLIANCE_MAIN_IMPEACHMENT_ENTRY)
    local giftNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.GiftEntry, NotificationType.ALLIANCE_MAIN_GIFT_ENTRY)
    local helpNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.HelpEntry, NotificationType.ALLIANCE_MAIN_HELP_ENTRY)
    local behemothNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.BehemothEntry, NotificationType.ALLIANCE_MAIN_BEHEMOTH_ENTRY)
    local dailyGift = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TerritoryDailyGift, NotificationType.ALLIANCE_TERRITORY_DAILY_GIFT)

    notificationModule:AddToParent(warNode, root)
    notificationModule:AddToParent(memberNode, root)
    notificationModule:AddToParent(otherNode, root)
    notificationModule:AddToParent(shopNode, root)
    notificationModule:AddToParent(noticeNode, root)
    notificationModule:AddToParent(territoryNode, root)
    notificationModule:AddToParent(techNode, root)
    notificationModule:AddToParent(techNode_update, root)
    notificationModule:AddToParent(impeachNode, root)
    notificationModule:AddToParent(giftNode, root)
    notificationModule:AddToParent(helpNode, root)
    notificationModule:AddToParent(behemothNode, root)
    notificationModule:AddToParent(dailyGift, root)

    local warTabNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabRally, NotificationType.ALLIANCE_WAR_TAB_RALLY)
    notificationModule:AddToParent(warTabNode, warNode)
    warTabNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabWar, NotificationType.ALLIANCE_WAR_TAB_WAR)
    notificationModule:AddToParent(warTabNode, warNode)
    warTabNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabSiege, NotificationType.ALLIANCE_WAR_TAB_SIEGE)
    notificationModule:AddToParent(warTabNode, warNode)
    
    local memberAppliesNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.MemberApplies, NotificationType.ALLIANCE_MEMBER_APPLIES_SELECTION)
    notificationModule:AddToParent(memberAppliesNode, memberNode)
    
    local techTabNode_alliance =  notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabAlliance, NotificationType.ALLIANCE_TECH_MAIN_TAB_ALLIANCE)
    local techTabNode_production =  notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabProduction, NotificationType.ALLIANCE_TECH_MAIN_TAB_PRODUCTION)
    local techTabNode_fight =  notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabFight, NotificationType.ALLIANCE_TECH_MAIN_TAB_FIGHT)

    local behemothListNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.BehemothListEntry, NotificationType.ALLIANCE_BEHEMOTH_LIST_ENTRY)
    notificationModule:AddToParent(behemothListNode, behemothNode)
    
    if not self:IsInAlliance() then
        notificationModule:SetDynamicNodeNotificationCount(otherNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(shopNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(needJoinNode, 1)
        notificationModule:SetDynamicNodeNotificationCount(memberAppliesNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(techNode_update, 0)
        notificationModule:SetDynamicNodeNotificationCount(techTabNode_alliance, 0)
        notificationModule:SetDynamicNodeNotificationCount(techTabNode_production, 0)
        notificationModule:SetDynamicNodeNotificationCount(techTabNode_fight, 0)
        notificationModule:SetDynamicNodeNotificationCount(impeachNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(giftNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(helpNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(dailyGift, 0)
        self:ClearAllNoticeNodes()
        self:ClearAllTerritoryNodes()
        self:ClearAllAllianceWarNotify()
        self:ClearAllAllianceTechNotify()
        self:ClearAllAllianceLabelUnReadNotify()
        self.Behemoth:GenerateNotify()
    else
        notificationModule:SetDynamicNodeNotificationCount(otherNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(shopNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(needJoinNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(memberAppliesNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(impeachNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(giftNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(helpNode, 0)
        notificationModule:SetDynamicNodeNotificationCount(dailyGift, 0)

        local allianceData = self:GetMyAllianceData()
        local player = ModuleRefer.PlayerModule:GetPlayer()
        
        self:UpdateNotifyAll(notificationModule, memberAppliesNode)
        self:UpdateNoticeNotify(notificationModule, noticeNode)
        self:UpdateTerritoryNotifyAll(notificationModule, territoryNode, allianceData)
        self:UpdateAllianceWarNotifyAll(notificationModule, warNode)
        self:UpdateAllianceTechUpdateNotify(notificationModule, allianceData)
        self:UpdateAllianceDonateNotify()
        self:UpdateAllianceTechNotify(notificationModule, allianceData)
        self:UpdateAllianceTechEntryNotifyCount()
        self:UpdateAllianceLabelUnReadNotify()
        self:UpdateImpeachEntryNotify()
        self:UpdateGiftEntryNotify(player)
        self:OnPlayerHelpNumChanged(player, _)
        self.Behemoth:GenerateNotify()
        table.clear(self._cachedAllianceLabel)
        if allianceData then
            for id, label in pairs(allianceData.AllianceMessage.MapLabels) do
                self._cachedAllianceLabel[id] = label
            end
            self:CheckAndSetVillageOrPassWarStartCountDown(DBEntityType.Village)
            self:CheckAndSetVillageOrPassWarStartCountDown(DBEntityType.Pass)
            self:CheckAndAddVillageWarStartNotify(DBEntityType.Village)
            self:CheckAndAddVillageWarStartNotify(DBEntityType.Pass)
            self:CheckAndAddVillageWarStartNotify(DBEntityType.BehemothCage)
        end
    end
    self:OnInviteAllianceIDsChanged()
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, self:GetAllianceId())
end

function AllianceModule:ClearAllNoticeNodes()
    local notificationModule = ModuleRefer.NotificationModule
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Notice, NotificationType.ALLIANCE_MAIN_NOTICE)
    for _, node in pairs(self._noticeNodes) do
        notificationModule:RemoveFromParent(node, noticeNode)
        node:Dispose()
    end
    table.clear(self._noticeNodes)
    AllianceModuleDefine.ClearLastNoticeSaveTime()
end

function AllianceModule:ClearAllTerritoryNodes()
    
end

function AllianceModule:ClearAllAllianceWarNotify()
    local notificationModule = ModuleRefer.NotificationModule
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabRally, NotificationType.ALLIANCE_WAR_TAB_RALLY)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabWar, NotificationType.ALLIANCE_WAR_TAB_WAR)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabSiege, NotificationType.ALLIANCE_WAR_TAB_SIEGE)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
end

function AllianceModule:ClearAllAllianceTechNotify()
    table.clear(self._canUpTechGroupIds)
    local notificationModule = ModuleRefer.NotificationModule
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabAlliance, NotificationType.ALLIANCE_TECH_MAIN_TAB_ALLIANCE)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabProduction, NotificationType.ALLIANCE_TECH_MAIN_TAB_PRODUCTION)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabFight, NotificationType.ALLIANCE_TECH_MAIN_TAB_FIGHT)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TECH_CAN_UP_GROUP_REFRESH, self._canUpTechGroupIds)
end

function AllianceModule:ClearAllAllianceLabelUnReadNotify()
    local notificationModule = ModuleRefer.NotificationModule
    local rootNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelEntry, NotificationType.ALLIANCE_LABEL_ENTRY)
    if not rootNode then
        return
    end
    for i, v in pairs(self._allianceLabelUnreadNode) do
        notificationModule:SetDynamicNodeNotificationCount(v, 0)
        notificationModule:RemoveFromParent(v, rootNode)
    end
    table.clear(self._allianceLabelUnreadNode)
end

function AllianceModule:UpdateNoticeNotify(notificationModule, noticeNode)
    local allianceData = self:GetMyAllianceData()
    local lastReadTime = AllianceModuleDefine.GetLastNoticeSaveTime()
    local currentNotice = allianceData and allianceData.AllianceMessage and allianceData.AllianceMessage.Informs or {}
    local toRemoveKey = {}
    for key, node in pairs(self._noticeNodes) do
        if not currentNotice[key] then
            notificationModule:RemoveFromParent(node, noticeNode)
            node:Dispose()
            table.insert(toRemoveKey, key)
        else
            local logTime = noticeNode:GetUserData("logTime")
            if logTime then
                notificationModule:SetDynamicNodeNotificationCount(node, logTime > lastReadTime and 1 or 0)
            end
        end
    end
    for _, v in pairs(toRemoveKey) do
        self._noticeNodes[v] = nil
    end
    for key, data in pairs(currentNotice) do
        if not self._noticeNodes[key] then
            local addNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.GetNotifyKeyForNotice(key), NotificationType.ALLIANCE_NOTICE_NEW)
            local logTime = data.Time.Millisecond
            addNode:SetUserData("logTime", logTime)
            notificationModule:AddToParent(addNode, noticeNode)
            notificationModule:SetDynamicNodeNotificationCount(addNode, logTime > lastReadTime and 1 or 0)
            self._noticeNodes[key] = addNode
        end
    end
end

---@private
---@param notificationModule NotificationModule
---@param memberAppliesNode CS.Notification.NotificationDynamicNode
function AllianceModule:UpdateNotifyAll(notificationModule, memberAppliesNode)
    local allianceData = self:GetMyAllianceData()
    if not allianceData then
        return
    end
    if self:CheckHasAuthority(AllianceAuthorityItem.VerityApply) then
        local applicants = allianceData.AllianceApplicants.Applicants
        local _,num = table.IsNullOrEmpty(applicants)
        notificationModule:SetDynamicNodeNotificationCount(memberAppliesNode, num)
    else
        notificationModule:SetDynamicNodeNotificationCount(memberAppliesNode, 0)
    end
end

---@private
---@param notificationModule NotificationModule
---@param territoryNode CS.Notification.NotificationDynamicNode
---@param myAllianceData wds.Alliance
function AllianceModule:UpdateTerritoryNotifyAll(notificationModule, territoryNode, myAllianceData)
    notificationModule:RemoveAllChildren(territoryNode)
    if not myAllianceData then
        return
    end
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then
        return
    end
    local inAllianceCenterRange = castle.BasicInfo.IsInAllianceCenter
    local hasInTranformingCenter = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TerritoryMoveCity, NotificationType.ALLIANCE_TERRITORY_CENTER_MOVE)
    if hasInTranformingCenter then
        if hasInTranformingCenter.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
            notificationModule:SetDynamicNodeNotificationCount(noticeNode, (not inAllianceCenterRange) and 1 or 0)
        else
            notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
        end
    else
        notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    end
    notificationModule:AddToParent(noticeNode, territoryNode)

    --领土 每日宝箱红点
    local dailyGift = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TerritoryDailyGift, NotificationType.ALLIANCE_TERRITORY_DAILY_GIFT)
    local status = self:GetDailyRewardState()
    notificationModule:SetDynamicNodeNotificationCount(dailyGift,  status == CommonDailyGiftState.CanCliam and 1 or 0)
    notificationModule:AddToParent(dailyGift, territoryNode)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TERRITORY_DAILY_GIFT_REDDOT)
end

---@private
---@param notificationModule NotificationModule
function AllianceModule:UpdateAllianceWarNotifyAll(notificationModule)
    local myAllianceData = self:GetMyAllianceData()
    if not myAllianceData then
        return
    end
    self:UpdateAllianceWarNotifyTabRally(notificationModule, myAllianceData)
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabWar, NotificationType.ALLIANCE_WAR_TAB_WAR)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, 0)
    self:UpdateAllianceWarNotifyTabSiege(notificationModule, myAllianceData)
end

---@private
---@param notificationModule NotificationModule
---@param myAllianceData wds.Alliance
function AllianceModule:UpdateAllianceWarNotifyTabRally(notificationModule, myAllianceData)
    local rallyInfo = myAllianceData.AllianceTeamInfos.Infos
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabRally, NotificationType.ALLIANCE_WAR_TAB_RALLY)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, table.nums(rallyInfo))
end

---@param wars table<number, wds.VillageAllianceWarInfos>
---@return number
function AllianceModule.GetOwnedWarCount(wars)
    if not wars then return 0 end
    local ret = 0
    for _, v in pairs(wars) do
        ret = ret + table.nums(v.WarInfo)
    end
    return ret
end

---@private
---@param notificationModule NotificationModule
---@param myAllianceData wds.Alliance
function AllianceModule:UpdateAllianceWarNotifyTabSiege(notificationModule, myAllianceData)
    local villageWars = myAllianceData.AllianceVillageWar.VillageWar
    local gateWars = myAllianceData.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar
    local behemothCageWars = myAllianceData.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar

    local underAttackCount = 0
    local underSiegeInfo = myAllianceData.AllianceVillageWar.OwnVillageWar
    underAttackCount = underAttackCount + AllianceModule.GetOwnedWarCount(underSiegeInfo)
    local underSiegeInfo2 = myAllianceData.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar
    underAttackCount = underAttackCount + AllianceModule.GetOwnedWarCount(underSiegeInfo2)
    local underSiegeInfo3 = myAllianceData.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar
    underAttackCount = underAttackCount + AllianceModule.GetOwnedWarCount(underSiegeInfo3)
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabSiege, NotificationType.ALLIANCE_WAR_TAB_SIEGE)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, table.nums(villageWars) + table.nums(gateWars) + table.nums(behemothCageWars) + underAttackCount)
end

---@private
---@param notificationModule NotificationModule
---@param myAllianceData wds.Alliance
function AllianceModule:UpdateAllianceTechNotify(notificationModule, myAllianceData)
    if not myAllianceData then
        return
    end
    local techData = myAllianceData.AllianceTechnology
    local markGroup = techData.MarkTechnology
    local groupTab = ModuleRefer.AllianceTechModule:GetTechTypeByGroupId(markGroup)
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabAlliance, NotificationType.ALLIANCE_TECH_MAIN_TAB_ALLIANCE)
    local hasDonateCount = self._selfDonateLeftCount > 0
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, hasDonateCount and groupTab == AllianceTechnologyType.Alliance and 1 or 0)
    noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabProduction, NotificationType.ALLIANCE_TECH_MAIN_TAB_PRODUCTION)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, hasDonateCount and groupTab == AllianceTechnologyType.Production and 1 or 0)
    noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabFight, NotificationType.ALLIANCE_TECH_MAIN_TAB_FIGHT)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, hasDonateCount and groupTab == AllianceTechnologyType.Fight and 1 or 0)
end

---@private
---@param notificationModule NotificationModule
---@param myAllianceData wds.Alliance
function AllianceModule:UpdateAllianceTechUpdateNotify(notificationModule, myAllianceData)
    if not myAllianceData then
        return
    end
    local hasAuthority = self:CheckHasAuthority(AllianceAuthorityItem.UpgradeTech)
    local hasUpdate = false
    self._canUpTechCount = 0
    table.clear(self._canUpTechGroupIds)
    if hasAuthority then
        local techData = myAllianceData.AllianceTechnology
        local AllianceTechModule = ModuleRefer.AllianceTechModule
        for _, v in pairs(techData.TechnologyData) do
            if AllianceTechModule:IsReadyToNextLevel(v) then
                hasUpdate = true
                self._canUpTechCount = self._canUpTechCount + 1
                self._canUpTechGroupIds[v.GroupId] = true
            end
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TECH_CAN_UP_GROUP_REFRESH, self._canUpTechGroupIds)
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TechUpdate, NotificationType.ALLIANCE_MAIN_TECH_ENTRY_UPDATE)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, hasUpdate and 1 or 0)
end

function AllianceModule:UpdateAllianceDonateNotify(skipUpdateNode)
    local limitTime = ConfigRefer.AllianceConsts:AllianceItemDonateLimit()
    local times = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance.NormalDonateTimes or 0
    self._selfDonateLeftCount = math.max(0, limitTime - times)
    self:UpdateAllianceTechEntryNotifyCount()
end

function AllianceModule:UpdateAllianceTechEntryNotifyCount()
    local notificationModule = ModuleRefer.NotificationModule
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Tech, NotificationType.ALLIANCE_MAIN_TECH_ENTRY)
    notificationModule:SetDynamicNodeNotificationCount(noticeNode, self._selfDonateLeftCount)
end

function AllianceModule:GetLabelUnReadNotify(id)
    return self._allianceLabelUnreadNode[id]
end

---@param ids table<number, boolean>
function AllianceModule:RemoveLabelUnReadNotify(ids)
    local notificationModule = ModuleRefer.NotificationModule
    local root = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelEntry, NotificationType.ALLIANCE_LABEL_ENTRY)
    local notifyChange = false
    for id, _ in pairs(ids) do
        local node = self._allianceLabelUnreadNode[id]
        if node then
            notifyChange = true
            self._allianceLabelUnreadNode[id] = nil
            notificationModule:SetDynamicNodeNotificationCount(node, 0)
            notificationModule:RemoveFromParent(node, root)
        end
    end
    if not notifyChange then return end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_CACHED_MARK_UNREAD_CHANGE, self:GetMyAllianceData())
end

function AllianceModule:UpdateAllianceLabelUnReadNotify()
    self:ClearAllAllianceLabelUnReadNotify()
    local data = self:GetMyAllianceData()
    if not data then
        return
    end
    local notificationModule = ModuleRefer.NotificationModule
    local rootNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelEntry, NotificationType.ALLIANCE_LABEL_ENTRY)
    local labels = data.AllianceMessage.MapLabels
    for id, v in pairs(labels) do
        local node = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelUnread:format(id), NotificationType.ALLIANCE_LABEL_UNREAD)
        notificationModule:AddToParent(node, rootNode)
        self._allianceLabelUnreadNode[id] = node
        notificationModule:SetDynamicNodeNotificationCount(node, 1)
    end
end

function AllianceModule:UpdateImpeachEntryNotify()
    local notificationModule = ModuleRefer.NotificationModule
    local rootNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.ImpeachmentEntry, NotificationType.ALLIANCE_MAIN_IMPEACHMENT_ENTRY)
    local data = self:GetMyAllianceData()
    if not data or not data.AllianceLeaderCtrl.IsImpeach or self:IsInImpeachmentVote() then
        notificationModule:SetDynamicNodeNotificationCount(rootNode, 0)
    else
        notificationModule:SetDynamicNodeNotificationCount(rootNode, 1)
    end
end

---@param entity wds.Player
function AllianceModule:UpdateGiftEntryNotify(entity)
    local notificationModule = ModuleRefer.NotificationModule
    local rootNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.GiftEntry, NotificationType.ALLIANCE_MAIN_GIFT_ENTRY)
    local data = entity.PlayerAlliance.NumGifts
    notificationModule:SetDynamicNodeNotificationCount(rootNode, data)
end

---@param entity wds.Alliance
function AllianceModule:OnApplicantsChanged(entity, _)
    if not self:IsInAlliance() then
        return
    end
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    local notificationModule = ModuleRefer.NotificationModule
    local memberAppliesNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.MemberApplies, NotificationType.ALLIANCE_MEMBER_APPLIES_SELECTION)
    self:UpdateNotifyAll(notificationModule, memberAppliesNode)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceNoticeChanged(entity, _)
    if not self:IsInAlliance() then
        return
    end
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    local notificationModule = ModuleRefer.NotificationModule
    local noticeNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Notice, NotificationType.ALLIANCE_MAIN_NOTICE)
    local noticeData = self:GetMyAllianceData().AllianceMessage.Informs or {}
    local toRemove = {}
    for key, _ in pairs(self._noticeNodes) do
        if not noticeData[key] then
            table.insert(toRemove, key)
        end
    end
    for _,key in pairs(toRemove) do
        local toRemoveNode = self._noticeNodes[key]
        self._noticeNodes[key] = nil
        notificationModule:RemoveFromParent(toRemoveNode, noticeNode)
        toRemoveNode:Dispose()
    end
    local lastReadTime = AllianceModuleDefine.GetLastNoticeSaveTime()
    for key, data in pairs(noticeData) do
        if not self._noticeNodes[key] then
            local addNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.GetNotifyKeyForNotice(key), NotificationType.ALLIANCE_NOTICE_NEW)
            local logTime = data.Time.Millisecond
            addNode:SetUserData("logTime", logTime)
            notificationModule:AddToParent(addNode, noticeNode)
            notificationModule:SetDynamicNodeNotificationCount(addNode, logTime > lastReadTime and 1 or 0)
            self._noticeNodes[key] = addNode
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, self:GetAllianceId())
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceActivityBattleDataChanged(entity, changedData)
    if not self:IsInAlliance() then
        return
    end
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    local add,_,_ = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.AllianceActivityBattleInfo)
    if add then
        local myRank = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank
        for _, v in pairs(add) do
            local config = ConfigRefer.AllianceBattle:Find(v.CfgId)
            if config and config:Type() == AllianceBattleType.BehemothBattle then
                ---@type AllianceBehemothWarTipMediatorParameter
                local param = {}
                if v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusOpen then
                    if myRank < AllianceModuleDefine.R3Rank then
                        goto continue
                    end
                    param.btnText = I18N.Get("alliance_behemoth_button_look")
                elseif v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
                    if myRank < AllianceModuleDefine.R3Rank then
                        goto continue
                    end
                    param.btnText = I18N.Get("alliance_behemoth_button_look")
                elseif v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
                    if myRank < AllianceModuleDefine.R3Rank then
                        param.btnText = I18N.Get("alliance_behemoth_button_look")
                    else
                        param.btnText = I18N.Get("alliance_behemoth_button_challenge")
                    end
                end
                param.content = I18N.Get("alliance_behemoth_fighting2")
                param.icon = config:BossIcon()
                param.onGoto = function()
                    local tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
                    ModuleRefer.ActivityCenterModule:GotoActivity(tabId)
                end
                g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothWarTipMediator, param)
                break
                ::continue::
            end
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BATTLE_HUD_REFRESH)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceTechMarkDataChanged(entity, _)
    if not self:IsInAlliance() then
        return
    end
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    local notificationModule = ModuleRefer.NotificationModule
    self:UpdateAllianceTechNotify(notificationModule, entity)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceTechDataChanged(entity, _)
    if not self:IsInAlliance() then
        return
    end
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    local notificationModule = ModuleRefer.NotificationModule
    self:UpdateAllianceTechUpdateNotify(notificationModule, entity)
end

---@param entity wds.Player
function AllianceModule:OnPlayerDonateTimesChanged(entity, _)
    if not entity or entity.ID ~= self._playerId then
        return
    end
    self:UpdateAllianceDonateNotify()
    if self:IsInAlliance() then
        self:UpdateAllianceTechNotify(ModuleRefer.NotificationModule, self:GetMyAllianceData())
    end
end

function AllianceModule.CompareData(a, b)
    local stack = {{x=a,y=b}}
    while #stack > 0 do
        local compare = table.remove(stack)
        if compare.x ~= compare.y then
            local typeX = type(compare.x)
            local typeY = type(compare.y)
            if typeX ~= typeY then return false end
            if typeX == 'number' then
                if math.abs(compare.y - compare.x) > 0.0000001 then
                    return false
                end
            elseif typeX == 'table' then
                for key, value in pairs(compare.x) do
                    table.insert(stack, {x=value,y=compare.y[key]})
                end
            else
                return false
            end
        end
    end
    return true
end

---@param entity wds.Alliance
function AllianceModule:DoOnForceRebuildLabelCache(entity)
    local currentData = entity.AllianceMessage.MapLabels
    local add = {}
    local remove = {}
    local change = {}
    for i, v in pairs(currentData) do
        local oldData = self._cachedAllianceLabel[i]
        if not oldData then
            add[i] = v
        elseif not AllianceModule.CompareData(oldData, v) then
            change[i] = {oldData, v}
        end
    end
    for i, v in pairs(self._cachedAllianceLabel) do
        if not currentData[i] then
            remove[i] = v
        end
    end
    table.clear(self._cachedAllianceLabel)
    for i, v in pairs(currentData) do
        self._cachedAllianceLabel[i] = v
    end

    local notificationModule = ModuleRefer.NotificationModule
    local rootNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelEntry, NotificationType.ALLIANCE_LABEL_ENTRY)
    if remove then
        for i, _ in pairs(remove) do
            local node = self._allianceLabelUnreadNode[i]
            if node then
                notificationModule:RemoveFromParent(node, rootNode)
                notificationModule:SetDynamicNodeNotificationCount(node, 0)
                self._allianceLabelUnreadNode[i] = nil
            end
        end
    end
    if add then
        for i, _ in pairs(add) do
            local node = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelUnread:format(i), NotificationType.ALLIANCE_LABEL_UNREAD)
            self._allianceLabelUnreadNode[i] = node
            notificationModule:AddToParent(node, rootNode)
            notificationModule:SetDynamicNodeNotificationCount(node, 1)
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, entity ,add, remove, change)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceLabelDataChanged(entity, changedData)
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    self:DoOnForceRebuildLabelCache(entity)
end

function AllianceModule:RefreshNoticeLastReadTime()
    local lastReadTime = g_Game.ServerTime:GetServerTimestampInMilliseconds()
    AllianceModuleDefine.SetLastNoticeSaveTime(lastReadTime)
    local notificationModule = ModuleRefer.NotificationModule
    for _, node in pairs(self._noticeNodes) do
        local logTime = node:GetUserData("logTime")
        notificationModule:SetDynamicNodeNotificationCount(node, logTime > lastReadTime and 1 or 0)
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, self:GetAllianceId())
end

function AllianceModule:HasAuthorityAllianceMapLabel()
    return self:IsInAlliance() and self:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel)
end

---@param isSuccess boolean
---@param rsp wrpc.NewAllianceInvitationRequest
function AllianceModule:OnServerPushNewAllianceInvitation(isSuccess, rsp)
    if not isSuccess then
        return
    end
    if self:IsInAlliance() then
        g_Logger.Warn("Player already in alliance")
        return
    end
    if ModuleRefer.GuideModule:GetGuideState() then
        g_Logger.Warn("In Guide, skip")
        return
    end
    ---@type AlliancePushInviteTipMediatorParameter
    local p = {}
    p.allianceInfo = rsp.BasicInfo
    g_Game.UIManager:Open(UIMediatorNames.AlliancePushInviteTipMediator, p)
end

function AllianceModule:OnAllianceImpeachStatusChanged(entity, _)
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    self:UpdateImpeachEntryNotify()
end

function AllianceModule:OnAllianceImpeachVoteChanged(entity, _)
    if entity.ID ~= self:GetAllianceId() then
        return
    end
    self:UpdateImpeachEntryNotify()
end

---@param entity wds.Player
function AllianceModule:OnPlayerGiftChanged(entity, _)
    if not entity or entity.ID ~= self._playerId then
        return
    end
    self:UpdateGiftEntryNotify(entity)
end

---@param isSuccess boolean
---@param rsp wrpc.PushCanJoinAlliancesRequest
function AllianceModule:OnServerPushCanJoinAlliances(isSuccess, rsp)
    if not isSuccess then
        return
    end
    self._cachedAllianceRecruitTopInfos = rsp.Infos
    if table.isNilOrZeroNums(self._cachedAllianceRecruitTopInfos) then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_FIND_NEXT_RECRUIT_TOP_INFO, 1)
end

---@param rsp wrpc.SyncAllianceHelpRequest
function AllianceModule:OnServerPushAllianceHelpd(isSuccess, rsp)
    if not isSuccess then return end
    if not self:IsInAlliance() then return end
    ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_help_behelped_tips", rsp.CurNum, rsp.MaxNum, rsp.PlayerName, TimeFormatter.TimerStringFormat(rsp.AllDelTime)))
end

---@param entity wds.CastleBrief
function AllianceModule:OnPlayerCastleInAllianceRangeChanged(entity)
    if not entity then return end
    local allianceData = self:GetMyAllianceData()
    local notificationModule = ModuleRefer.NotificationModule
    local territoryNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Territory, NotificationType.ALLIANCE_MAIN_TERRITORY)
    self:UpdateTerritoryNotifyAll(notificationModule, territoryNode ,allianceData)
end

---@param entity wds.Alliance
function AllianceModule:OnAllianceMapBuildingChanged(entity, changedData)
    if not entity then return end
    local add,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.MapBuildingBrief)
    local needRefresh = false
    if add then
        for _, value in pairs(add) do
            if value.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
                needRefresh = true
                break
            end
        end
    end
    if not needRefresh and remove then
        for _, value in pairs(remove) do
            if value.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
                needRefresh = true
                break
            end
        end
    end
    if not needRefresh and change then
        for _, value in pairs(change) do
            local old = value[1]
            local new = value[2]
            if old and new and old.AllianceCenterStatus ~= new.AllianceCenterStatus then
                if old.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone
                    or new.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone
                then
                    needRefresh = true
                    break
                end 
            end
        end
    end
    if not needRefresh then return end
    local allianceData = self:GetMyAllianceData()
    local notificationModule = ModuleRefer.NotificationModule
    local territoryNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Territory, NotificationType.ALLIANCE_MAIN_TERRITORY)
    self:UpdateTerritoryNotifyAll(notificationModule, territoryNode ,allianceData)
end

---@param item number @AllianceAuthorityItem
---@return boolean
function AllianceModule:CheckHasAuthority(item)
    if not self:IsInAlliance() then
        return false
    end
    local itemR = self._allianceAuthorityMatrix[item]
    if not itemR then
        return false
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return itemR[player.Owner.AllianceRank] or false
end

---@param createParameter AllianceModuleCreateAllianceParameter
---@param callBack fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SendCreateAlliance(createParameter, callBack)
    local cmd = AllianceParameters.CreateAllianceParameter.new()
    cmd.args.Name = createParameter.name
    cmd.args.Abbr = createParameter.abbr
    cmd.args.Notice = createParameter.notice
    cmd.args.Flag = createParameter.flag
    cmd.args.Language = createParameter.lang
    cmd.args.JoinSetting = createParameter.joinSetting
    cmd:SendOnceCallback(nil, nil, nil, callBack)
end

---@param notice string
---@param language number
---@param joinSetting number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SetAllianceBasicInfo(notice, language, joinSetting, callback)
    local cmd = AllianceParameters.SetAllianceBasicInfoParameter.new()
    cmd.args.Notice = notice
    cmd.args.Language = language
    cmd.args.JoinSetting = joinSetting
    cmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param allianceFlag wds.AllianceFlag
---@param lockable CS.UnityEngine.Transform
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SetAllianceFlagParameter(allianceFlag, lockable, callback)
    local cmd = AllianceParameters.SetAllianceFlagParameter.new()
    cmd.args.Flag = allianceFlag
    cmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param abbr string
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SetAllianceAbbrParameter(abbr, callback)
    local cmd = AllianceParameters.SetAllianceAbbrParameter.new()
    cmd.args.Abbr = abbr
    cmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param name string
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SetAllianceNameParameter(name, callback)
    local cmd = AllianceParameters.SetAllianceNameParameter.new()
    cmd.args.Name = name
    cmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param language number
---@param callback fun(cmd:GetRecommendedAlliancesParameter, isSuccess:boolean, rsp:wrpc.GetRecommendedAlliancesReply)
function AllianceModule:GetRecommendedAlliances(language, callback)
    local sendCmd = AllianceParameters.GetRecommendedAlliancesParameter.new()
    sendCmd.args.Language = language
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param search string
---@param callback fun(cmd:GetRecommendedAlliancesParameter, isSuccess:boolean, rsp:wrpc.FindAlliancesReply)
function AllianceModule:FindAlliances(search, callback)
    local sendCmd = AllianceParameters.FindAlliancesParameter.new()
    sendCmd.args.Prefix = search
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@return wrpc.AllianceBriefInfo
function AllianceModule:RequestAllianceBriefInfo(allianceId, forceUpdate)
    return self._allianceBasicInfoCacheHelper:RequestAllianceBriefInfo(allianceId, forceUpdate)
end

---@return AllianceMembersInfoCache
function AllianceModule:RequestAllianceMembersInfo(allianceId, forceUpdate)
    return self._allianceMembersInfoCacheHelper:RequestAllianceMemberInfo(allianceId, forceUpdate)
end

---@param lockable CS.UnityEngine.Transform
---@param allianceId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:JoinOrApplyAlliance(lockable, allianceId, callback)
    local sendCmd = AllianceParameters.ApplyForAllianceParameter.new()
    sendCmd.args.AllianceID = allianceId
    sendCmd:SendOnceCallback(lockable, nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            self:RequestAllianceBriefInfo(allianceId, true)
            self:RequestAllianceMembersInfo(allianceId, true)
        end
        if callback then
            callback(cmd, isSuccess, rsp)
        end
    end)
end

--接受邀请入盟
function AllianceModule:AcceptRecruitAlliance(lockable, allianceId, callback)
    local sendCmd = AllianceParameters.ReplyToAllianceInvitationParameter.new()
    sendCmd.args.AllianceID = allianceId
    sendCmd.args.Accept = true
    sendCmd:SendOnceCallback(lockable, nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            self:RequestAllianceBriefInfo(allianceId, true)
            self:RequestAllianceMembersInfo(allianceId, true)
        end
        if callback then
            callback(cmd, isSuccess, rsp)
        end
    end)
end

--被其他玩家邀请入盟 红点
function AllianceModule:OnInviteAllianceIDsChanged()
    local res = self:GetRecuirtAllianceInfo()
    local root = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Main, NotificationType.ALLIANCE_ENTRANCE)
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("ALLIANCE_RECRUIT", NotificationType.ALLIANCE_RECRUIT)
    ModuleRefer.NotificationModule:AddToParent(node, root)
    --不在联盟中才有此红点
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, not self:IsInAlliance() and #res or 0)
end

function AllianceModule:GetRecuirtAllianceInfo()
    local inviteData = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance.InviteAllianceIDs
    local count = 0
    local sortedAlliances = {}
    local alliances = {}

    for k,v in pairs(inviteData) do
        table.insert(sortedAlliances,{k = k, v = v})
    end
    table.sort(sortedAlliances,function(a,b)
        return a.v.Seconds > b.v.Seconds
    end)
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    for _,v in pairs(sortedAlliances) do
        local validT = ConfigRefer.AllianceConsts:AllianceInviteValidTime()
        if v.v.Seconds + validT > curT then
            count = count + 1
            table.insert(alliances,v.k)
            --服务器协议数量上限为10 多余直接丢掉
            if count > 10 then
                break
            end
        end
    end
    return alliances
end

---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:LeaveAlliance(callback)
    if not self:IsInAlliance() then
        if callback then
            callback(nil, false, nil)
        end
        return
    end
    if self:IsAllianceLeader() then
        if callback then
            callback(nil, false, nil)
        end
        return
    end
    local sendCmd = AllianceParameters.QuitAllianceParameter.new()
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:DisbandAlliance(callback)
    if not self:IsAllianceLeader() then
        if callback then
            callback(nil, false, nil)
        end
        return
    end
    local sendCmd = AllianceParameters.DisbandAllianceParameter.new()
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param playerFacebookId number
---@param agree boolean
function AllianceModule:VerifyAllianceApplication(playerFacebookId, agree)
    local sendCmd = AllianceParameters.VerifyAllianceApplicationParameter.new()
    sendCmd.args.Applicant = playerFacebookId
    sendCmd.args.Agree = agree
    sendCmd:Send(nil, playerFacebookId)
end

---@param targetPlayerFacebookId number
---@param rank number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SetAllianceRank(targetPlayerFacebookId, rank, callback)
    local sendCmd = AllianceParameters.SetAllianceRankParameter.new()
    sendCmd.args.Member = targetPlayerFacebookId
    sendCmd.args.Rank = rank
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param targetPlayerFacebookId number
---@param title number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SetAllianceTitle(targetPlayerFacebookId, title, callback)
    local sendCmd = AllianceParameters.SetAllianceTitleParameter.new()
    sendCmd.args.Member = targetPlayerFacebookId
    sendCmd.args.Title = title
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@param entity wds.Player
function AllianceModule:OnPlayerHelpNumChanged(entity, _)
    if entity.ID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    local NM = ModuleRefer.NotificationModule
    local node = NM:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.HelpEntry, NotificationType.ALLIANCE_MAIN_HELP_ENTRY)
    local count = self:IsInAlliance() and entity.PlayerAlliance.NumHelps or 0
    NM:SetDynamicNodeNotificationCount(node, count)
end

function AllianceModule:Tick(dt)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self:TickOnCheckBehemothCageStart(nowTime)
    self:TickOnVillageWarStart(nowTime)
    self:TickOnVillageWarInfoTipStart(nowTime)
end

function AllianceModule:GetAllianceHelps()
    local sendCmd = AllianceParameters.GetAllianceHelpsParameter.new()
    sendCmd:Send()
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:RequestAllianceHelp(lockable, callback, configId ,buildingId, workId)
    if not workId then
        return
    end
    local sendCmd = AllianceParameters.RequestAllianceHelpParameter.new()
    local info = sendCmd.args.Info
    info.HelpType = wrpc.AllianceHelpType.AllianceHelpType_Building
    info.BuildingCfgId = configId
    info.BuildingId = buildingId
    info.WorkId = workId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SendAllianceHelps(lockable, callback)
    local sendCmd = AllianceParameters.SendAllianceHelpsParameter.new()
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@return AllianceLogConfigCell
function AllianceModule:GetAllianceLogConfig(logType)
    if not self._logTypeConfigMap then
        self._logTypeConfigMap = {}
        for _, v in ConfigRefer.AllianceLog:ipairs() do
            self._logTypeConfigMap[v:Type()] = v
        end
    end
    return self._logTypeConfigMap[logType]
end

---@param title string
---@param content string
---@param lockable CS.UnityEngine.Transform
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SendReleaseAllianceInfo(title, content, lockable, callback)
    local sendCmd = AllianceParameters.AddAllianceInformParameter.new()
    sendCmd.args.Title = title
    sendCmd.args.Content = content
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param id number
---@param lockable CS.UnityEngine.Transform
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SendRemoveAllianceInfo(id, lockable, callback)
    local sendCmd = AllianceParameters.RemoveAllianceInformParameter.new()
    sendCmd.args.InformId = id
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:RequestAllianceLeader(lockable, callback)
    local sendCmd = AllianceParameters.RequestAllianceLeaderParameter.new()
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param difficulty number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@param chosenActivity number @ActivityTemplate ConfigId
function AllianceModule:ActivateAllianceActivityBattle(lockable, battleId, difficulty, callback, chosenActivity)
    local sendCmd = AllianceParameters.ActivateAllianceActivityBattleParameter.new()
    sendCmd.args.BattleId = battleId
    sendCmd.args.Difficulty = difficulty
    sendCmd.args.ChosenActivity = chosenActivity
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:CancelAllianceActivityBattle(lockable, battleId, callback)
    local sendCmd = AllianceParameters.CancelAllianceActivityBattleParameter.new()
    sendCmd.args.BattleId = battleId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param queueIndex number[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SignUpAllianceActivityBattle(lockable, battleId, queueIndex, callback)
    local sendCmd = AllianceParameters.SignUpAllianceActivityBattleParameter.new()
    sendCmd.args.BattleId = battleId
    for _, v in ipairs(queueIndex) do
        sendCmd.args.QueueIndex:Add(v)
    end
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param queueIndex number
---@param delete boolean
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:ModifySignUpTroopPresetParameter(lockable, battleId, queueIndex, delete, callback)
    local sendCmd = AllianceParameters.ModifySignUpTroopPresetParameter.new()
    sendCmd.args.BattleId = battleId
    sendCmd.args.QueueIndex = queueIndex
    sendCmd.args.Delete = delete
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:StartAllianceActivityBattle(lockable, battleId, callback)
    local sendCmd = AllianceParameters.StartAllianceActivityBattleParameter.new()
    sendCmd.args.BattleId = battleId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:CancelSignUpAllianceActivityBattle(lockable, battleId, callback)
    local sendCmd = AllianceParameters.CancelSignUpAllianceActivityBattleParameter.new()
    sendCmd.args.BattleId = battleId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param playerId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:KickAllianceActivityBattleMember(lockable, battleId, playerId, callback)
    local sendCmd = AllianceParameters.KickAllianceActivityBattleMemberParameter.new()
    sendCmd.args.BattleId = battleId
    sendCmd.args.TargetPlayerId = playerId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

function AllianceModule:GetBattleInstanceId(battleId)
    if not self:IsInAlliance() then
        return nil
    end
    local allianceData = self:GetMyAllianceData()
    local battleData = allianceData and allianceData.AllianceActivityBattles and allianceData.AllianceActivityBattles.Battles and allianceData.AllianceActivityBattles.Battles[battleId]
    local config = ConfigRefer.AllianceBattle:Find(battleData.CfgId)
    local sceneIndex = battleData.ActivatedInstanceIndex
    if sceneIndex >= 0 and sceneIndex < config:InstanceLength() then
        return config:Instance(sceneIndex + 1)
    end
    return nil
end

---@param lockable CS.UnityEngine.Transform
---@param battleId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:EnterAllianceActivityBattleScene(lockable, battleId, callback)
    local tid = self:GetBattleInstanceId(battleId)
    if tid then        
        local SEHudTroopMediatorDefine = require('SEHudTroopMediatorDefine')
        local fromType = ModuleRefer.SlgModule:IsInCity() and SEHudTroopMediatorDefine.FromType.City or SEHudTroopMediatorDefine.FromType.World
        g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", fromType, true)   
        if fromType == SEHudTroopMediatorDefine.FromType.World then           
            local kingdomCam = ModuleRefer.SlgModule:GetBasicCamera()
            local lookAtPos = kingdomCam:GetLookAtPlanePosition()          
            local lookAtCoord = CS.Grid.MapUtils.CalculateWorldPositionToCoord(lookAtPos,require("KingdomMapUtils").GetStaticMapData())
            g_Game.StateMachine:WriteBlackboard("SE_FROM_X", lookAtCoord.X, true)           
            g_Game.StateMachine:WriteBlackboard("SE_FROM_Y", lookAtCoord.Y, true)           
        end
        g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonNotifyPopupMediator)
        ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
        ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
        GotoUtils.GotoSceneSe(tid, {})
        if callback then
            callback(nil, true)
        end
        return
    end
    if callback then
        callback(nil, false, nil)
    end
end

---@param lockable CS.UnityEngine.Transform
---@param memberFacebookId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@param userData any
function AllianceModule:KickAllianceMember(lockable, memberFacebookId, callback, userData)
    local checkInActivityBattle = false
    local allianceData = self:GetMyAllianceData()
    if not allianceData then
        return
    end
    if allianceData.AllianceActivityBattles and allianceData.AllianceActivityBattles.Battles then
        for _, v in pairs(allianceData.AllianceActivityBattles.Battles) do
            if v.Members then
                for _, memberInfo in pairs(v.Members) do
                    if memberInfo.FacebookId == memberFacebookId then
                        checkInActivityBattle = true
                        goto KickAllianceMember_check_in_activity_battle_end
                    end
                end
            end
        end
    end
    ::KickAllianceMember_check_in_activity_battle_end::
    if checkInActivityBattle then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_gvebutiren"))
        return
    end
    local sendCmd = AllianceParameters.RemoveAllianceMemberParameter.new()
    sendCmd.args.Member = memberFacebookId
    sendCmd:SendOnceCallback(lockable, userData, nil, callback)
end

---@param currencyType number @AllianceCurrencyType
function AllianceModule:GetAllianceCurrencyByType(currencyType)
    local myAllianceData = self:GetMyAllianceData()
    if not myAllianceData then
        return 0
    end
    local idSet = self._currencyType2IdSet[currencyType]
    if not idSet then
        return 0
    end
    local count = 0
    local currencyData = myAllianceData.AllianceCurrency.Currency
    for i, v in pairs(currencyData) do
        if idSet[i] then
            count = count + v
        end
    end
    return count
end

---@param currencyType number @AllianceCurrencyType
---@return AllianceCurrencyConfigCell
function AllianceModule:GetAllianceCurrencyConfigByType(currencyType)
	local idSet = self._currencyType2IdSet[currencyType]
	if not idSet then
		return nil
	end
	for id, _ in pairs(idSet) do
		local ret =  ConfigRefer.AllianceCurrency:Find(id)
		if ret then
			return ret
		end
	end
	return nil
end

---@param id number
---@return number @AllianceCurrencyType
function AllianceModule:GetAllianceCurrencyTypeById(id)
    return self._currencyId2Type[id]
end

---@param id number
function AllianceModule:GetAllianceCurrencyById(id)
    local myAllianceData = self:GetMyAllianceData()
    if not myAllianceData then
        return 0
    end
    return myAllianceData.AllianceCurrency.Currency[id] or 0
end

---@return nil|number,number|nil
function AllianceModule:IsAllianceRelativeSpeedAttrId(id)
    return self._speedAttrIdSet[id], self._speedAttrId2CurrencyTypeSet[id]
end

---@return {speed:number|nil, limit:number|nil}|nil
function AllianceModule:GetAllianceCurrencyAttr(id)
    local type = self._currencyId2Type[id]
    if not type then
        return nil
    end
    return self._currencyType2Attr[type]
end

---@param id number
---@return number
function AllianceModule:GetAllianceCurrencyMaxCountById(id)
    local type = self._currencyId2Type[id]
    if not type then
        return 0
    end
    return self:GetAllianceCurrencyMaxCountByType(type)
end

---@param type number @AllianceCurrencyType
---@return number
function AllianceModule:GetAllianceCurrencyMaxCountByType(type)
    local attr = self._currencyType2Attr[type]
    if not attr or not attr.limit then
        return 0
    end
    if not self:GetMyAllianceData() then return 0 end
    local attrValue = self:GetMyAllianceData().AllianceTechnology.AttrDisplay
    return attrValue[attr.limit] or 0
end

---@param id number
---@return number
function AllianceModule:GetAllianceCurrencyAddSpeedById(id)
    local type = self._currencyId2Type[id]
    if not type then
        return 0
    end
    return self:GetAllianceCurrencyAddSpeedByType(type)
end

---@param type number @AllianceCurrencyType
---@return number
function AllianceModule:GetAllianceCurrencyAddSpeedByType(type)
    local attr = self._currencyType2Attr[type]
    if not attr or not attr.speed then
        return 0
    end
    if not self:GetMyAllianceData() then return 0 end
    local attrValue = self:GetMyAllianceData().AllianceTechnology.AttrDisplay
    return attrValue[attr.speed] or 0
end

---@param currencyType number @AllianceCurrencyType
function AllianceModule:GetAllianceCurrencyAutoAddTimeInterval(currencyType)
    local value
    if currencyType == AllianceCurrencyType.WarCard or currencyType == AllianceCurrencyType.BuildCard then
        value = 1 -- 1day
    elseif self:GetMyAllianceData() then
        local attrValue = self:GetMyAllianceData().AllianceTechnology.AttrDisplay
        value = attrValue[AllianceAttr.Currency_Time_Interval]
    end
    if not value or value <= 0 then
        return nil
    end
    return (value and value > 0) and value or nil
end

function AllianceModule:GetMyAllianceAllianceTeamInfoByTeamId(teamId)
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceTeamInfos or not allianceData.AllianceTeamInfos.Infos then
        return nil
    end
    return allianceData.AllianceTeamInfos.Infos[teamId]
end

---@param abbr string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function AllianceModule.CheckAllianceAbbr(abbr, callback, simpleErrorOverride)
    if string.IsNullOrEmpty(abbr) then
        callback(abbr, false)
        return
    end
    local parameter = AllianceParameters.CheckAllianceAbbrParameter.new()
    parameter.args.Abbr = abbr
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if callback then
            callback(abbr, isSuccess)
        end
    end, simpleErrorOverride)
end

---@param allianceName string
---@param callback fun(abbr:string,pass:boolean,errorCode:number)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function AllianceModule.CheckAllianceName(allianceName, callback, simpleErrorOverride)
    if string.IsNullOrEmpty(allianceName) then
        callback(allianceName, false)
        return
    end
    local parameter = AllianceParameters.CheckAllianceNameParameter.new()
    parameter.args.Name = allianceName
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if callback then
            callback(allianceName, isSuccess)
        end
    end, simpleErrorOverride)
end

---@param notice string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function AllianceModule.CheckAllianceNotice(notice, callback, simpleErrorOverride)
    local parameter = AllianceParameters.CheckAllianceInformParameter.new()
    parameter.args.Inform = notice
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if callback then
            callback(notice, isSuccess)
        end
    end, simpleErrorOverride)
end

---@param notice string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function AllianceModule.CheckAllianceInfoTitle(info, callback, simpleErrorOverride)
    callback(info, true)
end

---@param info string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function AllianceModule.CheckAllianceInfoContent(info, callback, simpleErrorOverride)
    local parameter = AllianceParameters.CheckAllianceInformParameter.new()
    parameter.args.Inform = info
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if callback then
            callback(info, isSuccess)
        end
    end, simpleErrorOverride)
end

---@param recruitMsg string
---@param callback fun(abbr:string,pass:boolean)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function AllianceModule.CheckAllianceRecruitMsg(recruitMsg, callback, simpleErrorOverride)
    local parameter = AllianceParameters.CheckAllianceInformParameter.new()
    parameter.args.Inform = recruitMsg
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if callback then
            callback(recruitMsg, isSuccess)
        end
    end, simpleErrorOverride)
end

---@param src wds.AllianceFlag
---@param dst wds.AllianceFlag
function AllianceModule.CopyFlagSetting(src, dst)
    dst.BadgeAppearance = src.BadgeAppearance
    dst.BadgePattern = src.BadgePattern
    dst.TerritoryColor = src.TerritoryColor
end

---@return number,number @itemId,count
function AllianceModule.GetAllianceCostItemAndNum(costItemGroupId)
    local cost = ConfigRefer.ItemGroup:Find(costItemGroupId)
    if not cost then
        return nil,0
    end
    local itemInfo = cost:ItemGroupInfoList(1)
    return itemInfo:Items(),itemInfo:Nums()
end


---@param territoryColor number
---@return CS.UnityEngine.Color
function AllianceModule:GetTerritoryColor(territoryColor)
    local cfg = ConfigRefer.AllianceTerritoryColor:Find(territoryColor)
    if cfg then
        local success,color = CS.UnityEngine.ColorUtility.TryParseHtmlString(cfg:Color())
        if success then
            return color
        end
    end
    return ModuleRefer.TerritoryModule:GetNeutralColor()
end

---@param currencyLog wds.AllianceCurrencyLog
---@return string
function AllianceModule.ParseAllianceCurrencyLog(currencyLog)
    local currencyConfig = ConfigRefer.AllianceCurrencyLog:Find(currencyLog.LogConfigId)
    if not currencyConfig then
        return string.Empty
    end
    return ServiceDynamicDescHelper.ParseWithI18N(currencyConfig:Content(), currencyConfig:ContentDescLength(), currencyConfig, currencyConfig.ContentDesc
    , currencyLog.StringParams, currencyLog.IntParams, {} ,currencyLog.ConfigParams)
end

---@return wds.AllianceMember
function AllianceModule:GetAllianceLeaderInfo()
    local leaderID = self:GetMyAllianceData().AllianceBasicInfo.LeaderID
    return self:QueryMyAllianceMemberData(leaderID)
end

function AllianceModule:CheckActivityBattleIsUnLocked(showToast)
    if not self:IsInAlliance() then
        goto CheckActivityBattleIsUnLocked_end_false
    end
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Alliance_gve) then
        goto CheckActivityBattleIsUnLocked_end_false
    else
        return true
    end
    ::CheckActivityBattleIsUnLocked_end_false::
    if showToast then
        if not ModuleRefer.NewFunctionUnlockModule:ShowLockedTipToast(NewFunctionUnlockIdDefine.Alliance_gve) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("gvewarning_test1"))
        end
    end
    return false
end

function AllianceModule:CheckBehemothUnlock(showToast)
    if not self:IsInAlliance() then
        goto CheckBehemothUnlock_end_false
    end
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.BehemothNest) then
        goto CheckBehemothUnlock_end_false
    else
        return true
    end
    ::CheckBehemothUnlock_end_false::
    if showToast then
        if not ModuleRefer.NewFunctionUnlockModule:ShowLockedTipToast(NewFunctionUnlockIdDefine.BehemothNest) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("gvewarning_test1"))
        end
    end
    return false
end

---@param allianceMember wds.AllianceMember
function AllianceModule:IsAllianceMemberAFK(allianceMember)
    if not allianceMember or not allianceMember.LatestLogoutTime then
        return false
    end
    if not allianceMember.LatestLoginTime then
        return true
    end
    local logoutTime = allianceMember.LatestLogoutTime.ServerSecond
    local loginTime = allianceMember.LatestLoginTime.ServerSecond
    if loginTime > logoutTime then
        return false
    end
    local entryId = ConfigRefer.AllianceConsts:AFKSystemEntry()
    local offLineTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() - logoutTime
    local afkOffsetTime
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(entryId) then
        afkOffsetTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AFKOfflineTime1())
    else
        afkOffsetTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AFKOfflineTime2())
    end
    return offLineTime >= afkOffsetTime
end

---@param allianceMember wds.AllianceMember
function AllianceModule:IsAllianceMemberNotActive(allianceMember)
    if not allianceMember or not allianceMember.LatestLogoutTime then
        return false
    end
    if not allianceMember.LatestLoginTime then
        return true
    end
    local logoutTime = allianceMember.LatestLogoutTime.ServerSecond
    local loginTime = allianceMember.LatestLoginTime.ServerSecond
    if loginTime > logoutTime then
        return false
    end
    local entryId = ConfigRefer.AllianceConsts:NoActiveSystemEntry()
    local offLineTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() - logoutTime
    local notActiveTime
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(entryId) then
        notActiveTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:NoActiveOfflineTime1())
    else
        notActiveTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:NoActiveOfflineTime2())
    end
    return offLineTime >= notActiveTime
end

---@param allianceMember wds.AllianceMember
function AllianceModule:IsAllianceMemberSwitchLeaderTarget(allianceMember)
    if not allianceMember then
        return
    end
    local allianceData = self:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceLeaderCtrl then
        return
    end
    return allianceMember.FacebookID == allianceData.AllianceLeaderCtrl.SwitchLeaderTargetFacebookId
end

function AllianceModule:GetSwitchLeaderEndTime()
    local allianceData = self:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceLeaderCtrl or not allianceData.AllianceLeaderCtrl.SwitchLeaderEndTime then
        return 0
    end
    return allianceData.AllianceLeaderCtrl.SwitchLeaderEndTime.ServerSecond
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param targetFacebookId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:SwitchLeader(lockable, targetFacebookId, callback)
    local sendCmd = AllianceParameters.SwitchLeaderParameter.new()
    sendCmd.args.MemberFacebookId = targetFacebookId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:CancelSwitchLeader(lockable, callback)
    local sendCmd = AllianceParameters.CancelSwitchLeaderParameter.new()
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

function AllianceModule:IsInImpeachmentVote()
    local allianceData = self:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceLeaderCtrl then
        return false
    end
    local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    if allianceData.AllianceLeaderCtrl.AgreeFbIds and allianceData.AllianceLeaderCtrl.AgreeFbIds[selfFacebookId] then
        return true
    end
    if allianceData.AllianceLeaderCtrl.DisAgreeFbIds and allianceData.AllianceLeaderCtrl.DisAgreeFbIds[selfFacebookId] then
        return true
    end
    return false
end

function AllianceModule:StartImpeachmentVote(toLeaderName)
    local impeachmentTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:ImpeachWaitTime())
    local toHour = impeachmentTime / 60 // 60
    local needCount = ConfigRefer.AllianceConsts:ImpeachNeedMemberCount()
    local styleDefine = CommonConfirmPopupMediatorDefine.Style
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = styleDefine.WarningAndCancel
    parameter.title = I18N.Get("alliance_retire_impeach_makesuretitle")
    parameter.content = I18N.GetWithParams("alliance_retire_impeach_desc", ("%d"):format(math.floor(toHour + 0.5)), needCount, toLeaderName)
    parameter.onConfirm = function()
        local sendCmd = AllianceParameters.StartImpeachAllianceLeaderParameter.new()
        sendCmd:Send()
        return true
    end
    
    local costItemGroup = ConfigRefer.AllianceConsts:ImpeachCostItem()
    if costItemGroup ~= 0 then
        parameter.styleBitMask = parameter.styleBitMask | styleDefine.WithResource
        ---@type CommonResourceRequirementComponentParameter
        parameter.resourceParameter = {}
        local itemGroup = ConfigRefer.ItemGroup:Find(costItemGroup)
        local itemNeed = itemGroup:ItemGroupInfoList(1)
        parameter.resourceParameter.requireId = itemNeed:Items()
        parameter.resourceParameter.requireValue = itemNeed:Nums()
        parameter.resourceParameter.requireType = 2
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param isAgree boolean
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:VoteForImpeachment(lockable, isAgree, callback)
    local sendCmd = AllianceParameters.VoteImpeachAllianceLeaderParameter.new()
    sendCmd.args.IsAgree = isAgree
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@return wds.AllianceLeaderChangeInfo|nil
function AllianceModule:GetLeaderChangeInfo()
    local allianceData = self:GetMyAllianceData()
    return allianceData and allianceData.AllianceLeaderCtrl.LeaderChangeInfo or nil
end

function AllianceModule:ReadAllianceLeaderChange()
    local sendCmd = AllianceParameters.ReadAllianceLeaderChangeParameter.new()
    sendCmd:Send()
end

function AllianceModule:IsAllianceLeaderAFKorNoActive()
    local allianceData = self:GetMyAllianceData()
    return allianceData.AllianceLeaderCtrl.IsNoActive or allianceData.AllianceLeaderCtrl.IsAFK
end

function AllianceModule:IsOnlyLeaderLeft()
    local allianceData = self:GetMyAllianceData()
    local leaderId = allianceData.AllianceBasicInfo.LeaderID
    local member = allianceData.AllianceMembers.Members
    for i, v in pairs(member) do
        if v.FacebookID ~= leaderId then
            return false
        end
    end
    return true
end

function AllianceModule:HasNoneAllianceBuilding()
    local mapBuildings = self:GetMyAllianceDataMapBuildingBriefs()
    if table.isNilOrZeroNums(mapBuildings) then
        return true
    end
    for i, v in pairs(mapBuildings) do
        if v.EntityTypeHash ~= DBEntityType.Village then
            return false
        end
    end
    return true
end

function AllianceModule:HasNoneActivityBattle()
    local myAllianceData = self:GetMyAllianceData()
    for id, v in pairs(myAllianceData.AllianceActivityBattles.Battles) do
        if v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated 
                or v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
            return false, id
        end
    end
    return true, nil
end

---@return wds.AllianceGifts|nil,number[],AllianceEnergyBoxConfigCell|nil,AllianceGiftLevelConfigCell|nil
function AllianceModule:GetAllianceEnergyBoxInfo()
    local myAllianceData = self:GetMyAllianceData()
    local giftInfo = myAllianceData and myAllianceData.AllianceGifts
    local boxCfgs = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance.EnergyBoxCfgs
    ---@type AllianceEnergyBoxConfigCell
    local energyBoxConfig = nil
    ---@type AllianceGiftLevelConfigCell
    local levelConfig = nil
    if giftInfo then
        energyBoxConfig = self._allianceEnergyBoxLevelConfig[giftInfo.EnergyBoxLevel]
        if not energyBoxConfig then
            if giftInfo.EnergyBoxLevel > self._maxAllianceEnergyBoxLevelConfig:Level() then
                energyBoxConfig = self._maxAllianceEnergyBoxLevelConfig
            else
                energyBoxConfig = self._minAllianceEnergyBoxLevelConfig
            end
        end
        levelConfig = self._allianceGiftLevelConfig[giftInfo.GiftLevel]
        if not levelConfig and self._maxAllianceGiftLevelConfig then
            if giftInfo.GiftLevel > self._maxAllianceGiftLevelConfig:Level() then
                levelConfig = self._maxAllianceGiftLevelConfig
            else
                levelConfig = self._minAllianceGiftLevelConfig
            end
        end
    end
    return giftInfo, boxCfgs, energyBoxConfig, levelConfig
end

function AllianceModule:GetAllianceGiftsList()
    local sendCmd = AllianceParameters.GetAllianceGiftsListParameter.new()
    sendCmd:Send()
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param giftId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:GetAllianceGiftReward(lockable, giftId, callback)
    local sendCmd = AllianceParameters.GetAllianceGiftRewardParameter.new()
    sendCmd.args.GiftId = giftId
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:wrpc.GetNormalAllianceGiftRewardReply)
function AllianceModule:GetBatchAllianceNormalGiftReward(lockable, callback)
    local sendCmd = AllianceParameters.GetNormalAllianceGiftRewardParameter.new()
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:ClearHaveGetGifts(lockable, callback)
    local sendCmd = AllianceParameters.ClearHaveGetGiftsParameter.new()
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param ids number[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:OpenAllianceEnergyBox(lockable, ids, callback)
    local sendCmd = AllianceParameters.OpenAllianceEnergyBoxParameter.new()
    sendCmd.args.BoxCfgIds:AddRange(ids)
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

function AllianceModule:CanShowGreyHelpRequestBubble()
    return (self._lastSetGreyHelpRequestBubbleTime + self._setGreyHelpRequestBubbleTimeCd) < g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

function AllianceModule:MarkShowGreyHelpRequestBubble()
    self._lastSetGreyHelpRequestBubbleTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_SET_HELP_REQUEST_GREY_TIME)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:RequestImpeachNewLeader(lockable, callback)
    local sendCmd = AllianceParameters.RequestImpeachNewLeaderParameter.new()
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

function AllianceModule:GetJoinAllianceCD()
    local joinCd = ConfigRefer.AllianceConsts:NewbieJoinCoolDown()
    return ConfigTimeUtility.NsToSeconds(joinCd)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param villageId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:TransformAllianceCenter(lockable, villageId, callback, userData)
	local sendCmd = AllianceParameters.TransformAllianceCenterParameter.new()
	sendCmd.args.VillageId = villageId
	sendCmd:SendOnceCallback(lockable, userData, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param villageId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule:ChangeAllianceCenter(lockable, villageId, callback, userData)
	local sendCmd = AllianceParameters.ChangeAllianceCenterParameter.new()
	sendCmd.args.VillageId = villageId
	sendCmd:SendOnceCallback(lockable, userData, nil, callback)
end

---@param serverData wds.AllianceMapLabel
---@return string
function AllianceModule.BuildContentInfo(serverData)
    if serverData.Type == require("AllianceMapLabelType").ConveneCenter then
        local config = ConfigRefer.AllianceMapLabel:Find(serverData.ConfigId)
        if config then
            return I18N.Get(config:DefaultDesc())
        else
            return serverData.Content
        end
    end

    local content = serverData.Content
    if not string.IsNullOrEmpty(content) then return content end
    local config = ConfigRefer.AllianceMapLabel:Find(serverData.ConfigId)
    if config then
        content = I18N.Get(config:DefaultDesc())
    end
    if not string.IsNullOrEmpty(content) then return content end
    local typeHash = serverData.TargetTypeHash
    if BattleSignalConfig.FixedMapBuildingType[typeHash] then
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(serverData.TargetConfigId)
        if buildingConfig then
            content = ("Lv.%d %s"):format(buildingConfig:Level(), I18N.Get(buildingConfig:Name()))
        end
    end
    if not string.IsNullOrEmpty(content) then return content end
    if BattleSignalConfig.FlexibleMapBuildingType[typeHash] then
        local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(serverData.TargetConfigId)
        if buildingConfig then
            content = ("Lv.%d %s"):format(buildingConfig:Level(), I18N.Get(buildingConfig:Name()))
        end
    end
    if not string.IsNullOrEmpty(content) then return content end
    if BattleSignalConfig.MobTypeHash[typeHash] then
        local name,_,level,_ = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfigId(serverData.TargetConfigId)
        content = ("Lv.%d %s"):format(level, name)
    end
    if not string.IsNullOrEmpty(content) then return content end
    local dynamicData = serverData.DynamicParam
    if string.IsNullOrEmpty(dynamicData.TargetAllianceName) then
        content = dynamicData.TargetName
    else
        content = ("[%s]%s"):format(dynamicData.TargetAllianceName, dynamicData.TargetName)
    end
    return content
end

---@param battles table<number, wds.VillageAllianceWarInfo>
---@param startAttack PushConfigCell
---@param endAttack PushConfigCell
---@param nowTime number
---@param setFuncCallback fun(id:number,title:string,subtitle:string,content:string,delay:number,userData:string)
function AllianceModule:BuildVillageWarsNotification(battles, startAttack, endAttack, nowTime, setFuncCallback)
    if not setFuncCallback then return end
    if not startAttack and not endAttack then return end
    ---@type wds.VillageAllianceWarInfo
    local pushStart
    ---@type wds.VillageAllianceWarInfo
    local pushEnd
    for _, value in pairs(battles) do
        if value.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            if startAttack and value.StartTime > nowTime then
                if not pushStart or pushStart.StartTime > value.StartTime then
                    pushStart = value
                end
            end
        elseif value.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            if endAttack and value.EndTime > nowTime then
                if not pushEnd or pushEnd.EndTime > value.EndTime then
                    pushEnd = value
                end
            end
        end
    end
    if pushStart then
        local id = startAttack:Id()
        local title = I18N.Get(startAttack:Title())
        local subTitle = I18N.Get(startAttack:SubTitle())
        local content = I18N.Get(startAttack:Content())
        local delay = pushStart.StartTime - nowTime
        setFuncCallback(id, title, subTitle, content, delay)
    end
    if pushEnd then
        local id = endAttack:Id()
        local title = I18N.Get(endAttack:Title())
        local subTitle = I18N.Get(endAttack:SubTitle())
        local content = I18N.Get(endAttack:Content())
        local delay = pushEnd.EndTime - nowTime
        setFuncCallback(id, title, subTitle, content, delay)
    end
end

---@param battles table<number, wds.VillageAllianceWarInfo>
---@param startAttackTM10 PushConfigCell
---@param startAttack PushConfigCell
---@param nowTime number
---@param setFuncCallback fun(id:number,title:string,subtitle:string,content:string,delay:number,userData:string)
function AllianceModule:BuildBehemothCageWarsNotification(battles, startAttackTM10, startAttack, nowTime, setFuncCallback)
    if not setFuncCallback then return end
    if not startAttackTM10 and not startAttack then return end
    local nowTime10M = nowTime + 10 * 60
    ---@type wds.VillageAllianceWarInfo
    local pushStartTM10
    ---@type wds.VillageAllianceWarInfo
    local pushPrepare
    for _, value in pairs(battles) do
        if value.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            if startAttackTM10 and value.StartTime > nowTime10M then
                if not pushStartTM10 or pushStartTM10.StartTime > value.StartTime then
                    pushStartTM10 = value
                end
            end
            if startAttack and value.StartTime > nowTime then
                if not pushPrepare or pushPrepare.StartTime > value.EndTime then
                    pushPrepare = value
                end
            end
        end
    end
    if pushStartTM10 then
        local id = startAttackTM10:Id()
        local title = I18N.Get(startAttackTM10:Title())
        local subTitle = I18N.Get(startAttackTM10:SubTitle())
        local content = I18N.Get(startAttackTM10:Content())
        local delay = pushStartTM10.StartTime - nowTime10M
        setFuncCallback(id, title, subTitle, content, delay)
    end
    if pushPrepare then
        local id = startAttack:Id()
        local title = I18N.Get(startAttack:Title())
        local subTitle = I18N.Get(startAttack:SubTitle())
        local content = I18N.Get(startAttack:Content())
        local delay = pushPrepare.StartTime - nowTime
        setFuncCallback(id, title, subTitle, content, delay)
    end
end

---@param setFuncCallback fun(id:number,title:string,subtitle:string,content:string,delay:number,userData:string)
function AllianceModule:OnSetLocalNotification(setFuncCallback)
    if not setFuncCallback then return end
    if not self:IsInAlliance() then return end
    local allianceData = self:GetMyAllianceData()
    if not allianceData then return end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local startAttack = ConfigRefer.Push:Find(ConfigRefer.PushConst:VillageAttackStart())
    local endAttack = ConfigRefer.Push:Find(ConfigRefer.PushConst:VillageAttackEnd())
    -- 乡镇
    local allWars = {}
    local villageBattles = self:GetMyAllianceVillageWars()
    local passBattles = self:GetMyAllianceGateWars()
    for _, value in pairs(villageBattles) do
        allWars[#allWars + 1] = value
    end
    for _, value in pairs(passBattles) do
        allWars[#allWars + 1] = value
    end
    self:BuildVillageWarsNotification(allWars, startAttack, endAttack, nowTime, setFuncCallback)
    -- 巨兽
    if not self.Behemoth then return end
    -- 巨兽巢穴
    local behemothCageWars = self:GetMyAllianceBehemothCageWar()
    local cageWarTM10 = ConfigRefer.Push:Find(ConfigRefer.PushConst:BehemothCageAttackTM10())
    local cageWarPrepare = ConfigRefer.Push:Find(ConfigRefer.PushConst:BehemothCageAttackPrepare())
    self:BuildBehemothCageWarsNotification(behemothCageWars, cageWarTM10, cageWarPrepare, nowTime, setFuncCallback)
    -- 巨兽挑战
    local challengeInfos = self.Behemoth:GetCurrentBehemothActivityWar()
    if not challengeInfos then return end
    local behemothChallengeTM10 = ConfigRefer.Push:Find(ConfigRefer.PushConst:BehemothChallengeTM10())
    local behemothChallengeStart = ConfigRefer.Push:Find(ConfigRefer.PushConst:BehemothChallengeStart())
    if challengeInfos.Status >= wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated
        and challengeInfos.Status < wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling
    then
        local battleStartTime = challengeInfos.StartBattleTime.ServerSecond
        if battleStartTime < nowTime then return end
        if behemothChallengeTM10 and battleStartTime > (nowTime + 10 * 60) then
            local id = behemothChallengeTM10:Id()
            local title = I18N.Get(behemothChallengeTM10:Title())
            local subTitle = I18N.Get(behemothChallengeTM10:SubTitle())
            local content = I18N.Get(behemothChallengeTM10:Content())
            local delay = battleStartTime - (nowTime + 10 * 60)
            setFuncCallback(id, title, subTitle, content, delay)
        end
        if behemothChallengeStart and battleStartTime > nowTime then
            local id = behemothChallengeStart:Id()
            local title = I18N.Get(behemothChallengeStart:Title())
            local subTitle = I18N.Get(behemothChallengeStart:SubTitle())
            local content = I18N.Get(behemothChallengeStart:Content())
            local delay = battleStartTime - nowTime
            setFuncCallback(id, title, subTitle, content, delay)
        end
    end
end

---@param teamInfo wds.AllianceTeamInfo
function AllianceModule:CheckAddAssembleInfoToChat(id, teamInfo)
    local allianceSession = ModuleRefer.ChatModule:GetAllianceSession()
    if not allianceSession then return end
    ModuleRefer.ChatModule:SendAllinceAssemnbleInfoMsg(allianceSession.SessionId, id, teamInfo)
end

function AllianceModule:GetDailyRewardState()
    local res
    local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    if curT < playerAlliance.NextGetDailyFactionRewardTime.Seconds then
        res = CommonDailyGiftState.HasCliamed
    else
        res = CommonDailyGiftState.CanCliam
    end
    return res
end

function AllianceModule:IsLeadboardUnlock()
    local systemEntryId = ConfigRefer.LeaderBoardConst:UnlockSystemEntry()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntryId)
end

function AllianceModule:IsHonorPageUnlock()
    local systemEntryId = ConfigRefer.LeaderBoardConst:HonorUnlockSystemEntry()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntryId)
end

--邀请玩家cd
function AllianceModule:AddInviteTimer(playerId)
    if self.invitePlayerCDs[playerId] then
        return false
    end
    
    self.invitePlayerCDs[playerId] = TimerUtility.DelayExecute(function()
        if self.invitePlayerCDs[playerId] then
            TimerUtility.StopAndRecycle(self.invitePlayerCDs[playerId])
            self.invitePlayerCDs[playerId] = nil
        end
    end,ConfigRefer.AllianceConsts:AllianceInvitePlayerCD())
    return true
end

function AllianceModule:IsInvitedPlayer(playerId)
    return self.invitePlayerCDs[playerId] == nil
end

function AllianceModule:DestroyInviteTimer()
    for k,v in pairs(self.invitePlayerCDs) do
        if v then
            TimerUtility.StopAndRecycle(v)
        end
    end
    self.invitePlayerCDs = {}
end

--获得活跃联盟推荐信息
function AllianceModule:GetRecommendation()
    local res = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance.PlayerAllianceWrapper.PlayerAllianceRecommend.RecommendAlliances
    if res and res[1] then
        return res[1]
    else
        return nil
    end
end

--更新活跃联盟推荐信息
function AllianceModule:OnRecommendAllianceChanged(entity,_)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_RECOMMENDATION_CHANGED, ConfigRefer.AllianceConsts:AllianceFurnitureId())
end

-- 联盟盟主发起召集
function AllianceModule:SendAllianceConvene(callback)
    local parameter = AllianceParameters.AllianceConveneMembersParameter.new()
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_gathering_point_6"))
            if callback then
                callback()
            end
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Error"))
        end
    end)
end

function AllianceModule:CheckCanSetAllianceGatherPoint()
    if not self:IsInAlliance() then
        return false
    end

    if not self:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel) then
        return false
    end
    
    return true 
end

---@param tile MapRetrieveResult
function AllianceModule:SetAllianceGatherPoint(tile)
    local tileX, tileZ
    if tile.entity then
        tileX, tileZ = KingdomMapUtils.ParseBuildingPos(tile.entity.MapBasics.Position)
    else
        tileX, tileZ = tile.X, tile.Z
    end
    local parameter = require("AddAllianceMapLabelParameter").new()
    parameter.args.ConfigId = ConfigRefer.AllianceConsts:AllianceConveneLabel()
    parameter.args.X = tileX
    parameter.args.Y = tileZ
    parameter.args.Type = require("AllianceMapLabelType").ConveneCenter
    parameter:Send()
end

return AllianceModule
