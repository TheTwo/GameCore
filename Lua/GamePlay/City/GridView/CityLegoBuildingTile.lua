local CityTileBase = require("CityTileBase")
---@class CityLegoBuildingTile:CityTileBase
---@field new fun():CityLegoBuildingTile
local CityLegoBuildingTile = class("CityLegoBuildingTile", CityTileBase)
local CityTilePriority = require("CityTilePriority")
local CityConst = require("CityConst")
local Rect = require("Rect")

---@param gridView CityGridView
---@param legoBuilding CityLegoBuilding
function CityLegoBuildingTile:ctor(gridView, legoBuilding)
    CityTileBase.ctor(self, gridView, legoBuilding.x, legoBuilding.z)
    self.legoId = legoBuilding.id
end

function CityLegoBuildingTile:GetPriority()
    return CityTilePriority.BUILDING
end

function CityLegoBuildingTile:GetCameraSize()
    return CityConst.BUILDING_MAX_VIEW_SIZE
end

function CityLegoBuildingTile:GetCell()
    return self.gridView.legoManager:GetLegoBuilding(self.legoId)
end

function CityLegoBuildingTile:GetWorldCenter()
    local legoBuilding = self:GetCell()
    return legoBuilding:GetWorldCenter()
end

function CityLegoBuildingTile:IsPolluted()
    ---TODO:污染问题没有设计
    return false
end

function CityLegoBuildingTile:SizeX()
    local legoBuilding = self:GetCell()
    return legoBuilding.sizeX
end

function CityLegoBuildingTile:SizeY()
    local legoBuilding = self:GetCell()
    return legoBuilding.sizeZ
end

function CityLegoBuildingTile:GetRect()
    local legoBuilding = self:GetCell()
    return Rect.new(legoBuilding.x, legoBuilding.z, legoBuilding.sizeX, legoBuilding.sizeZ)
end

function CityLegoBuildingTile:Movable()
    local legoBuilding = self:GetCell()
    return legoBuilding:Movable()
end

function CityLegoBuildingTile:GetNotMovableReason()
    local legoBuilding = self:GetCell()
    return legoBuilding:GetNotMovableReason()
end

return CityLegoBuildingTile