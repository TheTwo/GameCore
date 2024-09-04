local PvPTileAssetVFX = require("PvPTileAssetVFX")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local DBEntityType = require('DBEntityType')

---@class PvPTileAssetVFXGateBroken : PvPTileAssetVFX
local PvPTileAssetVFXGateBroken = class("PvPTileAssetVFXGateBroken", PvPTileAssetVFX)

function PvPTileAssetVFXGateBroken:AutoPlay()
    return true
end

function PvPTileAssetVFXGateBroken:GetVFXName()
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end

    if ModuleRefer.VillageModule:IsVillageInProtection(entity) then
        return string.Empty
    end

    local hp, maxHP = ModuleRefer.VillageModule:GetVillageHP(entity)
    local durability = entity.Battle.Durability
    local maxDurability = entity.Battle.MaxDurability
    if durability < 0.2 * maxDurability then
        return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_zhaohuo_03)
    elseif durability < 0.5 * maxDurability then
        return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_zhaohuo_02)
    elseif hp < 0.5 * maxHP then
        return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_zhaohuo_01)
    end
    --return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_zhaohuo_03)
    return string.Empty
end


function PvPTileAssetVFXGateBroken:GetVFXScale()
    local entity = self:GetData()
    if not entity then
        return 1
    end
    
    local hp, maxHP = ModuleRefer.VillageModule:GetVillageHP(entity)
    local durability = entity.Battle.Durability
    local maxDurability = entity.Battle.MaxDurability
    if durability < 0.2 * maxDurability then
        return ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_city_zhaohuo_03)
    elseif durability < 0.5 * maxDurability then
        return ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_city_zhaohuo_02)
    elseif hp < 0.5 * maxHP then
        return ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_city_zhaohuo_01)
    end
    return 1
end

function PvPTileAssetVFXGateBroken:OnShow()
    local entity = self:GetData()
    if not entity then
        return
    end

    self.hp = entity.Battle.Hp
    self.durability = entity.Battle.Durability
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.Battle.MsgPath, Delegate.GetOrCreate(self, self.OnBattleChanged))
end

function PvPTileAssetVFXGateBroken:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.Battle.MsgPath, Delegate.GetOrCreate(self, self.OnBattleChanged))
end

function PvPTileAssetVFXGateBroken:OnBattleChanged()
    local entity = self:GetData()
    if not entity then
        return
    end

    local hp, maxHP = ModuleRefer.VillageModule:GetVillageHP(entity)
    if self.hp >= 0.5 * maxHP and hp < 0.5 * maxHP then
        self:Refresh()
    end

    local durability = entity.Battle.Durability
    local maxDurability = entity.Battle.MaxDurability
    if self.durability >= 0.5 * maxDurability and durability < 0.5 * maxDurability then
        self:Refresh()
    elseif self.durability <= 0.2 * maxDurability then
        self:Refresh()
    end

    self.hp = hp
    self.durability = durability
end

return PvPTileAssetVFXGateBroken