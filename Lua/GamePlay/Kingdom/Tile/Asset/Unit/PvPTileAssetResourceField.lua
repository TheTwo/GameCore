local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local PoolUsage = require("PoolUsage")
local Delegate = require("Delegate")
local Utils = require("Utils")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")
local Layers = require("Layers")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")

---@class PvPTileAssetResourceField : PvPTileAssetUnit
local PvPTileAssetResourceField = class("PvPTileAssetResourceField", PvPTileAssetUnit)

---@return string
function PvPTileAssetResourceField:GetLodPrefabName(lod)
    if lod == 0 then
        return string.Empty
    end

    if not KingdomMapUtils.InMapNormalLod(lod) then
        return string.Empty
    end

    local uniqueId = self:GetUniqueId()
    local typeId = self:GetTypeId()
    if typeId ~= wds.ResourceField.TypeHash then
        return string.Empty
    end

    ---@type wds.ResourceField
    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if entity == nil then
        return string.Empty
    end

    local cfg = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    if cfg == nil then
        return string.Empty
    end

    self.normalAnim = self:GetNormalAnim(cfg)
    self.occupiedAnim = self:GetOccupiedAnim(cfg)
    return ArtResourceUtils.GetItem(cfg:Model())
end

function PvPTileAssetResourceField:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ResourceField.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ResourceField.FieldInfo.AllianceId.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ResourceField.FieldInfo.EndGatherTime.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
end

function PvPTileAssetResourceField:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ResourceField.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ResourceField.FieldInfo.AllianceId.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ResourceField.FieldInfo.EndGatherTime.MsgPath, Delegate.GetOrCreate(self, self.OnDataRefreshed))
end

function PvPTileAssetResourceField:OnDataRefreshed()
    local entity = self:GetData()
    if not entity then
        return
    end
    
    ModuleRefer.KingdomTouchInfoModule:RefreshCurrentTouchMenu(entity)
end

function PvPTileAssetResourceField:OnConstructionSetup()
    PvPTileAssetUnit.OnConstructionSetup(self)
    self.status = self:GetStatus()
    self.createHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create(PoolUsage.Map)

    local asset = self:GetAsset()
    if Utils.IsNull(asset) then return end

    local animation = asset:GetComponent(typeof(CS.UnityEngine.Animation))
    if Utils.IsNull(animation) then return end

    self.animation = animation
    self:PlayAnimationByState()
end

function PvPTileAssetResourceField:OnConstructionShutdown()
    self.status = nil
    if self.createHelper then
        self.createHelper:DeleteAll()
        self.createHelper = nil
    end
end

function PvPTileAssetResourceField:OnConstructionUpdate()
    local newStatus = self:GetStatus()
    if newStatus ~= self.status then
        self:PlayAnimationByState()
    end
    if self.status == wds.ResourceFieldState.ResourceStateBuilding and newStatus == wds.ResourceFieldState.ResourceStateOccupied then
        self:ShowEffect()
    end
    self.status = newStatus
end

function PvPTileAssetResourceField:GetStatus()
    local typeId = self:GetTypeId()
    if typeId ~= wds.ResourceField.TypeHash then return nil end

    local uniqueId = self:GetUniqueId()
    ---@type wds.ResourceField
    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if entity == nil then return nil end

    return entity.FieldInfo.State
end

function PvPTileAssetResourceField:ShowEffect()
    self.createHelper:Create(ManualResourceConst.vfx_common_base_accomplish, self:GetMapSystem().Parent, Delegate.GetOrCreate(self, self.OnVfxCreated))
end

---@param go CS.UnityEngine.GameObject
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function PvPTileAssetResourceField:OnVfxCreated(go, userdata, handle)
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    go:SetLayerRecursively(Layers.Tile)
    local trans = go.transform
    trans:SetPositionAndRotation(self:CalculateCenterPosition(), self:GetRotation())
    trans.localScale = self:GetScale()
    handle:Delete(5)
end

function PvPTileAssetResourceField:GetNormalAnim(cfg)
    return string.Empty
end

function PvPTileAssetResourceField:GetOccupiedAnim(cfg)
    return string.Empty
end

function PvPTileAssetResourceField:PlayAnimationByState()
    if Utils.IsNull(self.animation) then return end

    local animationName = self:GetAnimationNameByState()
    if string.IsNullOrEmpty(animationName) then return end

    self.animation:Play(animationName)
end

function PvPTileAssetResourceField:GetAnimationNameByState()
    if self.status == nil then return end
    if self.status == wds.ResourceFieldState.ResourceStateNormal then
        return self.normalAnim
    else
        return self.occupiedAnim
    end
end

return PvPTileAssetResourceField