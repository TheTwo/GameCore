---@class KingdomSurface
local KingdomSurface = class("KingdomSurface")

---@param mapSystem CS.Grid.MapSystem
---@param hudManager CS.Kingdom.MapHUDManager
function KingdomSurface:Initialize(mapSystem, hudManager)
    self.mapSystem = mapSystem
    self.staticMapData = mapSystem.StaticMapData
    self.root = mapSystem.Parent
    self.hudManager = hudManager
end

function KingdomSurface:Dispose()
end

function KingdomSurface:ClearUnits()
end

function KingdomSurface:OnEnterMap()
end

function KingdomSurface:OnLeaveMap()
end

function KingdomSurface:OnEnterHighLod()
end

function KingdomSurface:OnLeaveHighLod()
end

function KingdomSurface:OnLodChanged(oldLod, newLod)
end

function KingdomSurface:OnSizeChanged(oldSize, newSize)
end

function KingdomSurface:OnIconClick(id)
end

return KingdomSurface