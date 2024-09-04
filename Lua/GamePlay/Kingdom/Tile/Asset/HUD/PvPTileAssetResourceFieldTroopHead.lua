local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ManualResourceConst = require("ManualResourceConst")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")
local DBEntityPath = require("DBEntityPath")

---@class PvPTileAssetResourceFieldTroopHead : PvPTileAssetUnit
local PvPTileAssetResourceFieldTroopHead = class("PvPTileAssetResourceFieldTroopHead", PvPTileAssetUnit)

function PvPTileAssetResourceFieldTroopHead:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetResourceFieldTroopHead:GetLodPrefabName(lod)
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end

    if not KingdomMapUtils.InSymbolMapLod(lod) then
        local player = ModuleRefer.PlayerModule:GetPlayer()
        if entity.Owner.PlayerID == player.ID or entity.Army and entity.Army.InBattle then
            return ManualResourceConst.troop_map_resources
        end
    end
    return string.Empty
end

function PvPTileAssetResourceFieldTroopHead:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ResourceField.Army.MsgPath, Delegate.GetOrCreate(self, self.OnHPChanged))
end

function PvPTileAssetResourceFieldTroopHead:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ResourceField.Army.MsgPath, Delegate.GetOrCreate(self, self.OnHPChanged))
end

function PvPTileAssetResourceFieldTroopHead:OnConstructionSetup()
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return
    end

    ---@type PvPTileAssetResourceFieldTroopHeadBehavior
    local behavior = self:GetBehavior("PvPTileAssetResourceFieldTroopHeadBehavior")
    if not behavior then
        return
    end

    local armyMemberInfo = ModuleRefer.MapBuildingTroopModule:GetPlayerTroop(entity.Army, entity.Owner.PlayerID)
    if not armyMemberInfo then
        self:Hide()
        return
    end
    local headName = ModuleRefer.MapBuildingTroopModule:GetTroopHeroSpriteName(armyMemberInfo)
    behavior:SetIcon(headName)
    behavior:SetClick(Delegate.GetOrCreate(self, self.OnIconClicked))
    self:OnHPChanged()
end

function PvPTileAssetResourceFieldTroopHead:OnConstructionShutdown()
end

function PvPTileAssetResourceFieldTroopHead:OnIconClicked()
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return
    end
    
    local scene = KingdomMapUtils.GetKingdomScene()
    if scene and scene.mediator then
        local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
        local coord = CS.DragonReborn.Vector2Short(tileX, tileZ)
        scene.mediator:ChooseCoordTile(coord)
    end
end

function PvPTileAssetResourceFieldTroopHead:OnHPChanged()
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return
    end
    
    ---@type PvPTileAssetResourceFieldTroopHeadBehavior
    local behavior = self:GetBehavior("PvPTileAssetResourceFieldTroopHeadBehavior")
    if not behavior then
        return
    end
    
    
    if entity.Army then
        if entity.Army.InBattle then
            behavior:SetStateIcon(ManualResourceConst.sp_troop_icon_status_battle, ManualResourceConst.sp_troop_img_state_base_4)
        else
            behavior:SetStateIcon(ManualResourceConst.sp_troop_img_state_collect, ManualResourceConst.sp_troop_img_state_base_2)
        end

        local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetPlayerTroopHP(entity.Army)
        local hpRatio = hp / hpMax
        behavior:SetHP(hpRatio)
    else
        behavior:SetHP(1)
    end
end

return PvPTileAssetResourceFieldTroopHead