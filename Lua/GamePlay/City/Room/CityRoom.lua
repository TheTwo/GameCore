---@class CityRoom
---@field new fun(roomInfo:wds.BuildingRoom, building:CityBuilding):CityRoom
---@field areas RectDyadicMap 房间占地
---@field relativeWall table<CityWall, number> @value表示其关联的墙面枚举,一面墙有两面,房间大部分墙面只关联其一面
---@field connections table<CityRoom, CityRoom> 相连的房间
---@field reachable boolean 是否可达
local CityRoom = class("CityRoom")
local RectDyadicMap = require("RectDyadicMap")
local CityWallSide = require("CityWallSide")

---@param roomInfo wds.BuildingRoom
---@param building CityBuilding
function CityRoom:ctor(id, roomInfo, building)
    self.id = id
    self.roomInfo = roomInfo
    self.building = building
    self.city = self.building.mgr.city
    local gridConfig = self.city.gridConfig
    self.areas = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY)
    self.relativeWall = {}
    self.connections = {}
    self.reachable = false
end

function CityRoom:CollectTileBelongsSelf()
    self.areas:Clear()
    
    local wallInfo = self.building:GetRoomInfo()
    if wallInfo == nil then return end

    local minX, minY = wallInfo.X, wallInfo.Y
    local maxX, maxY = wallInfo.X + wallInfo.Width - 1, wallInfo.Y + wallInfo.Height - 1

    local first = {x = self.roomInfo.X, y = self.roomInfo.Y}
    ---@type {x:number, y:number}[]
    local open = {first}
    local close = self.areas
    close:Add(first.x, first.y, first)
    while #open > 0 do
        local node = table.remove(open, 1)
        ---上
        if node.y + 1 <= maxY and close:Get(node.x, node.y + 1) == nil then
            if not self.building:HasInnerHWallOrDoor(node.y + 1, node.x) then
                local neighbour = {x = node.x, y = node.y + 1}
                table.insert(open, neighbour)
                close:Add(neighbour.x, neighbour.y, neighbour)
            end
        end

        ---下
        if node.y - 1 >= minY and close:Get(node.x, node.y - 1) == nil then
            if not self.building:HasInnerHWallOrDoor(node.y, node.x) then
                local neighbour = {x = node.x, y = node.y - 1}
                table.insert(open, neighbour)
                close:Add(neighbour.x, neighbour.y, neighbour)
            end
        end

        ---左
        if node.x - 1 >= minX and close:Get(node.x - 1, node.y) == nil then
            if not self.building:HasInnerVWallOrDoor(node.x, node.y) then
                local neighbour = {x = node.x - 1, y = node.y}
                table.insert(open, neighbour)
                close:Add(neighbour.x, neighbour.y, neighbour)
            end
        end

        ---右
        if node.x + 1 <= maxX and close:Get(node.x + 1, node.y) == nil then
            if not self.building:HasInnerVWallOrDoor(node.x + 1, node.y) then
                local neighbour = {x = node.x + 1, y = node.y}
                table.insert(open, neighbour)
                close:Add(neighbour.x, neighbour.y, neighbour)
            end
        end
    end
end

function CityRoom:CollectRelativeWalls()
    table.clear(self.relativeWall)
    
    local x, y, _ = self.areas:First()
    if not x or not y then return end

    ---用洪泛检索房间关联到的墙壁
    ---@type {x:number,y:number}[]
    local open = {{x = x, y = y}}
    local gridConfig = self.city.gridConfig
    local close = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY)

    while #open > 0 do
        local curNode = table.remove(open)
        local nx, ny = curNode.x, curNode.y
        if self.areas:Get(nx, ny) == self then
            ---上
            ---相邻坐标需属于当前房间且没有被遍历过
            if self.areas:Get(nx, ny + 1) == self and not close:Get(nx, ny + 1) then
                table.insert(open, {x = nx, y = ny + 1})
            end
            ---无论相邻坐标是否被遍历过，都需要再检查一次关联墙体，同一面墙的两侧需分别记录
            if self.building:HasInnerHWallOrDoor(ny+1, nx) then
                self:AddRelativeWall(self.building:GetInnerHWallOrDoor(ny+1, nx) , CityWallSide.Bottom)
            end

            ---下
            if self.areas:Get(nx, ny - 1) == self and not close:Get(nx, ny - 1) then
                table.insert(open, {x = nx, y = ny - 1})
            end
            if self.building:HasInnerHWallOrDoor(ny, nx) then
                self:AddRelativeWall(self.building:GetInnerHWallOrDoor(ny, nx), CityWallSide.Top)
            end

            ---左
            if self.areas:Get(nx - 1, ny) == self and not close:Get(nx - 1, ny) then
                table.insert(open, {x = nx - 1, y = ny})
            end
            if self.building:HasInnerVWallOrDoor(nx, ny) then
                self:AddRelativeWall(self.building:GetInnerVWallOrDoor(nx, ny), CityWallSide.Right)
            end

            ---右
            if self.areas:Get(nx + 1, ny) == self and not close:Get(nx + 1, ny) then
                table.insert(open, {x = nx + 1, y = ny})
            end
            if self.building:HasInnerVWallOrDoor(nx + 1, ny) then
                self:AddRelativeWall(self.building:GetInnerVWallOrDoor(nx + 1, ny), CityWallSide.Left)
            end
        end
        close:Add(curNode.x, curNode.y, curNode)
        ::continue::
    end
end

function CityRoom:ContainsTile(x, y)
    return self.areas:Get(x, y) ~= nil
end

function CityRoom:AddRelativeWall(wall, side)
    if not self.relativeWall then
        self.relativeWall[wall] = 0
    end
    self.relativeWall[wall] = self.relativeWall[wall] | side
end

function CityRoom:RemoveRelativeWall(wall)
    if wall == nil then return end
    self.relativeWall[wall] = nil
end

function CityRoom:ClearConnectionAndReachable()
    table.clear(self.connections)
    self.reachable = false
end

function CityRoom:ConnectRoom(otherRoom)
    self.connections[otherRoom] = otherRoom
end

function CityRoom:SetPreviewFloorId(id)
    self.previewId = id
end

function CityRoom:GetFloorId()
    if self.previewId then
        return self.previewId
    end
    return self.roomInfo.Floor
end

function CityRoom:WorldCenter()
    local x, y = 0, 0
    local count = 0
    for i, j, _ in self.areas:pairs() do
        x = x + i
        y = y + j
        count = count + 1
    end

    if count > 0 then
        x = x / count
        y = y / count
    end

    x = x + self.building.x
    y = y + self.building.y
    return self.city:GetWorldPositionFromCoord(x, y)
end

return CityRoom