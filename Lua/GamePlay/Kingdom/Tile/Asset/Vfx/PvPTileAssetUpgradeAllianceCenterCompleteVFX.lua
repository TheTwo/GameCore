local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")

local PvPTileAssetVFX = require("PvPTileAssetVFX")

---@class PvPTileAssetUpgradeAllianceCenterCompleteVFX:PvPTileAssetVFX
---@field new fun():PvPTileAssetUpgradeAllianceCenterCompleteVFX
---@field super PvPTileAssetVFX
local PvPTileAssetUpgradeAllianceCenterCompleteVFX = class('PvPTileAssetUpgradeAllianceCenterCompleteVFX', PvPTileAssetVFX)

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:ctor()
    PvPTileAssetUpgradeAllianceCenterCompleteVFX.super.ctor(self)
    ---@type CS.DragonReborn.VisualEffect.ParticleVisualEffect
    self._effect = nil
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:GetPosition()
    return self:CalculatePosition()
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:GetVFXName()
    return ManualResourceConst.vfx_s_city_building_lvup
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:AutoPlay()
    return false
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:GetVFXScale()
    ---@type wds.Village
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity or not entity.VillageTransformInfo then
        return PvPTileAssetUpgradeAllianceCenterCompleteVFX.super.GetVFXScale(self)
    end
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(entity)
    return math.max(layout.SizeX, layout.SizeY, 1) * 0.68
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:OnConstructionSetup()
    if self.handle and Utils.IsNotNull(self.handle.Asset) then
        self._effect = self.handle.Asset :GetComponent(typeof(CS.DragonReborn.VisualEffect.ParticleVisualEffect))
        if Utils.IsNotNull(self._effect) then
            self._effect.autoDelete = false
            self._effect.autoPlay = false
            self._effect:SetVisible(false)
        end
    end
    self.status = PvPTileAssetUpgradeAllianceCenterCompleteVFX.GetStatus(self.view.uniqueId, self.view.typeId)
    self:HideEffect()
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:OnConstructionShutdown()
    self:HideEffect()
    self.status = nil
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnStatusChanged))
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnStatusChanged))
end

---@param entity wds.Village
function PvPTileAssetUpgradeAllianceCenterCompleteVFX:OnStatusChanged(entity, _)
    local data = self:GetData()
    if not data or not entity or data.ID ~= entity.ID then return end
    self:OnConstructionUpdate()
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:OnConstructionUpdate()
    local newStatus = PvPTileAssetUpgradeAllianceCenterCompleteVFX.GetStatus(self.view.uniqueId, self.view.typeId)
    if self.status == wds.VillageTransformStatus.VillageTransformStatusProcessing
            and newStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
        self:ShowEffect()
    end
    self.status = newStatus
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX.GetStatus(uniqueId, typeId)
    ---@type wds.Village
    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if not entity or not entity.VillageTransformInfo then
        return
    end
    return entity.VillageTransformInfo.Status
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:ShowEffect()
    if Utils.IsNotNull(self._effect) then
        self._effect:SetVisible(true)
        self._effect:ResetEffect()
        self._effect:Play()
    end
end

function PvPTileAssetUpgradeAllianceCenterCompleteVFX:HideEffect()
    if Utils.IsNotNull(self._effect) then
        self._effect:Stop()
        self._effect:SetVisible(false)
    end
end

return PvPTileAssetUpgradeAllianceCenterCompleteVFX