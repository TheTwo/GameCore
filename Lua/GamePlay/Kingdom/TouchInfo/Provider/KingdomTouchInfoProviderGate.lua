local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuCellProgressDatum = require("TouchMenuCellProgressDatum")
local TouchMenuCellLeagueDatum = require("TouchMenuCellLeagueDatum")
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")
local TMCellRewardPairDatum = require("TMCellRewardPairDatum")
local TMCellRewardsHorizontalDatum = require("TMCellRewardsHorizontalDatum")
local TMCellRewardSpecialPairDatum = require("TMCellRewardSpecialPairDatum")
local TouchMenuCellRewardPairListDatum = require("TouchMenuCellRewardPairListDatum")
local TMCellRewardPetDatum = require("TMCellRewardPetDatum")
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ColorConsts = require("ColorConsts")
local VillageSubType = require("VillageSubType")

---@class KingdomTouchInfoProviderGate : KingdomTouchInfoProvider
local KingdomTouchInfoProviderGate = class("KingdomTouchInfoProviderGate", KingdomTouchInfoProvider)

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate:CreateBasicInfo(tile)
    local entity = tile.entity
    local fixedMapBuildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    local basicInfo = KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    basicInfo:SetTipsOnClick(function()
        g_Game.EventManager:TriggerEvent(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, I18N.Get(fixedMapBuildingConfig:Des()))
    end)
    return basicInfo
end

function KingdomTouchInfoProviderGate.GetOccupyInfoPart(entity)
    local allianceStr = string.Empty
    local color
    if entity.Owner.AllianceID > 0 then
        allianceStr = ModuleRefer.PlayerModule.FullName(entity.Owner.AllianceAbbr.String, entity.Owner.AllianceName.String)
        if ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
            color = UIHelper.TryParseHtmlString(ColorConsts.army_blue)
        else
            color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        end
    else
        allianceStr = I18N.Get("village_info_No_Occupation")
    end
    local appear = entity.Owner.AllianceBadgeAppearance
    local pattern = entity.Owner.AllianceBadgePattern
    local pairOccupiedAlliances = TouchMenuCellLeagueDatum.new(allianceStr, color, appear, pattern, function()
        KingdomTouchInfoOperation.OccupationHistory({entity = entity, entityPath = DBEntityPath.Village})
    end)
    return pairOccupiedAlliances
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate:CreateDetailInfo(tile)
    local entity = tile.entity
    local isNeutral = ModuleRefer.PlayerModule:IsNeutral(entity.Owner.AllianceID)

    local hpRatioFunc = function()
        local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetNpcTroopHP(entity.Army)
        return hp / hpMax
    end
    local hpStrFunc = function()
        return I18N.Get("village_info_Garrison_Defenders")
    end
    local hpValueFunc = function()
        local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetNpcTroopHP(entity.Army)
        return string.format("<b>%d</b>/%d", hp, hpMax)
    end
    local progressHP = TouchMenuCellProgressDatum.new(nil, hpStrFunc, hpRatioFunc, nil, nil, true, hpValueFunc)
    progressHP:SetGoto(function()
        if isNeutral then
            ModuleRefer.MapBuildingTroopModule:ShowNpcTroopInfo(tile)
        else
            ModuleRefer.MapBuildingTroopModule:ShowTroopInfo(tile, true)
        end
    end)

    local durabilityProgressFunc = function()
        return entity.Battle.Durability / entity.Battle.MaxDurability
    end
    local durabilityStrFunc = function()
        return I18N.Get("xiangzhen_naijiu")
    end
    local durabilityValueFunc = function()
        return string.format("<b>%d</b>/%d", entity.Battle.Durability, entity.Battle.MaxDurability)
    end
    local progressDurability = TouchMenuCellProgressDatum.new(nil, durabilityStrFunc, durabilityProgressFunc, nil, nil, true, durabilityValueFunc)

    local ret = {}
    table.insert(ret, progressHP)
    table.insert(ret, progressDurability)

    local fixedMapBuildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    local pairBenefits = {}

    if fixedMapBuildingConfig:VillageSub() == VillageSubType.Gate then
        table.insert(pairBenefits, TMCellRewardsHorizontalDatum.new(nil, I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc())))
        -- table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(I18N.Get(fixedMapBuildingConfig:VillageSubTypeBenefitsDesc()), string.Empty, string.Empty))
    end

    local allianceAttr = ConfigRefer.AttrGroup:Find(fixedMapBuildingConfig:AllianceAttrGroup())
    if allianceAttr then
        if allianceAttr and allianceAttr:AttrListLength() > 0 then
            ---@type {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string}}[]
            local allianceGainAttr = {}
            for i = 1, allianceAttr:AttrListLength() do
                local attrTypeAndValue = allianceAttr:AttrList(i)
                ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, allianceGainAttr, true)
                local v = allianceGainAttr[1]
                allianceGainAttr[1] = nil
                table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(v.cellData.strLeft, v.cellData.strRight, v.cellData.icon))
            end
        end
    end

    if fixedMapBuildingConfig:VillageShowExtraPetItemLength() > 0 then
        local petConfigIds = {}
        ---@type TMCellRewardPetDatum
        local cellData = TMCellRewardPetDatum.new(I18N.Get("village_newpet_after_occupied"), petConfigIds)
        for i = 1, fixedMapBuildingConfig:VillageShowExtraPetItemLength() do
            table.insert(petConfigIds, fixedMapBuildingConfig:VillageShowExtraPetItem(i))
        end
        table.insert(pairBenefits, cellData)
    end

    local currencyConfig = ConfigRefer.AllianceCurrency:Find(fixedMapBuildingConfig:OccupyAllianceCurrencyType())
    local currencyNum = fixedMapBuildingConfig:OccupyAllianceCurrencyNum()
    if currencyConfig and currencyNum > 0 then
        local pairBenefitComp = TMCellRewardPairDatum.new(I18N.Get(currencyConfig:Name()), ("+%s"):format(fixedMapBuildingConfig:OccupyAllianceCurrencyNum()), currencyConfig:Icon())
        table.insert(pairBenefits, pairBenefitComp)
    end

    -- if fixedMapBuildingConfig:FactionValue() > 0 then
    --     table.insert(pairBenefits, TMCellRewardPairDatum.new(I18N.Get("village_info_Alliance_forces"), ("+%s"):format(fixedMapBuildingConfig:FactionValue()), "sp_comp_icon_achievement_1"))
    -- end

    -- local attr = entity.OccupyDropInfo.RandomAllianceAttrGroup
    -- ---@type {cellData:{strLeft:string,strRight:string,icon:string}}[]
    -- local addToTable = {}
    -- for _, v in ipairs(attr) do
    --     local attrGroup = ConfigRefer.AttrGroup:Find(v)
    --     if attrGroup then
    --         for i = 1, attrGroup:AttrListLength() do
    --             ModuleRefer.VillageModule.ParseAttrInfo(attrGroup:AttrList(i), addToTable, true)
    --         end
    --     end
    -- end
    -- for _, v in ipairs(addToTable) do
    --     local pairBenefitComp = TMCellRewardPairDatum.new(v.cellData.strLeft, v.cellData.strRight, v.cellData.icon)
    --     table.insert(pairBenefits, pairBenefitComp)
    -- end

    local rewardPairListDatum = TouchMenuCellRewardPairListDatum.new(I18N.Get("village_info_Occupy_gains"), pairBenefits, function()
        KingdomTouchInfoOperation.OccupationGainDetail({tile = tile, entityPath = DBEntityPath.Pass})
    end)

    table.insert(ret, rewardPairListDatum)
    local pairOccupiedAlliances = KingdomTouchInfoProviderGate.GetOccupyInfoPart(entity)
    table.insert(ret, pairOccupiedAlliances)

    return ret
end

---@param tile MapRetrieveResult
---@return TouchMenuButtonTipsData
function KingdomTouchInfoProviderGate:CreateTipData(tile)
    local entity = tile.entity
    if ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
        return nil
    end

    local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
    local textKey, timestamp = ModuleRefer.GateModule:GetCountDown(entity, allianceID)
    if timestamp > 0 then
        local tipFunc = function()
            local entity = tile.entity
            local textKey, timestamp = ModuleRefer.GateModule:GetCountDown(entity, allianceID)
            local tip = string.Empty
            local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
            local remainTime = timestamp - serverTime
            if remainTime >= 0 then
                local timeStr = TimeFormatter.SimpleFormatTimeWithDay(remainTime)
                tip = I18N.GetWithParams(textKey, timeStr)
            end
            return tip
        end

        return TouchMenuButtonTipsData.new():SetContent(tipFunc)
    else
        local can, tip = ModuleRefer.GateModule:GetCanSignAttackToast(entity)
        if can then
            return nil
        end
        return TouchMenuButtonTipsData.new():SetContent(tip)
    end
end

---@class KingdomTouchInfoProviderGate.ButtonFlags
KingdomTouchInfoProviderGate.ButtonFlags = {
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
    buttonManagedAttackDisabled = 1 << 10,
    buttonAttackDisabled = 1 << 11,
}

---@return KingdomTouchInfoProviderGate.ButtonFlags number[FLAGS]
function KingdomTouchInfoProviderGate.GetKingdomTouchInfoProviderGateButtonFlags(entity)
    local btnFlags = KingdomTouchInfoProviderGate.ButtonFlags
    ---@type KingdomTouchInfoProviderGate.ButtonFlags
    local ret = KingdomTouchInfoProviderGate.ButtonFlags.none
    local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
    local warStatus = ModuleRefer.GateModule:GetWarStatus(entity.ID, allianceID)
    local can, _ = ModuleRefer.GateModule:GetCanSignAttackToast(entity)
    local sasDeclareWarOnVillage = ModuleRefer.GateModule:HasDeclareWar(entity.ID)

    if ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
        if ModuleRefer.GateModule:IsInDrop(entity, allianceID) then
            ret = ret | btnFlags.buttonCancelDrop
        else
            ret = ret | btnFlags.buttonDrop
        end
        if ModuleRefer.MapBuildingTroopModule:GetMyTroopCount(entity.Army) > 0 then
            ret = ret | btnFlags.buttonRetreat
        else
            ret = ret | btnFlags.buttonGarrison
        end
    elseif sasDeclareWarOnVillage then
        if warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            ret = ret | btnFlags.buttonCancelDeclare
            ret = ret | btnFlags.buttonManagedAttackDisabled
            ret = ret | btnFlags.buttonAttackDisabled
        elseif warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder then
            ret = ret | btnFlags.buttonManagedAttack
            ret = ret | btnFlags.buttonAttack
            ret = ret | btnFlags.buttonWarDetail
        elseif warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction then
            ret = ret | btnFlags.buttonManagedAttack
            ret = ret | btnFlags.buttonAttack
        end
    else
        if (not can) or ModuleRefer.VillageModule:IsVillageInProtection(entity) then
            ret = ret | btnFlags.buttonDeclareWarDisabled
        else
            ret = ret | btnFlags.buttonDeclareWarEnabled
        end
    end
    return ret
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate:CreateButtonInfo(tile)
    local entity = tile.entity

    local buttonDeclareWarEnabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Declare_war"), KingdomTouchInfoProviderGate.DeclareWar, tile)
    local buttonDeclareWarDisabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Declare_war"), KingdomTouchInfoProviderGate.DeclareWar, tile):SetEnable(false)
    local buttonCancelDeclare = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Cancel_declara"), KingdomTouchInfoProviderGate.CancelDeclare, tile)

    local buttonGarrison = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Garrison"), KingdomTouchInfoProviderGate.Garrison, tile)
    local buttonRetreat = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Withdraw_troops"), KingdomTouchInfoProviderGate.Retreat, tile)
    local buttonDrop = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Abandon"), KingdomTouchInfoProviderGate.Drop, tile)
    local buttonCancelDrop = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Cancel_waiver"), KingdomTouchInfoProviderGate.CancelDrop, tile)

    local buttonManagedAttack = TouchMenuMainBtnDatum.new(I18N.Get("alliance_team"), KingdomTouchInfoProviderGate.ManagedAttack, tile)
    local buttonManagedAttackDisabled = TouchMenuMainBtnDatum.new(I18N.Get("alliance_team"), nil, nil, nil, nil, nil, false, function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_invite_tips7"))
    end)
    local buttonAttack = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Attack"), KingdomTouchInfoProviderGate.Attack, entity)
    local buttonAttackDisabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Attack"), nil, nil, nil, nil, nil, false, function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_in_preparation"))
    end)
    local buttonWarDetail = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Battle_situation"), KingdomTouchInfoProviderGate.WarDetail, tile)

    local buttons = {}
    local flags = KingdomTouchInfoProviderGate.GetKingdomTouchInfoProviderGateButtonFlags(entity)
    local btnFlags = KingdomTouchInfoProviderGate.ButtonFlags
    if (flags & btnFlags.buttonCancelDrop) ~= 0 then
        table.insert(buttons, buttonCancelDrop)
    end
    if (flags & btnFlags.buttonDrop) ~= 0 then
        table.insert(buttons, buttonDrop)
    end
    if (flags & btnFlags.buttonRetreat) ~= 0 then
        table.insert(buttons, buttonRetreat)
    end
    if (flags & btnFlags.buttonGarrison) ~= 0 then
        table.insert(buttons, buttonGarrison)
    end
    if (flags & btnFlags.buttonCancelDeclare) ~= 0 then
        table.insert(buttons, buttonCancelDeclare)
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
    return buttons
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.DeclareWar(tile)
    ModuleRefer.GateModule:StartSignAttack(tile.entity, true)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.CancelDeclare(tile)
    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(tile.entity)
    local content = I18N.GetWithParams("village_check_Cancel_declaration", name, KingdomMapUtils.CoordToXYString(tile.X, tile.Z))
    UIHelper.ShowConfirm(content, nil, function()
        local entity = tile.entity
        if entity then
            if not ModuleRefer.GateModule:CheckCanCancelDeclare(entity, true) then
                return
            end
            ModuleRefer.GateModule:DoCancelDeclareWar(nil, entity.ID)
            ModuleRefer.KingdomTouchInfoModule:Hide()
        end
    end)

end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.Garrison(tile)
    KingdomTouchInfoOperation.SendReinforceTroop(tile)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.Retreat(tile)
    local entity = tile.entity
    if entity then
        local memberInfo = ModuleRefer.MapBuildingTroopModule:GetMyTroop(entity.Army)
        ModuleRefer.MapBuildingTroopModule:LeaveTroopFrom(entity.ID, memberInfo.Id)
    end
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.Drop(tile)
    UIHelper.ShowConfirm(I18N.Get("village_check_Givingup_vallage"), nil, function()
        local entity = tile.entity
        if entity then
            if not ModuleRefer.VillageModule:CheckCanDropVillage(entity, true) then
                return
            end
            ModuleRefer.VillageModule:DoDropVillage(nil, entity.ID)
            ModuleRefer.KingdomTouchInfoModule:Hide()
        end
    end)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.CancelDrop(tile)
    UIHelper.ShowConfirm(I18N.Get("village_check_cancel_waiver"), nil, function()
        local entity = tile.entity
        if entity then
            if not ModuleRefer.VillageModule:CheckCanCancelDropVillage(entity, true) then
                return
            end
            ModuleRefer.VillageModule:DoCancelDropVillage(nil, entity.ID)
            ModuleRefer.KingdomTouchInfoModule:Hide()
        end
    end)
end

---@param entity table
function KingdomTouchInfoProviderGate.ManagedAttack(tile)
    KingdomTouchInfoOperation.StartAssembleAttack(tile)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.Attack(tile)
    KingdomTouchInfoOperation.SendTroopToEntityQuickly(tile)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderGate.WarDetail(tile)
    KingdomTouchInfoOperation.OpenWarDetailUIMediator({tile = tile, entityPath = DBEntityPath.Pass})
end

return KingdomTouchInfoProviderGate
