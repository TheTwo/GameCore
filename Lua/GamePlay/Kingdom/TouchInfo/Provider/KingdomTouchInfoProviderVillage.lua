local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")

local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuCellPairSpecialDatum = require("TouchMenuCellPairSpecialDatum")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuCellProgressDatum = require("TouchMenuCellProgressDatum")
local TouchMenuCellLeagueDatum = require("TouchMenuCellLeagueDatum")
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")

local TMCellRewardPairDatum = require("TMCellRewardPairDatum")
local TMCellRewardSpecialPairDatum = require("TMCellRewardSpecialPairDatum")
local TouchMenuCellRewardPairListDatum = require("TouchMenuCellRewardPairListDatum")
local TMCellRewardPetDatum = require("TMCellRewardPetDatum")
local TMCellRewardsHorizontalDatum = require("TMCellRewardsHorizontalDatum")

local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local TouchMenuHelper = require("TouchMenuHelper")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")

local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ColorConsts = require("ColorConsts")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local VillageSubType = require("VillageSubType")
local ItemGroupType = require("ItemGroupType")
local MapBuildingSubType = require("MapBuildingSubType")
local TouchMenuCellPairTimeDatum = require('TouchMenuCellPairTimeDatum')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')

---@class KingdomTouchInfoProviderVillage : KingdomTouchInfoProvider
local KingdomTouchInfoProviderVillage = class("KingdomTouchInfoProviderVillage", KingdomTouchInfoProvider)

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage:CreateBasicInfo(tile)
    ---@type wds.Village
    local entity = tile.entity
    local fixedMapBuildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)

    local basicInfo = KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    basicInfo:SetTipsOnClick(function()
        g_Game.EventManager:TriggerEvent(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, I18N.Get(fixedMapBuildingConfig:Des()))
    end)

    if ModuleRefer.VillageModule:CanStopRebuild(entity) then
        basicInfo:SetClickBtnDelete(function()
            KingdomTouchInfoProviderVillage.StopRebuild(entity)
        end)
    end
    return basicInfo
end

---@param entity wds.Village
function KingdomTouchInfoProviderVillage.GetOccupyInfoPart(entity)
    local clickCallback = function()
        KingdomTouchInfoOperation.OccupationHistory({entity = entity, entityPath = DBEntityPath.Village})
    end
    local pairOccupiedAlliances = TouchMenuHelper.GetAllianceLogoDatum(entity, clickCallback)
    return pairOccupiedAlliances
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage:CreateDetailInfo(tile)
    ---@type wds.Village
    local entity = tile.entity
    local isNeutral = ModuleRefer.PlayerModule:IsNeutral(entity.Owner.AllianceID)

    if ModuleRefer.RadarModule:GetScout(entity) then
        local ret = {}
        return ret
    end

    local ret = {}

    --据点守军
    if entity.Army and table.nums(entity.Army.DummyTroopIDs) > 0 then
        local hpRatioFunc = function()
            local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetNpcTroopHP(entity.Army)
            return hp / hpMax
        end
        local hpStrFunc = function()
            local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetNpcTroopHP(entity.Army)
            return string.format("<b>%d</b>/%d", hp, hpMax)
        end
        local progressHP = TouchMenuCellProgressDatum.new(
                nil, I18N.Get("village_info_Garrison_Defenders"), hpRatioFunc,
                nil,nil,true,hpStrFunc
        )
        progressHP:SetGoto(function()
            if isNeutral then
                ModuleRefer.MapBuildingTroopModule:ShowNpcTroopInfo(tile)
            else
                ModuleRefer.MapBuildingTroopModule:ShowTroopInfo(tile, true)
            end
        end)
        local creepBuff,creepBuffIcon,buffValue = ModuleRefer.MapCreepModule.GetCreepSpreadBuffCount(entity.CreepSpread)
        progressHP:SetCreepBufferCount(creepBuffIcon, creepBuff, function(clickTrans, datum)
            if datum.creepBuff then
                local content = I18N.GetWithParams("duzhu_qianghua", tostring(datum.creepBuff)) .. buffValue
                ModuleRefer.ToastModule:SimpleShowTextToastTip(content, clickTrans)
            end
        end)
        table.insert(ret, progressHP)
    end
    

    --耐久度
    local durabilityProgressFunc = function()
        return entity.Battle.Durability / entity.Battle.MaxDurability
    end   
    local durabilityValueFunc = function()
        return string.format("<b>%d</b>/%d", entity.Battle.Durability, entity.Battle.MaxDurability)
    end
    local progressDurability = TouchMenuCellProgressDatum.new(
        nil, I18N.Get("xiangzhen_naijiu"), durabilityProgressFunc,
        nil,nil,true,durabilityValueFunc
    )
    table.insert(ret, progressDurability)

    --推荐编队数量
    local fixedMapBuildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    if entity.Army and table.nums(entity.Army.DummyTroopIDs) > 0 then
        if isNeutral then
            -- local troopCount = tostring(ModuleRefer.MapBuildingTroopModule:GetTotalTroopCount(entity.Army, entity.MapBasics, nil))
            local suggestTeamCount = fixedMapBuildingConfig:SuggestAttackTeamCount()
            local pairTroopComp = TouchMenuCellPairDatum.new(I18N.Get("xiangzhen_shoujun"), tostring(suggestTeamCount))
            pairTroopComp:SetBlackSprite("sp_hud_icon_friends")
            table.insert(ret, pairTroopComp)
        end
    end

    --占领收益
    local pairBenefits = self:GetBenefitPair(entity, fixedMapBuildingConfig)

    local rewardPairListDatum = TouchMenuCellRewardPairListDatum.new(I18N.Get("village_info_Occupy_gains"), pairBenefits, function()
        KingdomTouchInfoOperation.OccupationGainDetail({tile = tile, entityPath = DBEntityPath.Village})
    end)
    table.insert(ret, rewardPairListDatum)
    
    --据点重建
    if ModuleRefer.VillageModule:IsVillageRuinRebuilding(entity) then
        --重建联盟
        local clickCallback = function()
            g_Game.UIManager:Open(UIMediatorNames.AllianceInfoPopupMediator, {allianceId = entity.BuildingRuinRebuild.AllianceId, tab = 1})
        end
        local allianceInfo = entity.BuildingRuinRebuild.AllianceInfo
        local allianceStr = ModuleRefer.PlayerModule.FullName(allianceInfo.AllianceAbbr, allianceInfo.AllianceName)
        local color
        if ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
            color = UIHelper.TryParseHtmlString(ColorConsts.army_blue)
        else
            color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        end
        local pairOccupiedAlliances = TouchMenuCellLeagueDatum.new(allianceStr, color, allianceInfo.AllianceFlag.BadgeAppearance, allianceInfo.AllianceFlag.BadgePattern, clickCallback)
        table.insert(ret, pairOccupiedAlliances)

        local buildTimerLabel = I18N.Get("village_outpost_info_time_remaining")
        local buildEndTime = ModuleRefer.VillageModule:GetVillageRebuildEndTime(entity)
        local buildTimerData = TouchMenuHelper.GetSecondTickCommonTimerData(buildEndTime)
        local buildTimerPair = TouchMenuCellPairTimeDatum.new(buildTimerLabel, buildTimerData)
        table.insert(ret, buildTimerPair)

        if ModuleRefer.PlayerModule:IsFriendlyById(entity.BuildingRuinRebuild.AllianceId) then
            if ModuleRefer.VillageModule:IsVillageInProtection(entity) then
                local protectTimerLabel = I18N.Get("village_outpost_info_protection_remaining")
                local protectEndTime = entity.MapStates.StateWrapper.ProtectionExpireTime
                local protectTimerData = TouchMenuHelper.GetSecondTickCommonTimerData(protectEndTime)
                local protectTimerPair = TouchMenuCellPairTimeDatum.new(protectTimerLabel, protectTimerData)
                table.insert(ret, protectTimerPair)
            end

            local memberCount = table.nums(entity.Strengthen.PlayerTroopIDs)
            local memberLabel = I18N.Get("village_outpost_info_assistance_team")
            local gotoCallback = function()
                g_Game.UIManager:Open(UIMediatorNames.VillageRebuildTroopUIMediator, entity.Strengthen)
            end
            local memberPair = TouchMenuCellPairDatum.new(memberLabel, memberCount):SetGotoCallback(gotoCallback)
            table.insert(ret, memberPair)
        end
    else
        --占领联盟
        local pairOccupiedAlliances = KingdomTouchInfoProviderVillage.GetOccupyInfoPart(entity)
        table.insert(ret, pairOccupiedAlliances)
    end

    return ret
end

function KingdomTouchInfoProviderVillage:GetBenefitPair(entity, fixedMapBuildingConfig)
    local pairBenefits = {}
    local isMyAllianceCenter = ModuleRefer.VillageModule:IsAllianceCenter(entity) and ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId() == entity.ID

    if fixedMapBuildingConfig:VillageSub() == VillageSubType.PetZoo  then
        -- table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc()), string.Empty, string.Empty))
        table.insert(pairBenefits, TMCellRewardsHorizontalDatum.new(nil, I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc())))
    end
    if fixedMapBuildingConfig:VillageSub() == VillageSubType.Economy then
        -- table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc()), string.Empty, string.Empty))
        local economyMail = ConfigRefer.Mail:Find(fixedMapBuildingConfig:DailyAllianceRewardMail())
        if economyMail then
            local itemGroup = ConfigRefer.ItemGroup:Find(economyMail:Attachment())
            if itemGroup and (itemGroup:Type() == ItemGroupType.OneByOne or itemGroup:ItemGroupInfoListLength() > 0) then
                ---@type TMCellRewardsHorizontalDatumCellData[]
                local cells = {}
                for i = 1, itemGroup:ItemGroupInfoListLength() do
                    local itemInfo = itemGroup:ItemGroupInfoList(i)
                    ---@type TMCellRewardsHorizontalDatumCellData
                    local item = {}
                    item.itemPayload = {}
                    item.itemPayload.configCell = ConfigRefer.Item:Find(itemInfo:Items())
                    item.itemPayload.count = itemInfo:Nums()
                    table.insert(cells, item)
                end
                table.insert(pairBenefits, TMCellRewardsHorizontalDatum.new(cells, I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc())))
            end
        end
    end

    ---@type table<number, AttrTypeAndValue> @
    local appendAttr = {}
    if isMyAllianceCenter then
        local allianceCenterConfig = ConfigRefer.AllianceCenter:Find(fixedMapBuildingConfig:BuildAllianceCenter())
        if allianceCenterConfig then
            local appendAttrGroup = ConfigRefer.AttrGroup:Find(allianceCenterConfig:AllianceAttrGroup())
            if appendAttrGroup and appendAttrGroup:AttrListLength() > 0 then
                for i = 1, appendAttrGroup:AttrListLength() do
                    local pair = appendAttrGroup:AttrList(i)
                    appendAttr[pair:TypeId()] = pair
                end
            end
        end
    end

    local needAppendPetExtra = false
    --if fixedMapBuildingConfig:VillageSub() == VillageSubType.PetZoo then
    --    if fixedMapBuildingConfig:VillageShowExtraPetItemLength() > 0 then
    --        table.insert(pairBenefits, TMCellRewardsHorizontalDatum.new(nil, I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc())))
    --        local petConfigIds = {}
    --        -- ---@type TMCellRewardPetDatum
    --        -- local cellData = TMCellRewardPetDatum.new(I18N.Get("village_newpet_after_occupied"), petConfigIds)
    --        for i = 1, fixedMapBuildingConfig:VillageShowExtraPetItemLength() do
    --            ---@type TMCellRewardsHorizontalDatumCellData
    --            local petDatum = {}
    --            petDatum.petPayload = {}
    --            petDatum.petPayload.id = 0
    --            petDatum.petPayload.cfgId = fixedMapBuildingConfig:VillageShowExtraPetItem(i)
    --            table.insert(petConfigIds, petDatum)
    --        end
    --        local cellData = TMCellRewardsHorizontalDatum.new(petConfigIds)
    --        table.insert(pairBenefits, cellData)
    --    end
    --    needAppendPetExtra = true
    --end
    if fixedMapBuildingConfig:SubType() == MapBuildingSubType.Stronghold
            or fixedMapBuildingConfig:VillageSub() == VillageSubType.Military
            or fixedMapBuildingConfig:VillageSub() == VillageSubType.PetZoo then
        local allianceAttr = ConfigRefer.AttrGroup:Find(fixedMapBuildingConfig:AllianceAttrGroup())
        if allianceAttr and not needAppendPetExtra then
            if allianceAttr and allianceAttr:AttrListLength() > 0 then
                ---@type {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string}}[]
                local allianceGainAttr = {}
                for i = 1, allianceAttr:AttrListLength() do
                    local attrTypeAndValue = allianceAttr:AttrList(i)
                    local attrTypeId = attrTypeAndValue:TypeId()
                    local appendValue = appendAttr[attrTypeId]
                    if appendValue then
                        appendAttr[attrTypeId] = nil
                        local baseValue = attrTypeAndValue:Value()
                        attrTypeAndValue = {
                            TypeId = function(_)
                                return attrTypeId
                            end,
                            Value = function(_)
                                return baseValue + appendValue:Value()
                            end,
                        }
                    end
                    ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, allianceGainAttr, true)
                    local v = allianceGainAttr[1]
                    allianceGainAttr[1] = nil
                    table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(v.cellData.strLeft, v.cellData.strRight, v.cellData.icon))
                end
            end
        end
    end

    if needAppendPetExtra then
        table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc()), string.Empty, string.Empty))
    end

    if not needAppendPetExtra then
        if fixedMapBuildingConfig:SubType() == MapBuildingSubType.Stronghold or fixedMapBuildingConfig:VillageSub() == VillageSubType.Military then
            if fixedMapBuildingConfig:VillageSub() ~= VillageSubType.Military then
                local currencyConfig = ConfigRefer.AllianceCurrency:Find(fixedMapBuildingConfig:OccupyAllianceCurrencyType())
                local currencyNum = fixedMapBuildingConfig:OccupyAllianceCurrencyNum()
                if currencyConfig and currencyNum > 0 then
                    local pairBenefitComp = TMCellRewardPairDatum.new(I18N.Get(currencyConfig:Name()), ("+%s"):format(currencyNum), currencyConfig:Icon())
                    table.insert(pairBenefits, pairBenefitComp)
                end
                if fixedMapBuildingConfig:FactionValue() > 0 then
                    table.insert(pairBenefits, TMCellRewardPairDatum.new(I18N.Get("village_info_Alliance_forces"), ("+%s"):format(fixedMapBuildingConfig:FactionValue()), "sp_comp_icon_achievement_1"))
                end
            end
            if fixedMapBuildingConfig:VillageSub() ~= VillageSubType.Military then
                local attr = entity.Village.RandomAllianceAttrGroup
                ---@type {cellData:{strLeft:string,strRight:string,icon:string}}[]
                local addToTable = {}
                for _, v in ipairs(attr) do
                    local attrGroup = ConfigRefer.AttrGroup:Find(v)
                    if attrGroup then
                        for i = 1, attrGroup:AttrListLength() do
                            ModuleRefer.VillageModule.ParseAttrInfo(attrGroup:AttrList(i), addToTable, true)
                        end
                    end
                end
                for _, v in ipairs(addToTable) do
                    local pairBenefitComp = TMCellRewardPairDatum.new(v.cellData.strLeft, v.cellData.strRight, v.cellData.icon)
                    table.insert(pairBenefits, pairBenefitComp)
                end
            end
        end
    end
    
    return pairBenefits
end

---@param tile MapRetrieveResult
---@return TouchMenuButtonTipsData
function KingdomTouchInfoProviderVillage:CreateTipData(tile)
    local village = tile.entity
    if ModuleRefer.PlayerModule:IsFriendly(village.Owner) then
        return nil
    end

    local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
    local _, timestamp = ModuleRefer.VillageModule:GetVillageCountDown(village, allianceID)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    
    local getTip = function(village)
        if ModuleRefer.VillageModule:IsVillageRuined(village) then
            local canRebuild, tipRebuild = ModuleRefer.VillageModule:GetCanRebuildVillageToast(village)
            return tipRebuild
        else
            local canSign, tipSign = ModuleRefer.VillageModule:GetCanSignAttackVillageToast(village)
            return tipSign
        end
    end
    
    if timestamp > nowTime then
        local tipFunc = function()
            local textKey, timestampInFunc = ModuleRefer.VillageModule:GetVillageCountDown(tile.entity, allianceID)
            local tip = string.Empty
            local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
            local remainTime = timestampInFunc - serverTime
            if remainTime >= 0 then
                local timeStr = TimeFormatter.SimpleFormatTimeWithDay(remainTime)
                tip = I18N.GetWithParams(textKey, timeStr)
            else
                tip = getTip(village)
            end
            return tip
        end

        return TouchMenuButtonTipsData.new():SetContent(tipFunc)
    else
        local tip = getTip(village)
        return TouchMenuButtonTipsData.new():SetContent(tip)
    end
end

---@class KingdomTouchInfoProviderVillage.ButtonFlags
KingdomTouchInfoProviderVillage.ButtonFlags = {
    none = 0,
    buttonCancelDrop = 1 << 0,
    buttonDrop = 1 << 1,
    buttonRetreat = 1 << 2,
    buttonGarrison = 1 << 3,
    buttonCancelDeclare = 1 << 4,
    buttonManagedAttack = 1 << 5,
    buttonAttack = 1 << 6,
    buttonWarDetail = 1 << 7,
    buttonDeclareWarDisabled = 1 << 8,
    buttonDeclareWarEnabled = 1 << 9,
    buttonSummonBehemothEnabled = 1 << 10,
    buttonSummonBehemothDisabled = 1 << 11,
    buttonTransformToAllianceCenter = 1 << 12,
    buttonChangeToAllianceCenter = 1 << 13,
    buttonTransformToAllianceCenterSpeedUp = 1 << 14,
    buttonTransformToAllianceCenterDisabled = 1 << 15,
    buttonChangeToAllianceCenterDisabled = 1 << 16,
    buttonScout = 1 << 17,
    buttonScoutFogUnlock = 1 << 18,
    buttonManagedAttackDisabled = 1 << 19,
    buttonAttackDisabled = 1 << 20,
    buttonStartRebuild = 1 << 21,
    buttonStartRebuildDisabled = 1 << 22,
    buttonJoinRebuild = 1 << 23,
    buttonSummonAllianceMembers = 1 << 24,
    buttonAllianceGather = 1 << 26,
}

---@param village wds.Village
---@return KingdomTouchInfoProviderVillage.ButtonFlags number[FLAGS]
function KingdomTouchInfoProviderVillage.GetKingdomTouchInfoProviderVillageButtonFlags(village)
    local btnFlags = KingdomTouchInfoProviderVillage.ButtonFlags
    ---@type KingdomTouchInfoProviderVillage.ButtonFlags
    local ret = KingdomTouchInfoProviderVillage.ButtonFlags.none
    local VillageModule = ModuleRefer.VillageModule
    local AllianceModule = ModuleRefer.AllianceModule
    
    local allianceID = AllianceModule:GetAllianceId()

    local needScout = ModuleRefer.RadarModule:GetScout(village)
    if needScout then
        local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(village.MapBasics.Position)
        if ModuleRefer.MapFogModule:IsFogUnlocked(tileX, tileZ) then
            ret = ret | btnFlags.buttonScout
        else
            ret = ret | btnFlags.buttonScoutFogUnlock
        end
        return ret
    end

    --乡镇援建
    if VillageModule:IsVillageRuined(village) then
        local can, _ = VillageModule:GetCanRebuildVillageToast(village)
        if can then
            ret = ret | btnFlags.buttonStartRebuild
        else
            ret = ret | btnFlags.buttonStartRebuildDisabled
        end
        return ret
    elseif VillageModule:IsVillageRuinRebuilding(village) then
        local rebuildAllianceID = village.BuildingRuinRebuild.AllianceId
        if rebuildAllianceID == allianceID then
            ret = ret | btnFlags.buttonJoinRebuild
            ret = ret | btnFlags.buttonSummonAllianceMembers
        else
            if VillageModule:IsVillageInProtection(village) then
                ret = ret | btnFlags.buttonAttackDisabled
            else
                ret = ret | btnFlags.buttonAttack
            end
        end
        return ret
    end
    
    local villageWarStatus = VillageModule:GetVillageWarStatus(village.ID, allianceID)
    local can, _ = VillageModule:GetCanSignAttackVillageToast(village)
    local sasDeclareWarOnVillage = VillageModule:HasDeclareWarOnVillage(village.ID)
    if ModuleRefer.PlayerModule:IsFriendly(village.Owner) then
        local inDrop = false
        if VillageModule:IsVillageInDrop(village, allianceID) then
            if VillageModule:IsAllianceCenter(village) then
                if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DropAllianceCenter) then
                    ret = ret | btnFlags.buttonCancelDrop
                end
            else
                if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DropVillage) then
                    ret = ret | btnFlags.buttonCancelDrop
                end
            end
            inDrop = true
        else
            if VillageModule:IsAllianceCenter(village) then
                if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DropAllianceCenter) then
                    ret = ret | btnFlags.buttonDrop
                end
                if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel) then
                    ret = ret | btnFlags.buttonAllianceGather
                end
            elseif village.VillageTransformInfo.Status ~= wds.VillageTransformStatus.VillageTransformStatusProcessing then
                if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DropVillage) then
                    ret = ret | btnFlags.buttonDrop
                end
            end
        end
        if ModuleRefer.MapBuildingTroopModule:GetMyTroopCount(village.Army) > 0 then
            ret = ret | btnFlags.buttonRetreat
        else
            ret = ret | btnFlags.buttonGarrison
        end
        if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SummonBehemoth) then
            if AllianceModule.Behemoth:GetCurrentDeviceBuildingStatus() == wds.BuildingStatus.BuildingStatus_Constructed and AllianceModule.Behemoth:GetCurrentBindBehemoth() and
                AllianceModule.Behemoth:GetSummonerInfo() and AllianceModule.Behemoth:GetSummonerInfo()._building.Status == wds.BuildingStatus.BuildingStatus_Constructed and
                not AllianceModule.Behemoth:IsCurrentBehemothInSummon() then
                local enough, _, _ = AllianceModule.Behemoth:CheckHasEnoughCurrencyForSummon()
                if enough then
                    ret = ret | btnFlags.buttonSummonBehemothEnabled
                else
                    ret = ret | btnFlags.buttonSummonBehemothDisabled
                end
            end
        end
        if not inDrop and village.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusNone then
            if AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter) then
                local v = VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
                local cdLeftTime = VillageModule:GetTransformAllianceCenterCdEndTime() - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
                if not v then
                    if cdLeftTime > 0 then
                        ret = ret | btnFlags.buttonTransformToAllianceCenterDisabled
                    else
                        ret = ret | btnFlags.buttonTransformToAllianceCenter
                    end
                elseif v.AllianceCenterStatus ~= wds.VillageTransformStatus.VillageTransformStatusProcessing and v.Status == wds.BuildingStatus.BuildingStatus_Constructed then
                    if cdLeftTime > 0 then
                        ret = ret | btnFlags.buttonChangeToAllianceCenterDisabled
                    else
                        ret = ret | btnFlags.buttonChangeToAllianceCenter
                    end
                end
            end
        elseif village.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusProcessing then
            ret = ret | btnFlags.buttonTransformToAllianceCenterSpeedUp
            ret = ret & ~btnFlags.buttonGarrison
        end
    elseif sasDeclareWarOnVillage then
        if villageWarStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            ret = ret | btnFlags.buttonCancelDeclare
            ret = ret | btnFlags.buttonManagedAttackDisabled
            ret = ret | btnFlags.buttonAttackDisabled
        elseif villageWarStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder then
            ret = ret | btnFlags.buttonManagedAttack
            ret = ret | btnFlags.buttonAttack
            --if village.Village.InBattle then
            --    ret = ret | btnFlags.buttonWarDetail
            --end
        elseif villageWarStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction then
            ret = ret | btnFlags.buttonManagedAttack
            ret = ret | btnFlags.buttonAttack
        end
    else
        if (not can) or VillageModule:IsVillageInProtection(village) then
            ret = ret | btnFlags.buttonDeclareWarDisabled
        else
            ret = ret | btnFlags.buttonDeclareWarEnabled
        end
    end
    return ret
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage:CreateButtonInfo(tile)
    ---@type wds.Village
    local village = tile.entity

    local buttonDeclareWarEnabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Declare_war"), KingdomTouchInfoProviderVillage.DeclareWar, tile)
    local buttonDeclareWarDisabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Declare_war"), KingdomTouchInfoProviderVillage.DeclareWar, tile):SetEnable(false)
    local buttonCancelDeclare = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Cancel_declara"), KingdomTouchInfoProviderVillage.CancelDeclare, tile)
    local buttonScout = TouchMenuMainBtnDatum.new(I18N.Get("bw_radar_invest_btn"), KingdomTouchInfoProviderVillage.Scout, village)
    local buttonScoutFogUnlock = TouchMenuMainBtnDatum.new(I18N.Get("worldevent_qianwang"), KingdomTouchInfoProviderVillage.ScoutFogUnlock, village)

    local buttonTransformToAllianceCenter = TouchMenuMainBtnDatum.new(I18N.Get("alliance_center_info_build_btn"), KingdomTouchInfoProviderVillage.TransformToAllianceCenter, tile)
    local buttonTransformToAllianceCenterSpeedUp = TouchMenuMainBtnDatum.new(I18N.Get("djianzhu_zhiyuan"), KingdomTouchInfoProviderVillage.TransformToAllianceCenterSpeedUp, tile)
    local buttonChangeToAllianceCenter = TouchMenuMainBtnDatum.new(I18N.Get("alliance_center_info_change_btn"), KingdomTouchInfoProviderVillage.TransformToAllianceCenter, tile)
    local buttonTransformToAllianceCenterDisabled = TouchMenuMainBtnDatum.new(I18N.Get("alliance_center_info_build_btn")):SetOnClickDisable(function()
        local leftime = ModuleRefer.VillageModule:GetTransformAllianceCenterCdEndTime() - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_center_cooldown_countdown", TimeFormatter.SimpleFormatTime(math.max(0, leftime))))
    end)
    local buttonChangeToAllianceCenterDisabled = TouchMenuMainBtnDatum.new(I18N.Get("alliance_center_info_change_btn")):SetOnClickDisable(function()
        local leftime = ModuleRefer.VillageModule:GetTransformAllianceCenterCdEndTime() - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        if leftime > 0 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_center_cooldown_countdown", TimeFormatter.SimpleFormatTime(leftime)))
        end
    end)

    local buttonGarrison = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Garrison"), KingdomTouchInfoProviderVillage.Garrison, tile)
    local buttonRetreat = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Withdraw_troops"), KingdomTouchInfoProviderVillage.Retreat, tile)
    local buttonDrop = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Abandon"), KingdomTouchInfoProviderVillage.Drop, tile)
    local buttonCancelDrop = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Cancel_waiver"), KingdomTouchInfoProviderVillage.CancelDrop, tile)

    local buttonManagedAttack = TouchMenuMainBtnDatum.new(I18N.Get("alliance_team"), KingdomTouchInfoProviderVillage.ManagedAttack, tile)
    local buttonManagedAttackDisabled = TouchMenuMainBtnDatum.new(I18N.Get("alliance_team"), nil, nil, nil, nil, nil, false, function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips7"))
    end)
    local buttonAttack = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Attack"), KingdomTouchInfoProviderVillage.Attack, village)
    local buttonAttackDisabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Attack"), nil, nil, nil, nil, nil, false, function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_in_preparation"))
    end)
    local buttonWarDetail = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Battle_situation"), KingdomTouchInfoProviderVillage.WarDetail, tile)

    local buttonSummonBehemoth = TouchMenuMainBtnDatum.new(I18N.Get("seskill_category_summon"), KingdomTouchInfoProviderVillage.SummonBehemoth, tile)
    local buttonSummonBehemothDisabled = TouchMenuMainBtnDatum.new(I18N.Get("seskill_category_summon")):SetOnClickDisable(function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_ziyuanbuzu"))
    end)
    local _, currencyConfig, currencyCostCount = ModuleRefer.AllianceModule.Behemoth:CheckHasEnoughCurrencyForSummon()
    local currencyIcon = currencyConfig and currencyConfig:Icon()
    buttonSummonBehemoth:SetExtraImage(currencyIcon):SetExtraLabel(tostring(currencyCostCount))
    buttonSummonBehemothDisabled:SetExtraImage(currencyIcon):SetExtraLabel(tostring(currencyCostCount)):SetExtraLabelColor(CS.UnityEngine.Color.red):SetEnable(false)
    
    local buttonStartRebuild = TouchMenuMainBtnDatum.new(I18N.Get("village_outpost_btn_construction"), KingdomTouchInfoProviderVillage.StartRebuild, village)
    local buttonStartRebuildDisabled = TouchMenuMainBtnDatum.new(I18N.Get("village_outpost_btn_construction"), KingdomTouchInfoProviderVillage.StartRebuild, village):SetEnable(false)
    local buttonJoinRebuild = TouchMenuMainBtnDatum.new(I18N.Get("village_outpost_info_participate_in_construction"), KingdomTouchInfoProviderVillage.JoinRebuild, village)
    local buttonSummonAllianceMembers = TouchMenuMainBtnDatum.new(I18N.Get("village_outpost_btn_summon_members"), KingdomTouchInfoProviderVillage.SummonAllianceMembers, village)

    local buttonAllianceGather = TouchMenuMainBtnDatum.new(I18N.Get("alliance_gathering_point_1"), Delegate.GetOrCreate(ModuleRefer.AllianceModule, ModuleRefer.AllianceModule.SetAllianceGatherPoint), tile)
    

    local buttons = {}
    local flags = KingdomTouchInfoProviderVillage.GetKingdomTouchInfoProviderVillageButtonFlags(village)
    local btnFlags = KingdomTouchInfoProviderVillage.ButtonFlags
    if (flags & btnFlags.buttonCancelDrop) ~= 0 then
        table.insert(buttons, buttonCancelDrop)
    end
    if (flags & btnFlags.buttonDrop) ~= 0 then
        table.insert(buttons, buttonDrop)
    end
    if (flags & btnFlags.buttonRetreat) ~= 0 then
        table.insert(buttons, buttonRetreat)
    end
    if (flags & btnFlags.buttonTransformToAllianceCenter) ~= 0 then
        table.insert(buttons, buttonTransformToAllianceCenter)
    end
    if (flags & btnFlags.buttonTransformToAllianceCenterDisabled) ~= 0 then
        table.insert(buttons, buttonTransformToAllianceCenterDisabled)
    end
    if (flags & btnFlags.buttonChangeToAllianceCenter) ~= 0 then
        table.insert(buttons, buttonChangeToAllianceCenter)
    end
    if (flags & btnFlags.buttonChangeToAllianceCenterDisabled) ~= 0 then
        table.insert(buttons, buttonChangeToAllianceCenterDisabled)
    end
    if KingdomTouchInfoOperation.IsTransformToAllianceCenterConstructingReinforceFunctionOn() then
        if (flags & btnFlags.buttonTransformToAllianceCenterSpeedUp) ~= 0 then
            table.insert(buttons, buttonTransformToAllianceCenterSpeedUp)
        end
    end
    if (flags & btnFlags.buttonGarrison) ~= 0 then
        table.insert(buttons, buttonGarrison)
    end
    if (flags & btnFlags.buttonCancelDeclare) ~= 0 then
        table.insert(buttons, buttonCancelDeclare)
    end
    if (flags & btnFlags.buttonScout) ~= 0 then
        table.insert(buttons, buttonScout)
    end
    if (flags & btnFlags.buttonScoutFogUnlock) ~= 0 then
        table.insert(buttons, buttonScoutFogUnlock)
    end
    if (flags & btnFlags.buttonAttack) ~= 0 then
        table.insert(buttons, buttonAttack)
    end
    if (flags & btnFlags.buttonAttackDisabled) ~= 0 then
        table.insert(buttons, buttonAttackDisabled)
    end
    if (flags & btnFlags.buttonManagedAttack) ~= 0 then
        table.insert(buttons, buttonManagedAttack)
    end
    if (flags & btnFlags.buttonManagedAttackDisabled) ~= 0 then
        table.insert(buttons, buttonManagedAttackDisabled)
    end
    if (flags & btnFlags.buttonWarDetail) ~= 0 then
        table.insert(buttons, buttonWarDetail)
    end
    if (flags & btnFlags.buttonDeclareWarDisabled) ~= 0 then
        table.insert(buttons, buttonDeclareWarDisabled)
    end
    if (flags & btnFlags.buttonDeclareWarEnabled) ~= 0 then
        table.insert(buttons, buttonDeclareWarEnabled)
    end
    if (flags & btnFlags.buttonSummonBehemothEnabled) ~= 0 then
        table.insert(buttons, buttonSummonBehemoth)
    end
    if (flags & btnFlags.buttonSummonBehemothDisabled) ~= 0 then
        table.insert(buttons, buttonSummonBehemothDisabled)
    end
    if (flags & btnFlags.buttonStartRebuild) ~= 0 then
        table.insert(buttons, buttonStartRebuild)
    end
    if (flags & btnFlags.buttonStartRebuildDisabled) ~= 0 then
        table.insert(buttons, buttonStartRebuildDisabled)
    end
    if (flags & btnFlags.buttonJoinRebuild) ~= 0 then
        table.insert(buttons, buttonJoinRebuild)
    end
    if (flags & btnFlags.buttonSummonAllianceMembers) ~= 0 then
        table.insert(buttons, buttonSummonAllianceMembers)
    end
    if (flags & btnFlags.buttonAllianceGather) ~= 0 then
        table.insert(buttons, buttonAllianceGather)
    end
    return buttons
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.DeclareWar(tile)
    ModuleRefer.VillageModule:StartSignAttackVillage(tile.entity, true)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.CancelDeclare(tile)
    local villageName = ModuleRefer.MapBuildingTroopModule:GetBuildingName(tile.entity)
    local content = I18N.GetWithParams("village_check_Cancel_declaration", villageName, KingdomMapUtils.CoordToXYString(tile.X, tile.Z))
    UIHelper.ShowConfirm(content, nil, function()
        ---@type wds.Village
        local village = tile.entity
        if village then
            if not ModuleRefer.VillageModule:CheckCanCancelDeclare(village, true) then
                return
            end
            ModuleRefer.VillageModule:DoCancelDeclareWarOnVillage(nil, village.ID)
            ModuleRefer.KingdomTouchInfoModule:Hide()
        end
    end)

end

function KingdomTouchInfoProviderVillage.Scout(entity)
    ModuleRefer.RadarModule:ScoutDialogue(entity)
end

function KingdomTouchInfoProviderVillage.ScoutFogUnlock(entity)
    g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.Position)
    ModuleRefer.MapFogModule:SetSelectedMistAt(tileX, tileZ,true)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.Garrison(tile)
    KingdomTouchInfoOperation.SendReinforceTroop(tile)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.Retreat(tile)
    ---@type wds.Village
    local village = tile.entity
    if village then
        local memberInfo = ModuleRefer.MapBuildingTroopModule:GetMyTroop(village.Army)
        ModuleRefer.MapBuildingTroopModule:LeaveTroopFrom(village.ID, memberInfo.Id)
    end
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.Drop(tile)
    local content = I18N.Get("village_check_Givingup_vallage")
    if ModuleRefer.VillageModule:IsAllianceCenter(tile.entity) then
        content = I18N.Get("alliance_center_giveup_makesure_content")
    end
    UIHelper.ShowConfirm(content, nil, function()
        ---@type wds.Village
        local village = tile.entity
        if village then
            if not ModuleRefer.VillageModule:CheckCanDropVillage(village, true) then
                return
            end
            ModuleRefer.VillageModule:DoDropVillage(nil, village.ID)
            ModuleRefer.KingdomTouchInfoModule:Hide()
        end
    end)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.CancelDrop(tile)
    UIHelper.ShowConfirm(I18N.Get("village_check_cancel_waiver"), nil, function()
        ---@type wds.Village
        local village = tile.entity
        if village then
            if not ModuleRefer.VillageModule:CheckCanCancelDropVillage(village, true) then
                return
            end
            ModuleRefer.VillageModule:DoCancelDropVillage(nil, village.ID)
            ModuleRefer.KingdomTouchInfoModule:Hide()
        end
    end)
end

---@param entity table
function KingdomTouchInfoProviderVillage.ManagedAttack(tile)
    KingdomTouchInfoOperation.StartAssembleAttack(tile)
end

---@param entity wds.Village
function KingdomTouchInfoProviderVillage.Attack(entity)
    KingdomTouchInfoOperation.SendTroopToEntityQuickly(entity)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.WarDetail(tile)
    KingdomTouchInfoOperation.OpenWarDetailUIMediator({tile = tile, entityPath = DBEntityPath.Village})
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderVillage.SummonBehemoth(tile, btnTrans)
    KingdomTouchInfoOperation.SummonBehemothOnEntity(tile, btnTrans)
end

function KingdomTouchInfoProviderVillage.TransformToAllianceCenter(tile, btnTrans)
    KingdomTouchInfoOperation.TransformToAllianceCenter(tile, btnTrans)
end

function KingdomTouchInfoProviderVillage.TransformToAllianceCenterSpeedUp(tile, btnTrans)
    KingdomTouchInfoOperation.TransformToAllianceCenterSpeedUp(tile, btnTrans)
end

---@param village wds.Village
function KingdomTouchInfoProviderVillage.StartRebuild(village)
    ModuleRefer.VillageModule:StartRebuild(village)
end

---@param village wds.Village
function KingdomTouchInfoProviderVillage.StopRebuild(village)
    ModuleRefer.VillageModule:StopRebuild(village)
end

---@param village wds.Village
function KingdomTouchInfoProviderVillage.JoinRebuild(village)
    ModuleRefer.VillageModule:JoinRebuild(village)
end

---@param village wds.Village
function KingdomTouchInfoProviderVillage.SummonAllianceMembers(village)
    ModuleRefer.VillageModule:SummonAllianceMembers(village)
end

return KingdomTouchInfoProviderVillage
