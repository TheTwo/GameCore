local PvPTileAssetVFX = require("PvPTileAssetVFX")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")

local UP = CS.UnityEngine.Vector3.up


---@class PvPTileAssetVFXVillageOccupied : PvPTileAssetVFX
---@field allianceID number
local PvPTileAssetVFXVillageOccupied = class("PvPTileAssetVFXVillageOccupied", PvPTileAssetVFX)

function PvPTileAssetVFXVillageOccupied:AutoPlay()
    return false
end

function PvPTileAssetVFXVillageOccupied:GetVFXName()
    return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_hudun_start)
end

function PvPTileAssetVFXVillageOccupied:GetVFXScale()
    return ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_city_hudun_start)
end

function PvPTileAssetVFXVillageOccupied:GetVFXOffset()
    return ArtResourceUtils.GetPosition(ArtResourceConsts.vfx_bigmap_city_hudun_start)
end

function PvPTileAssetVFXVillageOccupied:OnShow()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return
    end

    self.allianceID = entity.Owner.AllianceID
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
end

function PvPTileAssetVFXVillageOccupied:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
end

function PvPTileAssetVFXVillageOccupied:OnOwnerChanged()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return
    end

    local newAllianceID = entity.Owner.AllianceID
    if self.allianceID ~= newAllianceID and newAllianceID and  newAllianceID > 0 then
        if self.behavior then
            self.behavior:ShowEffect(true)
        end
    end
    
end

return PvPTileAssetVFXVillageOccupied