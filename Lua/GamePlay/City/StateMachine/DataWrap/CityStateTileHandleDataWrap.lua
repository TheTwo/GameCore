---@class CityStateTileHandleDataWrap
---@field new fun():CityStateTileHandleDataWrap
local CityStateTileHandleDataWrap = class("CityStateTileHandleDataWrap")
local SelectorDataWrap = require("SelectorDataWrap")
local CityConst = require("CityConst")

---@param city City
---@param legoBuilding CityLegoBuilding
function CityStateTileHandleDataWrap:ctor(city, x, y, sizeX, sizeY, direction, legoBuilding, dirSet)
    self.city = city
    self.x, self.y = x, y
    self.sizeX, self.sizeY = sizeX, sizeY
    self.direction = direction

    self.RiseOffset = CityConst.RiseOffset
    self.legoBuilding = legoBuilding

    if not dirSet or #dirSet == 0 then
        g_Logger.Error("SelectorDataWrap:ctor dirSet is nil or empty!")
        return
    end
    
    self.dirSet = dirSet
    self.dirIndex = 1
    for i, v in ipairs(self.dirSet) do
        if v == self.direction then
            self.dirIndex = i
            break
        end
    end
end

---@param handle CityStateTileHandle
function CityStateTileHandleDataWrap:OnHandleInitialize(handle)
    
end

---@param handle CityStateTileHandle
function CityStateTileHandleDataWrap:OnHandleRelease(handle)
    
end

function CityStateTileHandleDataWrap:GetSelectorDataWrap()
    return SelectorDataWrap.new(self.x, self.y, self.sizeX, self.sizeY, self.direction, self.legoBuilding, self.dirSet)
end

function CityStateTileHandleDataWrap:UpdatePosition(x, y, easeYAxis)
    self.x, self.y = x, y
end

function CityStateTileHandleDataWrap:ForceShowTile()
    ---DO NOTHING
end

function CityStateTileHandleDataWrap:CancelForceShowTile()
    ---DO NOTHING
end

function CityStateTileHandleDataWrap:SquareCheck(x, y, sizeX, sizeY)
    if self.legoBuilding then
        for i = x, x + sizeX - 1 do
            for j = y, y + sizeY - 1 do
                if not self.legoBuilding.floorPosMap:Contains(i, j) then
                    return false
                end
            end
        end
    end
    return self.city:IsSquareValidForFurniture(x, y, sizeX, sizeY)
end

function CityStateTileHandleDataWrap:FixCoord(x, y, sizeX, sizeY)
    return self.city:GetFixCoord(x, y, sizeX, sizeY)
end

function CityStateTileHandleDataWrap:Rotate(anticlockwise)
    if self.dirIndex == nil then
        if anticlockwise then
            self.direction = (self.direction - 90) % 360
        else
            self.direction = (self.direction + 90) % 360
        end
    else
        if anticlockwise then
            self.dirIndex = self.dirIndex - 1
            if self.dirIndex < 1 then
                self.dirIndex = #self.dirSet
            end
        else
            self.dirIndex = self.dirIndex + 1
            if self.dirIndex > #self.dirSet then
                self.dirIndex = 1
            end
        end
        self.direction = self.dirSet[self.dirIndex]
    end

    ---长宽不等时需要调整 x, y, sizeX, sizeY
    if self.sizeX ~= self.sizeY then
        local offsetX = self.sizeX / 2 - self.sizeY / 2
        local offsetY = self.sizeY / 2 - self.sizeX / 2
        self.x = math.floor(math.abs(offsetX)) * math.sign(offsetX) + self.x
        self.y = math.floor(math.abs(offsetY)) * math.sign(offsetY) + self.y

        self.sizeX, self.sizeY = self.sizeY, self.sizeX
    end
end

function CityStateTileHandleDataWrap:NotChanged()
    return false
end

---@param screenPos CS.UnityEngine.Vector3
function CityStateTileHandleDataWrap:IsPressOnModel(screenPos)
    return false
end

function CityStateTileHandleDataWrap:TileHandleType()
    return CityConst.TileHandleType.None
end

function CityStateTileHandleDataWrap:OriginBuildingId()
    return 0
end

return CityStateTileHandleDataWrap