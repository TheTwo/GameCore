local PvPTileAssetVFX = require("PvPTileAssetVFX")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetBuildingCompleteVfx : PvPTileAssetVFX
---@field super PvPTileAssetVFX
---@field status wds.BuildingConstructionStatus
local PvPTileAssetBuildingCompleteVfx = class("PvPTileAssetBuildingCompleteVfx", PvPTileAssetVFX)

function PvPTileAssetBuildingCompleteVfx:ctor()
    PvPTileAssetBuildingCompleteVfx.super.ctor(self)
    ---@type CS.DragonReborn.VisualEffect.SimpleVisualEffect
    self._effect = nil
end

function PvPTileAssetBuildingCompleteVfx:GetVFXName()
    return ManualResourceConst.vfx_common_build_Box_01
end

function PvPTileAssetBuildingCompleteVfx:AutoPlay()
    return false
end

function PvPTileAssetBuildingCompleteVfx:GetVFXScale()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity or not entity.Construction then
        return PvPTileAssetBuildingCompleteVfx.super.GetVFXScale(self)
    end
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(entity)
    return math.max(layout.SizeX, layout.SizeY, 1) * 3
end

function PvPTileAssetBuildingCompleteVfx:OnConstructionSetup()
    if self.handle and Utils.IsNotNull(self.handle.Asset ) then
        self._effect = self.handle.Asset :GetComponent(typeof(CS.DragonReborn.VisualEffect.SimpleVisualEffect))
        if Utils.IsNotNull(self._effect) then
            self._effect.autoDelete = false
            self._effect.autoPlay = false
            self._effect:SetVisible(false)
        end
    end
    self.status = PvPTileAssetBuildingCompleteVfx.GetStatus(self.view.uniqueId, self.view.typeId)
    self:HideEffect()
end

function PvPTileAssetBuildingCompleteVfx:OnConstructionShutdown()
    self:HideEffect()
    self.status = nil
end

function PvPTileAssetBuildingCompleteVfx:OnConstructionUpdate()
    local newStatus = PvPTileAssetBuildingCompleteVfx.GetStatus(self.view.uniqueId, self.view.typeId)
    if self.status == wds.BuildingConstructionStatus.BuildingConstructionStatusProcessing
            and newStatus == wds.BuildingConstructionStatus.BuildingConstructionStatusDone then
        self:ShowEffect()
    end
    self.status = newStatus
end

function PvPTileAssetBuildingCompleteVfx.GetStatus(uniqueId, typeId)
    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if not entity or not entity.Construction then
        return
    end
    return entity.Construction.Status
end

function PvPTileAssetBuildingCompleteVfx:ShowEffect()
    if Utils.IsNotNull(self._effect) then
        self._effect:SetVisible(true)
        self._effect:ResetEffect()
        self._effect:Play()
    end
end

function PvPTileAssetBuildingCompleteVfx:HideEffect()
    if Utils.IsNotNull(self._effect) then
        self._effect:Stop()
        self._effect:SetVisible(false)
    end
end

return PvPTileAssetBuildingCompleteVfx