local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetHud : PvPTileAssetUnit
---@field root CS.UnityEngine.Transform
local PvPTileAssetHud = class("PvPTileAssetHud", PvPTileAssetUnit)

function PvPTileAssetHud:ctor()
    PvPTileAssetUnit.ctor(self)
end

function PvPTileAssetHud:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetHud:OnConstructionSetup()
    self.root = self.handle.Asset.transform
end

function PvPTileAssetHud:OnConstructionShutdown()
    self.root = nil
end

return PvPTileAssetHud