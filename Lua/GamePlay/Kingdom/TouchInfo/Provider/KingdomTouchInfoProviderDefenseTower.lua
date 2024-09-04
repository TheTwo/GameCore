local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local DBEntityPath = require("DBEntityPath")
local AllianceAuthorityItem = require("AllianceAuthorityItem")

local KingdomTouchInfoProviderFlexibleBuilding = require("KingdomTouchInfoProviderFlexibleBuilding")

---@class KingdomTouchInfoProviderDefenseTower:KingdomTouchInfoProviderFlexibleBuilding
---@field new fun():KingdomTouchInfoProviderDefenseTower
---@field super KingdomTouchInfoProviderFlexibleBuilding
local KingdomTouchInfoProviderDefenseTower = class('KingdomTouchInfoProviderDefenseTower', KingdomTouchInfoProviderFlexibleBuilding)

function KingdomTouchInfoProviderDefenseTower:CreateBasicInfo(tile)
    local ret = KingdomTouchInfoProviderDefenseTower.super.CreateBasicInfo(self, tile)
    if ModuleRefer.KingdomConstructionModule:CanBreak(tile.entity) then
        if ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.RemoveDefenceTower) then
            ret:SetClickBtnDefuse(function(btnTrans)
                KingdomTouchInfoOperation.RemoveMapBuilding(tile, btnTrans)
            end)
        end
    end
    return ret
end

function KingdomTouchInfoProviderDefenseTower:CreateButtonInfo(tile)
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
        end
        table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
                KingdomTouchInfoOperation.ShowTroopInfo,
                tile,
                KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
                I18N.Get("djianzhu_buduixiangqing"),
                KingdomTouchInfoFactory.ButtonBacks.NormalBack
        ))
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
                    {tile = tile,entityPath = DBEntityPath.DefenceTower},
                    KingdomTouchInfoFactory.ButtonIcons.IconExplore,--"sp_common_icon_explore",
                    I18N.Get("world_build_zhankuang"),
                    KingdomTouchInfoFactory.ButtonBacks.NormalBack
            ))
        end
    end
    return buttons
end

return KingdomTouchInfoProviderDefenseTower