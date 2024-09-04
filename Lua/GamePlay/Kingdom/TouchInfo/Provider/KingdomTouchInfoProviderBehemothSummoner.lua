local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local DBEntityPath = require("DBEntityPath")

local KingdomTouchInfoProviderFlexibleBuilding = require("KingdomTouchInfoProviderFlexibleBuilding")

---@class KingdomTouchInfoProviderBehemothSummoner:KingdomTouchInfoProviderFlexibleBuilding
---@field new fun():KingdomTouchInfoProviderBehemothSummoner
---@field super KingdomTouchInfoProviderFlexibleBuilding
local KingdomTouchInfoProviderBehemothSummoner = class('KingdomTouchInfoProviderBehemothSummoner', KingdomTouchInfoProviderFlexibleBuilding)

function KingdomTouchInfoProviderBehemothSummoner:CreateBasicInfo(tile)
    local ret = KingdomTouchInfoProviderBehemothSummoner.super.CreateBasicInfo(self, tile)
    if ModuleRefer.PlayerModule:IsFriendly(tile.entity.Owner) and ModuleRefer.KingdomConstructionModule:CanBreak(tile.entity) then
        if ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.RemoveBehemothSummoner) then
            ret:SetClickBtnDefuse(function(btnTrans)
                KingdomTouchInfoOperation.RemoveBehemothSummoner(tile, btnTrans)
            end)
        end
    end
    return ret
end

function KingdomTouchInfoProviderBehemothSummoner:CreateButtonInfo(tile)
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
                    {tile = tile,entityPath = DBEntityPath.CommonMapBuilding},
                    KingdomTouchInfoFactory.ButtonIcons.IconExplore,--"sp_common_icon_explore",
                    I18N.Get("world_build_zhankuang"),
                    KingdomTouchInfoFactory.ButtonBacks.NormalBack
            ))
        end
    end
    return buttons
end

return KingdomTouchInfoProviderBehemothSummoner