---@class CityZone
---@field new fun(block:CityZoneManager, config:CityZoneConfigCell):CityZone
---@field mgr CityZoneManager
---@field config CityZoneConfigCell
---@field id number
---@field singleExploring boolean
local CityZone = class("CityZone")
local CityZoneStatus = require("CityZoneStatus")

---@param mgr CityZoneManager
---@param config CityZoneConfigCell
function CityZone:ctor(mgr, config)
    self.mgr = mgr
    self.config = config
    self.id = config:Id()
    self.status = config:InitialStatus()
    self.isSingleSeExplorer = config:InitSingleSeExplorMode()
    self.singleExploring = false
end

function CityZone:UpdateStatus(status)
    self.status = status
end

function CityZone:UpdateSingleSeExplorer(isSingleSeExplorer)
    self.isSingleSeExplorer = isSingleSeExplorer
end

function CityZone:UpdateSingleExploring(singleExploring)
    self.singleExploring = singleExploring
end

function CityZone:SingleSeExplorerOnly()
    return self.isSingleSeExplorer and self.status <= CityZoneStatus.Explored
end

function CityZone:NotExplore()
    return self.status == CityZoneStatus.NotExplore
end

function CityZone:Explored()
    return self.status == CityZoneStatus.Explored
end

function CityZone:Recovered()
    return self.status == CityZoneStatus.Recovered
end

function CityZone:IsHideFog()
    return self.status >= CityZoneStatus.Explored
end

function CityZone:IsHideFogForExploring()
    return self.status > CityZoneStatus.Explored or self.singleExploring
end

function CityZone:WorldPlaneCenter()
    local center = self.config:CenterPos()
    local x, y = center:X(), center:Y()
    return self.mgr.city:GetPlanePositionFromCoord(x, y)
end

function CityZone:WorldCenter()
    local center = self.config:CenterPos()
    local x, y = center:X(), center:Y()
    return self.mgr.city:GetWorldPositionFromCoord(x, y)
end

function CityZone:PopBubblePosition()
    local center = self.config:RecoverPopPos()
    local x, y = center:X(), center:Y()
    return self.mgr.city:GetWorldPositionFromCoord(x, y)
end

return CityZone
