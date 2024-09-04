local CityStateTileHandleDataWrap = require("CityStateTileHandleDataWrap")
---@class CityStateTileHandleFurnitureTileData:CityStateTileHandleDataWrap
---@field new fun():CityStateTileHandleFurnitureTileData
local CityStateTileHandleFurnitureTileData = class("CityStateTileHandleFurnitureTileData", CityStateTileHandleDataWrap)
local FurnitureTileSelectorDataWrap = require("FurnitureTileSelectorDataWrap")
local CityConst = require("CityConst")

---@param furnitureTile CityFurnitureTile
function CityStateTileHandleFurnitureTileData:ctor(furnitureTile, legoBuilding)
    self.furnitureTile = furnitureTile
    CityStateTileHandleDataWrap.ctor(self, self.furnitureTile:GetCity(), self.furnitureTile.x, self.furnitureTile.y, self.furnitureTile:SizeX(), self.furnitureTile:SizeY(), self.furnitureTile:GetCell().direction, legoBuilding, furnitureTile:GetDirSet())
end

function CityStateTileHandleFurnitureTileData:GetSelectorDataWrap()
    return FurnitureTileSelectorDataWrap.new(self.furnitureTile, self.legoBuilding)
end

function CityStateTileHandleFurnitureTileData:UpdatePosition(x, y, easeYAxis)
    CityStateTileHandleDataWrap.UpdatePosition(self, x, y, easeYAxis)
    if easeYAxis then
        self.furnitureTile:UpdatePosition(self.city:GetWorldPositionFromCoord(x, y))
        self.furnitureTile:MoveEase(self.RiseOffset)
    else
        self.furnitureTile:UpdatePosition(self.city:GetWorldPositionFromCoord(x, y) + self.RiseOffset)
    end
end

function CityStateTileHandleFurnitureTileData:ForceShowTile()
    self.city.gridView:ForceShow(self.furnitureTile)
end

function CityStateTileHandleFurnitureTileData:CancelForceShowTile()
    self.city.gridView:CancelForceShow(self.furnitureTile)
end

function CityStateTileHandleFurnitureTileData:Rotate(anticlockwise)
    CityStateTileHandleDataWrap.Rotate(self, anticlockwise)
    local position = self.city:GetWorldPositionFromCoord(self.x, self.y) + self.RiseOffset
    local centerPos = self.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY) + self.RiseOffset
    local rotation = CityConst.Quaternion[self.direction]
    self.furnitureTile:SetPositionCenterAndRotation(position, centerPos, rotation)
end

function CityStateTileHandleFurnitureTileData:NotChanged()
    return self.furnitureTile.x == self.x and self.furnitureTile.y == self.y and (self.furnitureTile:GetCell().direction or 0) == self.direction
end

function CityStateTileHandleFurnitureTileData:IsPressOnModel(screenPos)
    local flag, trigger = self.city.mediator:RaycastAny(screenPos)
    if not flag then
        return false
    end

    if trigger:IsUIBubble() then
        return false
    end

    local tile = trigger:GetTile()
    return tile == self.furnitureTile
end

function CityStateTileHandleFurnitureTileData:TileHandleType()
    return CityConst.TileHandleType.Furniture
end

function CityStateTileHandleFurnitureTileData:FurnitureLevelCfgId()
    return self.furnitureTile:GetCell().configId
end

function CityStateTileHandleFurnitureTileData:OriginBuildingId()
    return self.furnitureTile:GetCastleFurniture().BuildingId
end

return CityStateTileHandleFurnitureTileData