local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")

local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")

---@class PvPTileAssetHUDIconCommonMapBuilding:PvPTileAssetHUDIcon
---@field new fun():PvPTileAssetHUDIconCommonMapBuilding
---@field super PvPTileAssetHUDIcon
local PvPTileAssetHUDIconCommonMapBuilding = class('PvPTileAssetHUDIconCommonMapBuilding', PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconCommonMapBuilding:DisplayIcon(lod)
    ---@type wds.CommonMapBuilding
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckIconLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconCommonMapBuilding:DisplayText(lod)
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckTextLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconCommonMapBuilding:DisplayName(lod)
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckNameLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconCommonMapBuilding:OnRefresh(entity)
    ---@type wds.CommonMapBuilding
    local building = entity
    local icon
    local config = ConfigRefer.FlexibleMapBuilding:Find(building.MapBasics.ConfID)
    if ModuleRefer.PlayerModule:IsFriendly(building.Owner) then
        icon = ArtResourceUtils.GetUIItem(config:LodIconOwn())
    else
        icon = ArtResourceUtils.GetUIItem(config:LodIconOther())
    end
    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(building)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(building)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(building.Owner)
    self.behavior:SetIcon(icon)
    self.behavior:AdjustNameLevel(name, level)
    self.behavior:SetNameColor(color)
end

function PvPTileAssetHUDIconCommonMapBuilding:OnIconClick()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, name, level)
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

function PvPTileAssetHUDIconCommonMapBuilding:GetPosition()
    local building = self:GetData()
    if building then
        local config = ConfigRefer.FlexibleMapBuilding:Find(building.MapBasics.ConfID)
        if config then
            if config:Type() == FlexibleMapBuildingType.BehemothDevice then
                local x, z = self:GetServerPosition()
                local xC, zC = self:GetServerCenterPosition()
                x = (x + xC) * 0.5
                z = (z + zC) * 0.5
                local staticMapData = self:GetStaticMapData()
                x = x * staticMapData.UnitsPerTileX
                z = z * staticMapData.UnitsPerTileZ
                local y = KingdomMapUtils.SampleHeight(x, z)
                return CS.UnityEngine.Vector3(x, y, z)
            end
        end
    end
    return PvPTileAssetHUDIconCommonMapBuilding.super.GetPosition(self)
end

return PvPTileAssetHUDIconCommonMapBuilding