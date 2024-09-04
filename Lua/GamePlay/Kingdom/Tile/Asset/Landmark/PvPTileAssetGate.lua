local ModuleRefer = require('ModuleRefer')
local PvPTileAssetLandmark = require("PvPTileAssetLandmark")
local Utils = require("Utils")
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityPath = require('DBEntityPath')
local Delegate = require('Delegate')
local KingdomConstant = require('KingdomConstant')
local TimerUtility = require("TimerUtility")
local PvPRequestService = require("PvPRequestService")

---@class PvPTileAssetGate : PvPTileAssetLandmark
---@field behavior PvPTileAssetVillageBehavior
local PvPTileAssetGate = class("PvPTileAssetGate", PvPTileAssetLandmark)

function PvPTileAssetGate:GetLodPrefabName(lod)
    return self:GetLodPrefabInternal(lod)
end
function PvPTileAssetGate:GetLodPrefabInternal(lod)
    -- 无entity数据时，关隘也需要加载到地图上,此时隐藏模型 LOD = 3
    local entity = self:GetData()
    -- 计算 transform相关
    local uniqueId = self:GetUniqueId()
    local staticMapData = self:GetStaticMapData()
    ---@type CS.Grid.DecorationInstance
    local instance, decoration = staticMapData:GetDecorationInstance(uniqueId)
    self.position, self.rotation, self.scale = instance:GetTransform()

    if entity then
        if PvPRequestService.TempFilter(entity) then
            return string.Empty
        end
        
        local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
        local model
        if not KingdomMapUtils.IsMapEntityCreepInfected(entity) then
            model = config:OccupiedModel()
        end
        if not model or model == 0 then
            model = config:Model()
        end
        return ArtResourceUtils.GetItem(model)
    else
        if self.gateRefreshTimer == nil then
            self.gateRefreshTimer = TimerUtility.IntervalRepeat(function()
                local entity = self:GetData()
                if entity then
                    self:HideInternal(false)
                    self:ShowInternal()
                    if self.gateRefreshTimer then
                        self.gateRefreshTimer:Stop()
                        self.gateRefreshTimer = nil
                    end
                end
            end, 0.2, -1)
        end
        return decoration.PrefabName
    end

end
function PvPTileAssetGate:OnConstructionSetup()
    local entity = self:GetData()
    if entity == nil then
        return
    end

    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))

    self.isOccupied = ModuleRefer.VillageModule:HasBeenOccupied(entity)
    ---@type CS.UnityEngine.GameObject
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        self:Hide()
        return
    end

    local lua = asset.transform:GetLuaBehaviour("PvPTileAssetVillageBehavior")
    if not lua then
        g_Logger.Error(string.format("can't find lua behaviour on %s", asset.name))
        return
    end
    self.behavior = lua.Instance
    self.isDead = ModuleRefer.VillageModule:IsVillageTroopDead(entity)
    self.playDeadAnim = false
    self.playAttackLoop = false
    self:RefreshModel()
    self:RefreshAnim(entity)
end

function PvPTileAssetGate:OnConstructionShutdown()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))

    if self.gateRefreshTimer then
        self.gateRefreshTimer:Stop()
        self.gateRefreshTimer = nil
    end

    if self.behavior then
        self.behavior:ClearAllVfx()
    end
    self.behavior = nil
    self.isOccupied = false
end

function PvPTileAssetGate:OnConstructionUpdate()
    local entity = self:GetData()
    self:RefreshModel()
    self:RefreshAnim(entity)
end

function PvPTileAssetGate:RefreshModel()
    local lod = KingdomMapUtils.GetLOD()
    if lod < KingdomConstant.SymbolLod then
        self:Show()
    else
        self:Hide()
    end
end

function PvPTileAssetGate:RefreshAnim(entity)
    if not entity or self.behavior == nil then
        return
    end

    if self.playDeadAnim then
        -- 已播放死亡动画
        return
    end

    if not self.isDead and ModuleRefer.VillageModule:IsVillageTroopDead(entity) then
        -- 守军死完后 炮塔开始死亡
        self.behavior:StopTowerAnim()
        self.behavior:PlayTowerAnim("death")
        self.isDead = true
        self.playDeadAnim = true
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    elseif self.isDead then
        -- 炮塔死亡待机
        self.behavior:StopTowerAnim()
        self.behavior:PlayTowerAnim("death", 1)
    elseif entity.PassInfo.InBattle then
        -- 炮塔战斗 调用x次 refresh时 播一次动画
        if not self.playAttackLoop then
            self.behavior:StopTowerAnim()
            self.playAttackLoop = true
            self.behavior:PlayBattleTowerAnim()
        end
    else
        -- 炮塔待机
        self.behavior:StopTowerAnim()
        self.behavior:PlayTowerAnim("idle")
        self.playAttackLoop = false
    end
end

-- 占领后切换模型
function PvPTileAssetGate:OnOwnerChanged()
    self:Refresh()
end

-- 守军战斗时播炮塔动画
function PvPTileAssetGate:OnArmyChanged()
    self:Refresh()
end

---@param entity wds.Village
function PvPTileAssetGate:OnCreepInfectedChanged(entity, _)
    if entity.Id ~= self.view.uniqueId then
        return
    end
    self:Refresh()
end

return PvPTileAssetGate
