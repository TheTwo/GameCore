local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TouchMenuHelper = require("TouchMenuHelper")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")
local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuCellLeagueDatum = require("TouchMenuCellLeagueDatum")
local TouchMenuCellProgressDatum = require("TouchMenuCellProgressDatum")

---@class KingdomTouchInfoProviderCastle :KingdomTouchInfoProvider
local KingdomTouchInfoProviderCastle = class("KingdomTouchInfoProviderCastle", KingdomTouchInfoProvider)

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderCastle:CreateBasicInfo(tile)
    local mainWindow = KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    mainWindow:SetOwner(tile.entity.Owner)
    if tile.entity.Owner.PlayerID ~= ModuleRefer.PlayerModule.playerId then
        mainWindow:SetClickBtnPlayerInfo(function()
            ModuleRefer.PlayerModule:ShowPlayerInfoPanel(tile.entity.Owner.PlayerID, nil)
            return true
        end)
    end
    return mainWindow
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderCastle:CreateDetailInfo(tile)
    local IsProtected = ModuleRefer.PlayerModule:IsProtected(tile.entity)

    local compsData = {}

    ---Player power
    local powerPart = KingdomTouchInfoProviderCastle.GetPlayerPower(tile.entity)
    table.insert(compsData, powerPart)

    ---Alliance info
    local alliancePart = KingdomTouchInfoProviderCastle.GetAllianceInfoPart(tile.entity)
    table.insert(compsData, alliancePart)

    ---Protection info
    if IsProtected then
        local timerData = TouchMenuHelper.GetSecondTickCommonTimerData(tile.entity.MapStates.StateWrapper.ProtectionExpireTime)
        table.insert(compsData, TouchMenuCellPairTimeDatum.new(I18N.Get("protect_info_castle_under_protection"), timerData))
    end

    ---city Defence
    local defDatum = KingdomTouchInfoProviderCastle.GetCityDefenceValue(tile.entity)
    if defDatum then
        table.insert(compsData, defDatum)
    end
    return compsData
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderCastle:CreateButtonInfo(tile)
    local isMine = ModuleRefer.KingdomConstructionModule:IsMyBuilding(tile.entity.Owner)
    local isFriendly = ModuleRefer.PlayerModule:IsFriendly(tile.entity.Owner)
    local IsProtected = ModuleRefer.PlayerModule:IsProtected(tile.entity)
    
    local buttons = {}

    if isMine then
        table.insert(buttons, TouchMenuMainBtnDatum.new(I18N.Get("world_huicheng"), KingdomTouchInfoOperation.VisitCity, tile))
        table.insert(buttons, TouchMenuMainBtnDatum.new(I18N.Get("base_defence_title"), KingdomTouchInfoOperation.OpenDefenceUI, tile))
    elseif isFriendly then
        table.insert(buttons, TouchMenuMainBtnDatum.new(I18N.Get("world_zhushou"), KingdomTouchInfoOperation.OpenReinforceUI, tile))
    else
        --Other City
        --攻击敌方
        local attackBtnDatum = TouchMenuMainBtnDatum.new(I18N.Get("world_gongji"), KingdomTouchInfoOperation.MoveTroopToTile, tile)
        local assemblyDatum = TouchMenuMainBtnDatum.new(I18N.Get("alliance_team"), KingdomTouchInfoOperation.StartAssembleAttack, tile)

        if IsProtected then
            attackBtnDatum:SetEnable(false)
            attackBtnDatum:SetOnClickDisable(function()
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("protect_info_castle_under_protection"))
            end)

            assemblyDatum:SetEnable(false)
            assemblyDatum:SetOnClickDisable(function()
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("protect_info_castle_under_protection"))
            end)
        else
            if not ModuleRefer.AllianceModule:IsInAlliance() then
                assemblyDatum:SetEnable(false)
                assemblyDatum:SetOnClickDisable(function()
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('alliance_team_toast02'))
                end)
            end
        end

        table.insert(buttons, attackBtnDatum)
        table.insert(buttons, assemblyDatum)
    end
    return buttons
end

---@param entity wds.CastleBrief
function KingdomTouchInfoProviderCastle.GetAllianceInfoPart(entity)
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
        allianceStr = I18N.Get("bw_info_base_no_alliance")
    end
    local appear = entity.Owner.AllianceBadgeAppearance
    local pattern = entity.Owner.AllianceBadgePattern
    local pairOccupiedAlliances = TouchMenuCellLeagueDatum.new(allianceStr, color, appear, pattern, nil)
    pairOccupiedAlliances:SetButtonHidden(true)
    return pairOccupiedAlliances
end

---@param entity wds.CastleBrief
function KingdomTouchInfoProviderCastle.GetPlayerPower(entity)
    local powerIcon = 'sp_comp_icon_power'
    local powerString = CS.System.String.Format("{0:#,0}", entity.BasicInfo.Power)
    if ModuleRefer.PlayerModule:IsMine(entity.Owner) then
        powerString = CS.System.String.Format("{0:#,0}", ModuleRefer.PlayerModule:GetPlayerPower())
    end

    return TouchMenuCellPairDatum.new(I18N.Get("power_entire_breakdown_name"), powerString, nil, nil,nil, powerIcon)
end

---@param entity wds.CastleBrief
function KingdomTouchInfoProviderCastle.GetCityDefenceValue(entity)
    if entity.Battle.MaxDurability <= 0 then
        return nil
    end

    local durabilityProgressFunc =  function()
        return entity.Battle.Durability / entity.Battle.MaxDurability
    end
    local durablityValueStrFunc = function()
        return string.format(" %d/%d", entity.Battle.Durability, entity.Battle.MaxDurability)
    end
    local progressDurability = TouchMenuCellProgressDatum.new(
            nil, I18N.Get("xiangzhen_naijiu"), durabilityProgressFunc,
            nil,nil,
            true, durablityValueStrFunc
    )

    return progressDurability
end

return KingdomTouchInfoProviderCastle