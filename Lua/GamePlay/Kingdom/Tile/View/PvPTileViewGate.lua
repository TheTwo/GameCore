local MapTileView = require("MapTileView")
local PvPTileAssetHUDConstructionGate = require("PvPTileAssetHUDConstructionGate")
local PvPTileAssetHUDIconGate = require("PvPTileAssetHUDIconGate")
local PvPTileAssetProtectionShield = require("PvPTileAssetProtectionShield")
local PvPTileAssetHUDFighting = require("PvPTileAssetHUDFighting")
local PvPTileAssetVFXGateBroken = require("PvPTileAssetVFXGateBroken")
local PvPTileAssetVFXGateOccupied = require("PvPTileAssetVFXGateOccupied")
local PvPTileAssetHUDTroopHead = require("PvPTileAssetHUDTroopHead")
-- local PvPTileAssetHUDBeamRedVfx = require("PvPTileAssetHUDBeamRedVfx")
local PvPTileAssetVillageWarningBreath = require("PvPTileAssetVillageWarningBreath")

---@class PvPTileViewGate : MapTileView
local PvPTileViewGate = class("PvPTileViewGate", MapTileView)

function PvPTileViewGate:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetHUDConstructionGate.new())
    self:AddAsset(PvPTileAssetHUDIconGate.new())
    self:AddAsset(PvPTileAssetProtectionShield.new())
    self:AddAsset(PvPTileAssetHUDFighting.new())
    self:AddAsset(PvPTileAssetVFXGateBroken.new())
    self:AddAsset(PvPTileAssetVFXGateOccupied.new())
    self:AddAsset(PvPTileAssetHUDTroopHead.new())
    self:AddAsset(PvPTileAssetVillageWarningBreath.new())

    -- 攻占时特效
    -- self:AddAsset(PvPTileAssetHUDBeamRedVfx.new())
end

return PvPTileViewGate
