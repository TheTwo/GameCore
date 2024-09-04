local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local ModuleRefer = require("ModuleRefer")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local Delegate = require("Delegate")
local Utils = require("Utils")
local EventConst = require("EventConst")

---@class PvPTileAssetHUDIconCastle : PvPTileAssetHUDIcon
local PvPTileAssetHUDIconCastle = class("PvPTileAssetHUDIconCastle", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconCastle:OnShow()
    PvPTileAssetHUDIconCastle.super.OnShow(self)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
end

function PvPTileAssetHUDIconCastle:OnHide()
    PvPTileAssetHUDIconCastle.super.OnHide(self)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
end

function PvPTileAssetHUDIconCastle:OnRefresh(entity)
    ---@type wds.CastleBrief
    local castleEntity = entity
    local lod = KingdomMapUtils.GetLOD()
    local icon = ModuleRefer.MapBuildingTroopModule:GetBuildingIcon(entity, lod)
    self.behavior:SetIcon(icon)
    self:SetName(castleEntity, lod)
    self.behavior:SetOrthographicScale(0.0004)
end

---@param castleBrief wds.CastleBrief
function PvPTileAssetHUDIconCastle:SetName(castleBrief, lod)
    if Utils.IsNull(self.behavior) then
        return
    end

    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(castleBrief)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(castleBrief)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(castleBrief.Owner, false, true)

    if not self:DisplayName(lod) and not self:DisplayText(lod) then
        self.behavior:SetName(name)
        self.behavior:SetLevel(level)
        self.behavior:SetNameColor(color)
        self.behavior:AdjustNameLevel()
        return
    end
    
    self.behavior:AdjustNameLevel(name, level)
    ---other player is Hostile - alliance == 0, see OnRefresh IsHostile
    self.behavior:SetNameColor(color)
end

function PvPTileAssetHUDIconCastle:DisplayText(lod)
    return KingdomMapUtils.InMapNormalLod(lod)
end

function PvPTileAssetHUDIconCastle:DisplayName(lod)
    return KingdomMapUtils.InMapNormalLod(lod)
end

function PvPTileAssetHUDIconCastle:OnIconClick()
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

function PvPTileAssetHUDIcon:OnOwnerChanged(castle)
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    if not self.behavior then
        return
    end

    if entity.ID == castle.ID then
        --self:OnRefresh(entity)
    end
end

function PvPTileAssetHUDIcon:OnAllianceChanged()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    if not self.behavior then
        return
    end

    --self:OnRefresh(entity)
end

return PvPTileAssetHUDIconCastle