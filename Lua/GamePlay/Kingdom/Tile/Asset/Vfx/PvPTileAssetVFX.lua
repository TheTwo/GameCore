local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")

local Vector3 = CS.UnityEngine.Vector3
local One = Vector3.one
local Zero = Vector3.zero

---@class PvPTileAssetVFX : PvPTileAssetUnit
---@field behavior PvPTileAssetVFXBehavior
local PvPTileAssetVFX = class("PvPTileAssetVFX", PvPTileAssetUnit)

function PvPTileAssetVFX:AutoPlay()
    return true
end

function PvPTileAssetVFX:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        return self:GetVFXName(lod)
    end
    return string.Empty
end

function PvPTileAssetVFX:GetPosition()
    local entity = self:GetData()
    if not entity then
        return Zero
    end
    return self:CalculateCenterPosition() + self:GetVFXOffset()
end

function PvPTileAssetVFX:GetScale()
    local entity = self:GetData()
    if not entity then
        return One
    end

    return One * self:GetVFXScale()
end

function PvPTileAssetVFX:OnConstructionSetup()
    PvPTileAssetVFX.super.OnConstructionSetup(self)
    
    local asset = self:GetAsset()
    self.behavior = asset:GetLuaBehaviour("PvPTileAssetVFXBehavior").Instance

    if self.behavior then
        self.behavior:ShowEffect(self:AutoPlay())
    else
        self:Hide()
    end
    
    self:OnRefresh()
end

function PvPTileAssetVFX:OnConstructionShutdown()
    if self.behavior then
        self.behavior:ShowEffect(false)
    end
    PvPTileAssetVFX.super.OnConstructionShutdown(self)
end

function PvPTileAssetVFX:OnConstructionUpdate()
    PvPTileAssetVFX.super.OnConstructionUpdate(self)
    self:OnRefresh()
end

function PvPTileAssetVFX:GetVFXName(lod)
    -- override this
    return string.Empty
end

function PvPTileAssetVFX:GetVFXOffset()
    -- override this
    return Zero
end

function PvPTileAssetVFX:GetVFXScale()
    -- override this
    return 1
end

function PvPTileAssetVFX:OnRefresh()
    -- override this
end

return PvPTileAssetVFX