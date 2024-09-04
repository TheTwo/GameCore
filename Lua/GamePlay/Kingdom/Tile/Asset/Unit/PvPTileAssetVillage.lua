local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")

local Animator = CS.UnityEngine.Animator
local ListComponent = CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Component))

---@class PvPTileAssetVillage : PvPTileAssetUnit
---@field behavior PvPTileAssetVillageBehavior
---@field isOccupied boolean
local PvPTileAssetVillage = class("PvPTileAssetVillage", PvPTileAssetUnit)

function PvPTileAssetVillage:ctor()
    PvPTileAssetVillage.super.ctor(self)
    self.entityHash = nil
    self.entityId = nil
    self.inViewIndex = nil
    self.basicCamera = nil
    self.coordMin = CS.DragonReborn.Vector2Short.Zero
    self.coordMax = CS.DragonReborn.Vector2Short.Zero
end

---@return string
function PvPTileAssetVillage:GetLodPrefabName(lod)
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(entity.MapBasics.ConfID, lod) then
        local model
        if not KingdomMapUtils.IsMapEntityCreepInfected(entity) then
            model = config:OccupiedModel()
        end
        if not model or model == 0 then
            model = config:Model()
        end
        return ArtResourceUtils.GetItem(model)
    end
    return string.Empty
end

function PvPTileAssetVillage:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Strengthen.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function PvPTileAssetVillage:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Strengthen.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function PvPTileAssetVillage.IsNotifyInViewLod(lod)
    return KingdomMapUtils.InMapNormalLod(lod)
end

function PvPTileAssetVillage:OnConstructionSetup()
    PvPTileAssetVillage.super.OnConstructionSetup(self)
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        self:Hide()
        return
    end

    ---@type CS.UnityEngine.GameObject
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        self:Hide()
        return
    end

    local lua = asset:GetLuaBehaviour("PvPTileAssetVillageBehavior")
    if not lua then
        g_Logger.Error(string.format("can't find lua behaviour on %s", asset.name))
        return
    end

    self.behavior = lua.Instance
    self.isDead = ModuleRefer.VillageModule:IsVillageTroopDead(entity)
    self.playDeadAnim = false
    self.playAttackLoop = false
    self.isOccupied = ModuleRefer.VillageModule:HasBeenOccupied(entity)
    self:RefreshAnim(entity)

    self.entityHash = entity.TypeHash
    self.entityId = entity.ID
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self.basicCamera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
    local serverPosX, serverPosY = self:GetServerPosition()
    local serverCenterPosX, serverCenterPosY = self:GetServerCenterPosition()
    local maxPosX, maxPosY = serverCenterPosX * 2 - serverPosX, serverCenterPosY * 2 - serverPosY
    self.coordMin = CS.DragonReborn.Vector2Short(serverPosX, serverPosY)
    self.coordMax = CS.DragonReborn.Vector2Short(maxPosX, maxPosY)
    self:UpdateCamera()
end

function PvPTileAssetVillage:OnConstructionShutdown()
    if self.behavior then
        self.behavior:ClearAllVfx()
    end
    self.behavior = nil
    self.isOccupied = false
    self.entityHash = nil
    self.entityId = nil
    if self.basicCamera then
        self.basicCamera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
    end
    self.basicCamera = nil
    if self.inViewIndex then
        ModuleRefer.VillageModule:ReleaseCurrentInViewVillage(self.inViewIndex)
    end
    self.inViewIndex = nil
end

function PvPTileAssetVillage:OnConstructionUpdate()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return
    end

    if not self.behavior then
        return
    end

    self:RefreshAnim(entity)
end
---@param entity wds.Village
function PvPTileAssetVillage:RefreshAnim(entity)
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
    elseif self.isDead then
        -- 炮塔死亡待机
        self.behavior:StopTowerAnim()
        self.behavior:PlayTowerAnim("death", 1)
    elseif entity.Village.InBattle then
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

---@param entity wds.Village
function PvPTileAssetVillage:OnCreepInfectedChanged(entity, _)
    if entity.Id ~= self.view.uniqueId then
        return
    end
    self:Refresh()
end

function PvPTileAssetVillage:OnDataRefreshed()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return
    end
    
    ModuleRefer.KingdomTouchInfoModule:RefreshCurrentTouchMenu(entity)
end

function PvPTileAssetVillage:OnSecond()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return
    end
    
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local _, countDown = ModuleRefer.VillageModule:GetVillageCountDown(entity, myAllianceData)
    if countDown ~= self.countDown then
        if countDown == 0 and self.countDown ~= 0 then
            ModuleRefer.KingdomTouchInfoModule:RefreshCurrentTouchMenu(entity)
        end
        self.countDown = countDown
    end
    
    local protectionExpireTime = ModuleRefer.VillageModule:GetVillageProtectEndTimestamp(entity)
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local protectLeftTime = protectionExpireTime - serverTime
    if protectLeftTime ~= self.protectLeftTime then
        if protectLeftTime == 0 and self.protectLeftTime ~= 0 then
            ModuleRefer.KingdomTouchInfoModule:RefreshCurrentTouchMenu(entity)
        end
        self.protectLeftTime = protectLeftTime
    end
end

function PvPTileAssetVillage:UpdateCamera()
    local lod = KingdomMapUtils.GetLOD()
    if not PvPTileAssetVillage.IsNotifyInViewLod(lod) then
        if self.inViewIndex then
            ModuleRefer.VillageModule:ReleaseCurrentInViewVillage(self.inViewIndex)
        end
        self.inViewIndex = nil
        return
    end
    local camera = self.basicCamera.mainCamera
    local projection = CS.Grid.CameraUtils.CalculateFrustumProjectionOnPlane(camera, camera.nearClipPlane, camera.farClipPlane, self.basicCamera:GetBasePlane())
    local cameraBox = CS.Grid.CameraUtils.CalculateFrustumProjectionAABB(projection)
    local min, max = cameraBox.min, cameraBox.max
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local coordMin = CS.Grid.MapUtils.CalculateWorldPositionToCoord(min, staticMapData)
    local coordMax = CS.Grid.MapUtils.CalculateWorldPositionToCoord(max, staticMapData)
    if self.coordMin.X > coordMax.X or self.coordMin.Y > coordMax.Y or self.coordMax.X < coordMin.X or self.coordMax.Y < coordMin.Y then
        if self.inViewIndex then
            ModuleRefer.VillageModule:ReleaseCurrentInViewVillage(self.inViewIndex)
        end
        self.inViewIndex = nil
    elseif not self.inViewIndex then
        self.inViewIndex = ModuleRefer.VillageModule:SetCurrentInViewVillage(self.entityHash, self.entityId)
    end
end

return PvPTileAssetVillage
