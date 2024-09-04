local PvPTileAssetVFX = require("PvPTileAssetVFX")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local DBEntityType = require('DBEntityType')

---@class PvPTileAssetVFXGateOccupied : PvPTileAssetVFX
local PvPTileAssetVFXGateOccupied = class("PvPTileAssetVFXGateOccupied", PvPTileAssetVFX)

function PvPTileAssetVFXGateOccupied:AutoPlay()
    return false
end

function PvPTileAssetVFXGateOccupied:GetVFXName()
    return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_hudun_start)
end

function PvPTileAssetVFXGateOccupied:GetVFXScale()
    return ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_city_hudun_start)
end

function PvPTileAssetVFXGateOccupied:GetVFXOffset()
    return ArtResourceUtils.GetPosition(ArtResourceConsts.vfx_bigmap_city_hudun_start)
end

function PvPTileAssetVFXGateOccupied:OnShow()
    local entity = self:GetData()
    if not entity then
        return
    end

    self.allianceID = entity.Owner.AllianceID
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
end

function PvPTileAssetVFXGateOccupied:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
end

function PvPTileAssetVFXGateOccupied:OnOwnerChanged()
    local entity = self:GetData()
    if not entity then
        return
    end

    local newAllianceID = entity.Owner.AllianceID
    if self.allianceID ~= newAllianceID and newAllianceID and newAllianceID > 0 then
        if self.behavior then
            self.behavior:ShowEffect(true)
        end
    end

end

return PvPTileAssetVFXGateOccupied
