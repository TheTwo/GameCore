local MapTileAssetSolo = require("MapTileAssetSolo")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local MapEntityConstructingProgress = require("MapEntityConstructingProgress")
local ConfigRefer = require("ConfigRefer")
local MapHudTransformControl = require("MapHudTransformControl")
local MapTileAssetUnit = require("MapTileAssetUnit")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetHudBuild : MapTileAssetUnit
---@field super MapTileAssetUnit
---@field constructing MapEntityConstructingProgress
---@field finished boolean
local PvPTileAssetHudBuild = class("PvPTileAssetHudBuild", MapTileAssetUnit)

function PvPTileAssetHudBuild:ctor()
    PvPTileAssetHudBuild.super.ctor(self)
    self.finished = true
end

function PvPTileAssetHudBuild:GetLodPrefabName(lod)
    if self:CanShow() and KingdomMapUtils.InMapNormalLod(lod) then
        return ManualResourceConst.ui3d_bubble_progress
    end
    return string.Empty
end

function PvPTileAssetHudBuild:CanShow()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return false
    end
    self.finished = MapEntityConstructingProgress.IsFinished(entity)
    return not self.finished
end

function PvPTileAssetHudBuild:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetHudBuild:OnConstructionSetup()
    PvPTileAssetHudBuild.super.OnConstructionSetup(self)
    ---@type wds.EnergyTower
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    
    if not self.constructing then
        self.constructing = MapEntityConstructingProgress.new()
    end
    self.constructing:Setup(self:GetAsset())
    self:UpdateProgress()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
end

function PvPTileAssetHudBuild:OnConstructionShutdown()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
    if self.constructing then
        self.constructing:ShutDown()
    end
    self.finished = true
    
    PvPTileAssetHudBuild.super.OnConstructionShutdown(self)
end

function PvPTileAssetHudBuild:SecondTick()
    self:UpdateProgress()
end

function PvPTileAssetHudBuild:UpdateProgress()
    ---@type wds.EnergyTower|wds.DefenceTower
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    local sizeX, sizeZ, margin = KingdomMapUtils.GetLayoutSize(buildingConfig:Layout())
    local offset = MapHudTransformControl.CalculateTopOffsetBySize(sizeX, sizeZ, margin, KingdomMapUtils.GetStaticMapData())
    self.constructing:SetOffset(offset)

    self.finished = self.constructing:UpdateProgress(entity)
    if self.finished then
        self:Hide()
    end
end

return PvPTileAssetHudBuild