

---@class CitySafeAreaWallDoor:CityCellBase
---@field new fun(id:number, centerGridX:number, centerGridY:number, dir:number, isDoor:boolean, gridMap:RectDyadicMap):CitySafeAreaWallDoor
local CitySafeAreaWallDoor = class('CitySafeAreaWallDoor')

---@param id number
---@param centerGridX number
---@param centerGridY number
---@param dir number
---@param isDoor boolean
---@param gridMap RectDyadicMap
function CitySafeAreaWallDoor:ctor(id, centerGridX, centerGridY, dir, isDoor, gridMap)
    self.singleId = id
    self.isDoor = isDoor
    self.centerGridX = centerGridX
    self.centerGridY = centerGridY
    local firstPosX, firstPosY = gridMap:First()
    self.x = firstPosX
    self.y = firstPosY
    self.sizeX = 1
    self.sizeY = 1
    self.dir = dir
    self.gridMap = gridMap
    self.rangeMinX = 512
    self.rangeMinY = 512
    self.rangeMaxX = 0
    self.rangeMaxY = 0
    for x,y,_ in gridMap:pairs() do
        if x > self.rangeMaxX then
            self.rangeMaxX = x
        end
        if x < self.rangeMinX then
            self.rangeMinX = x
        end
        if y > self.rangeMaxY then
            self.rangeMaxY = y
        end
        if y < self.rangeMinY then
            self.rangeMinY = y
        end
    end
end

function CitySafeAreaWallDoor:UniqueId()
    return self.singleId
end

function CitySafeAreaWallDoor:ConfigId()
    return self.singleId
end

function CitySafeAreaWallDoor:GetUnitArea()
    if self.dir == 3 then
        return self.rangeMinX - 0.5, self.rangeMinY - 3, 1 + self.rangeMaxX - self.rangeMinX + 1, 1 + self.rangeMaxY - self.rangeMinY + 6
    elseif self.dir == 12 then
        return self.rangeMinX - 3, self.rangeMinY - 0.5, 1 + self.rangeMaxX - self.rangeMinX + 6, 1 + self.rangeMaxY - self.rangeMinY + 1
    end
end

function CitySafeAreaWallDoor:IsSafeAreaDoor()
    return self.isDoor
end

function CitySafeAreaWallDoor:IsSafeAreaWall()
    return not self.isDoor
end

return CitySafeAreaWallDoor