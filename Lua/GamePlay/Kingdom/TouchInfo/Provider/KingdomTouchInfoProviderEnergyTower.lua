local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local DBEntityPath = require("DBEntityPath")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")

local KingdomTouchInfoProviderFlexibleBuilding = require("KingdomTouchInfoProviderFlexibleBuilding")

---@class KingdomTouchInfoProviderEnergyTower:KingdomTouchInfoProviderFlexibleBuilding
---@field new fun():KingdomTouchInfoProviderEnergyTower
---@field super KingdomTouchInfoProviderFlexibleBuilding
local KingdomTouchInfoProviderEnergyTower = class('KingdomTouchInfoProviderEnergyTower', KingdomTouchInfoProviderFlexibleBuilding)

function KingdomTouchInfoProviderEnergyTower:CreateBasicInfo(tile)
    local ret = KingdomTouchInfoProviderEnergyTower.super.CreateBasicInfo(self, tile)
    if ModuleRefer.KingdomConstructionModule:CanBreak(tile.entity) then
        if ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.RemoveEnergyTower) then
            ret:SetClickBtnDefuse(function(btnTrans)
                KingdomTouchInfoOperation.RemoveMapBuilding(tile, btnTrans)
            end)
        end
    end
    return ret
end

function KingdomTouchInfoProviderEnergyTower:CreateButtonInfo(tile)
    local buttons = {}
    local canBreak =  ModuleRefer.KingdomConstructionModule:CanBreak(tile.entity)
    local canSupportBuild = ModuleRefer.KingdomConstructionModule:CanSupportBuild(tile.entity)
    if canBreak or canSupportBuild then
        if ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(tile.entity) then
            if KingdomTouchInfoOperation.IsConstructingReinforceFunctionOn() then
                table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                        KingdomTouchInfoOperation.ConstructingReinforce,
                        tile,
                        KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
                        I18N.Get("djianzhu_zhiyuan"),
                        KingdomTouchInfoFactory.ButtonBacks.NormalBack
                ))
            end
        else
            if ModuleRefer.MapBuildingTroopModule:GetMyTroopCount(tile.entity.Army) > 0 then
                table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                    KingdomTouchInfoOperation.LeaveTroopFrom,
                    tile.entity,
                    KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
                    I18N.Get("village_btn_Withdraw_troops"),
                    KingdomTouchInfoFactory.ButtonBacks.NormalBack
                ))
            else
                table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                        KingdomTouchInfoOperation.SendReinforceTroop,
                        tile,
                        KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
                        I18N.Get("village_btn_Garrison"),
                        KingdomTouchInfoFactory.ButtonBacks.NormalBack
                ))
            end
            table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                KingdomTouchInfoOperation.ShowTroopInfo,
                tile,
                KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
                I18N.Get("djianzhu_buduixiangqing"),
                KingdomTouchInfoFactory.ButtonBacks.NormalBack
            ))
            if ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SummonBehemoth) then
                if ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
                        and ModuleRefer.AllianceModule.Behemoth:GetSummonerInfo()
                        and not ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon()
                then
                    local enough,currencyConfig,currencyCostCount = ModuleRefer.AllianceModule.Behemoth:CheckHasEnoughCurrencyForSummon()
                    if enough then
                        local buttonSummonBehemoth = TouchMenuMainBtnDatum.new(I18N.Get("seskill_category_summon"), KingdomTouchInfoOperation.SummonBehemothOnEntity, tile)
                        buttonSummonBehemoth:SetExtraImage(currencyConfig and currencyConfig:Icon()):SetExtraLabel(tostring(currencyCostCount))
                        table.insert(buttons, buttonSummonBehemoth)
                    else
                        local buttonSummonBehemothDisabled = TouchMenuMainBtnDatum.new(I18N.Get("seskill_category_summon"), function(_, _)
                            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_ziyuanbuzu"))
                        end)
                        buttonSummonBehemothDisabled:SetExtraImage(currencyConfig and currencyConfig:Icon()):SetExtraLabel(tostring(currencyCostCount)):SetExtraLabelColor(CS.UnityEngine.Color.red):SetEnable(false)
                        table.insert(buttons, buttonSummonBehemothDisabled)
                    end
                end
            end
        end
    elseif not ModuleRefer.PlayerModule:IsFriendly(tile.entity.Owner) then
        --Other's
        table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                KingdomTouchInfoOperation.MoveTroopToTile,
                tile,
                KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
                I18N.Get("world_gongji"),
                KingdomTouchInfoFactory.ButtonBacks.NegativeBack
        ))
        if tile.entity.MapStates.Battling and KingdomTouchInfoOperation.HasArmySituationInfosCanShow(tile.entity.Army) then
            table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                    KingdomTouchInfoOperation.OpenWarDetailUIMediator,
                    {tile = tile,entityPath = DBEntityPath.EnergyTower},
                    KingdomTouchInfoFactory.ButtonIcons.IconExplore,--"sp_common_icon_explore",
                    I18N.Get("world_build_zhankuang"),
                    KingdomTouchInfoFactory.ButtonBacks.NormalBack
            ))
        end
    end
    return buttons
end

return KingdomTouchInfoProviderEnergyTower