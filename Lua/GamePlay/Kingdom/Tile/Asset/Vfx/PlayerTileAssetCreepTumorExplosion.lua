local MapTileAssetUnit = require("MapTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local PoolUsage = require("PoolUsage")
local ModuleRefer = require("ModuleRefer")
local AudioConsts = require("AudioConsts")

local VisualEffectHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle
local One = CS.UnityEngine.Vector3.one

---@class PlayerTileAssetCreepTumorExplosion : MapTileAssetUnit
---@field vfxHandle CS.DragonReborn.VisualEffect.VisualEffectHandle
---@field prevPosition CS.UnityEngine.Vector3
local PlayerTileAssetCreepTumorExplosion = class("PlayerTileAssetCreepTumorExplosion", MapTileAssetUnit)

function PlayerTileAssetCreepTumorExplosion:GetLodPrefabName(lod)
    return string.Empty
end

function PlayerTileAssetCreepTumorExplosion:GetPosition()
    return self:CalculateCenterPosition()
end

function PlayerTileAssetCreepTumorExplosion:GetScale()
    --return One * 20
    return One * ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_juntangbaozha)
end

function PlayerTileAssetCreepTumorExplosion:OnShow()
    ---@type wds.PlayerMapCreep
    local creepData = self:GetData()
    if not creepData then
        return
    end
    
    self.vfxHandle = VisualEffectHandle()
    self.isAlive = ModuleRefer.MapCreepModule:IsTumorAlive(creepData)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerMapCreeps.Creeps.MsgPath, Delegate.GetOrCreate(self, self.OnCreepsChanged))
end

function PlayerTileAssetCreepTumorExplosion:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerMapCreeps.Creeps.MsgPath, Delegate.GetOrCreate(self, self.OnCreepsChanged))
    --if self.vfxHandle then
    --    self.vfxHandle:Delete()
    --    self.vfxHandle = nil
    --end
end

function PlayerTileAssetCreepTumorExplosion:OnCreepsChanged(entity, changeTable)
    ---@type wds.PlayerMapCreep
    local creepData = self:GetData()
    if not creepData then
        return
    end
    
    local isAlive = ModuleRefer.MapCreepModule:IsTumorAlive(creepData)
    if self.isAlive ~= isAlive then
        self:Play()
    end

    self.isAlive = isAlive
end

---@param userData PlayerTileAssetCreepTumorExplosion
---@param handle CS.DragonReborn.VisualEffect.VisualEffectHandle
local function OnLoaded(isSuccess, userData, handle)
    local trans = handle.Effect.transform
    trans.position = userData.prevPosition
    trans.localScale = userData:GetScale()
    userData.prevPosition = nil
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_se_world_pustuleexplosion)
end

function PlayerTileAssetCreepTumorExplosion:Play()
    if KingdomMapUtils.InMapNormalLod() then
        --"vfx_bigmap_juntangbaozha"
        local vfxName = ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_juntangbaozha)
        self.prevPosition = self:GetPosition()
        self.vfxHandle:Create(vfxName, PoolUsage.Map, KingdomMapUtils.GetMapSystem().Parent, OnLoaded, self)
    end
end


return PlayerTileAssetCreepTumorExplosion