---@class CityStateTileHandleLegoTileData
---@field new fun():CityStateTileHandleLegoTileData
local CityStateTileHandleLegoTileData = class("CityStateTileHandleLegoTileData")
local LegoTileSelectorDataWrap = require("LegoTileSelectorDataWrap")
local CityConst = require("CityConst")

---@param legoTile CityLegoBuildingTile
function CityStateTileHandleLegoTileData:ctor(legoTile)
    self.legoTile = legoTile
    self.legoBuilding = legoTile:GetCell()
    self.city = self.legoTile:GetCity()
    self.x, self.y = self.legoBuilding.x, self.legoBuilding.z
    self.sizeX, self.sizeY = self.legoBuilding.sizeX, self.legoBuilding.sizeZ
    self.RiseOffset = CityConst.RiseOffset
end

function CityStateTileHandleLegoTileData:OnHandleInitialize()
    
end

function CityStateTileHandleLegoTileData:OnHandleRelease()
    
end

function CityStateTileHandleLegoTileData:GetSelectorDataWrap()
    return LegoTileSelectorDataWrap.new(self.x, self.y, self.sizeX, self.sizeY, self.legoBuilding)
end

function CityStateTileHandleLegoTileData:UpdatePosition(x, y, easeYAxis)
    self.x, self.y = x, y
    if easeYAxis then
        self.legoTile:UpdatePosition(self.city:GetWorldPositionFromCoord(x, y))
        self.legoTile:MoveEase(self.RiseOffset)
    else
        self.legoTile:UpdatePosition(self.city:GetWorldPositionFromCoord(x, y) + self.RiseOffset)
    end
end

function CityStateTileHandleLegoTileData:ForceShowTile()
    self.city.gridView:ForceShow(self.legoTile)
end

function CityStateTileHandleLegoTileData:CancelForceShowTile()
    self.city.gridView:CancelForceShow(self.legoTile)
end

function CityStateTileHandleLegoTileData:SquareCheck(x, y, sizeX, sizeY)
    return self.city:IsSquareValidForBuilding(x, y, sizeX, sizeY)
end

function CityStateTileHandleLegoTileData:FixCoord(x, y, sizeX, sizeY)
    return self.city:GetFixCoord(x, y, sizeX, sizeY)
end

function CityStateTileHandleLegoTileData:Rotate(anticlockwise)
    ---NOTE: DO NOTHING
end

function CityStateTileHandleLegoTileData:NotChanged()
    return self.x == self.legoBuilding.x and self.y == self.legoBuilding.z
end

function CityStateTileHandleLegoTileData:IsPressOnModel(screenPos)
    return false
end

function CityStateTileHandleLegoTileData:TileHandleType()
    return CityConst.TileHandleType.LegoBuilding
end

return CityStateTileHandleLegoTileData