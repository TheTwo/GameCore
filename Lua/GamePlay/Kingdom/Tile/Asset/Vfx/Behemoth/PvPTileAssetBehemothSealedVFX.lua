local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local EventConst = require("EventConst")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetBehemothSealedVFX:PvPTileAssetUnit
---@field new fun():PvPTileAssetBehemothSealedVFX
---@field super PvPTileAssetUnit
local PvPTileAssetBehemothSealedVFX = class('PvPTileAssetBehemothSealedVFX', PvPTileAssetUnit)

function PvPTileAssetBehemothSealedVFX:ctor()
    PvPTileAssetBehemothSealedVFX.super.ctor(self)
    self._territoryId = nil
    ---@type CS.UnityEngine.Vector3
    self._worldPoint = nil
    ---@type CS.UnityEngine.Quaternion
    self._worldRotation = nil
end

function PvPTileAssetBehemothSealedVFX:CanShow()
    if not self._worldPoint then return false end
    ---@type wds.BehemothCage
    local entity = self:GetData()
    if not entity then
        return false
    end
    local notInWaiting = (entity.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting) == 0
    local inBattle = (entity.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInBattle) ~= 0
    local inLock = (entity.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInLocked) ~= 0
    return notInWaiting or inBattle or inLock
end

function PvPTileAssetBehemothSealedVFX:GetLodPrefabName(lod)
    if not KingdomMapUtils.InMapNormalLod(lod) and not KingdomMapUtils.InMapLowLod(lod) then
        return string.Empty
    end
    if not self:CanShow() then
        return string.Empty
    end
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    return ManualResourceConst.vfx_bigmap_jushoulichang_01
end

function PvPTileAssetBehemothSealedVFX:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.BehemothCage.Status.MsgPath, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_CUSTOM_HEX_CHUNK_SHOW, Delegate.GetOrCreate(self, self.OnGroundPrefabReady))
    self._territoryId = nil
    local data = self:GetDataGeneric(wds.BehemothCage)
    self._territoryId = data.BehemothCage.VID
    local go = KingdomMapUtils.GetCustomHexChunkAccess():QueryCustomHexChunkByTerritoryId(self._territoryId)
    self:OnGroundPrefabReady(self._territoryId, go, true)
end

function PvPTileAssetBehemothSealedVFX:OnHide()
    self._worldPoint = nil
    self._worldRotation = nil
    self._territoryId = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.BehemothCage.Status.MsgPath, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_CUSTOM_HEX_CHUNK_SHOW, Delegate.GetOrCreate(self, self.OnGroundPrefabReady))
end

---@param go CS.UnityEngine.GameObject
function PvPTileAssetBehemothSealedVFX:OnGroundPrefabReady(territoryId, go, skipRefresh)
    if not self._territoryId or  self._territoryId ~= territoryId then return end
    if Utils.IsNull(go) then return end
    local trans = go.transform:Find(KingdomMapUtils.GetCustomHexChunkAccess().BehemothGate)
    -- ---@type CS.FXAttachPointHolder
    -- local point = go:GetComponent(typeof(CS.FXAttachPointHolder))
    -- if Utils.IsNull(point) then return end
    -- local trans = point:GetAttachPoint(KingdomMapUtils.GetCustomHexChunkAccess().BehemothGate)
    if Utils.IsNull(trans) then
        g_Logger.Error("巨兽巢穴六边形资源找不到名字应为:%s的门位置节点",KingdomMapUtils.GetCustomHexChunkAccess().BehemothGate) 
        return 
    end
    self._worldPoint = trans.position
    self._worldRotation = trans.rotation
    if skipRefresh then return end
    self:Refresh()
end

function PvPTileAssetBehemothSealedVFX:OnConstructionSetup()
    if not self._worldPoint or not self._worldRotation then return end
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then return end
    asset.transform:SetPositionAndRotation(self._worldPoint, self._worldRotation)
end

function PvPTileAssetBehemothSealedVFX:OnGroundPrefabPreHide(territoryId, oldGo)
    if not self._territoryId or  self._territoryId ~= territoryId then return end
    self._worldPoint = nil
    self._worldRotation = nil
    self:Refresh()
end

---@param entity wds.BehemothCage
function PvPTileAssetBehemothSealedVFX:OnStatusChanged(entity, changed)
    ---@type wds.BehemothCage
    local data = self:GetData()
    if not data or not entity or data.ID ~= entity.ID then return end
    self:Refresh()
end

return PvPTileAssetBehemothSealedVFX