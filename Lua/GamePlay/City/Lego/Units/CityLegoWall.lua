---@class CityLegoWall
---@field new fun(legoBuilding, payload):CityLegoWall
local CityLegoWall = class("CityLegoWall")
local WallSide = require("WallSide")
local CityLegoDefine = require("CityLegoDefine")
local CityLegoAttachedDecoration = require("CityLegoAttachedDecoration")
local ConfigRefer = require("ConfigRefer")
local LegoBlockType = require("LegoBlockType")
local Quaternion = CS.UnityEngine.Quaternion
local NeighborOffsetX = { [WallSide.Bottom] = 0, [WallSide.Top] = 0, [WallSide.Left] = -CityLegoDefine.BlockSize, [WallSide.Right] = CityLegoDefine.BlockSize}
local NeighborOffsetZ = { [WallSide.Bottom] = -CityLegoDefine.BlockSize, [WallSide.Top] = CityLegoDefine.BlockSize, [WallSide.Left] = 0, [WallSide.Right] = 0}
local NeighborCornerOffsetX = { [WallSide.Bottom] = -CityLegoDefine.BlockSize, [WallSide.Top] = CityLegoDefine.BlockSize, [WallSide.Left] = -CityLegoDefine.BlockSize, [WallSide.Right] = CityLegoDefine.BlockSize}
local NeighborCornerOffsetZ = { [WallSide.Bottom] = -CityLegoDefine.BlockSize, [WallSide.Top] = CityLegoDefine.BlockSize, [WallSide.Left] = CityLegoDefine.BlockSize, [WallSide.Right] = -CityLegoDefine.BlockSize}

---@param legoBuilding CityLegoBuilding
---@param payload LegoBlockInstanceConfigCell
function CityLegoWall:ctor(legoBuilding, payload)
    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.manager.city
    self:UpdatePayload(payload)
end

---@param payload LegoBlockInstanceConfigCell
function CityLegoWall:UpdatePayload(payload)
    local coord = payload:RelPos()
    self.floorX = coord:X() + self.legoBuilding.x
    self.floorY = coord:Y()
    self.floorZ = coord:Z() + self.legoBuilding.z

    if (self.floorX % 1 ~= 0) or (self.floorZ % 1 ~= 0) then
        g_Logger.ErrorChannel("CityLegoWall", "[BlockInstance:%d] 配置偏移非整数", payload:Id())
    end

    self.side = payload:SideOfWall()
    self.payload = payload
    self.hashCode = CityLegoDefine.GetWallHashCode(self.floorX, self.floorY, self.floorZ, self.side)
    self.axisYRot = CityLegoWall.GetAngleFromSide(self.side)
    self.filter = nil
    self.isDoor = self:IsDoor()
    self.indoorDecorations = nil
    self.outsideDecorations = nil
end

function CityLegoWall:UpdatePosition()
    if not self.payload then return end

    local coord = self.payload:RelPos()
    self.floorX = coord:X() + self.legoBuilding.x
    self.floorY = coord:Y()
    self.floorZ = coord:Z() + self.legoBuilding.z

    if (self.floorX % 1 ~= 0) or (self.floorZ % 1 ~= 0) then
        g_Logger.ErrorChannel("CityLegoWall", "[BlockInstance:%d] 配置偏移非整数", self.payload:Id())
    end

    self.hashCode = CityLegoDefine.GetWallHashCode(self.floorX, self.floorY, self.floorZ, self.side)
end

function CityLegoWall:GetWorldRotation()
    return Quaternion.Euler(0, self.axisYRot, 0)
end

function CityLegoWall.GetAngleFromSide(side)
    if side == WallSide.Bottom then
        return 0
    elseif side == WallSide.Left then
        return 90
    elseif side == WallSide.Top then
        return 180
    elseif side == WallSide.Right then
        return 270
    end
    return 0
end

function CityLegoWall:GetCfgId()
    return self.payload:Type()
end

function CityLegoWall:IsDoor()
    local blockCfg = ConfigRefer.LegoBlock:Find(self:GetCfgId())
    return blockCfg:Type() == LegoBlockType.Door
end

function CityLegoWall:GetRange()
    if self.side == WallSide.Left then
        return self.floorX - 0.5 * CityLegoDefine.BlockSize, self.floorZ, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize
    end
    if self.side == WallSide.Right then
        return self.floorX + 0.5 * CityLegoDefine.BlockSize, self.floorZ, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize
    end
    if self.side == WallSide.Bottom then
        return self.floorX, self.floorZ - 0.5 * CityLegoDefine.BlockSize, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize
    end
    if self.side == WallSide.Top then
        return self.floorX, self.floorZ + 0.5 * CityLegoDefine.BlockSize, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize
    end
    return self.floorX, self.floorZ, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize
end

function CityLegoWall:IsFront()
    return self.side == WallSide.Bottom or self.side == WallSide.Left
end

function CityLegoWall:GetWorldPosition()
    return self.city:GetCenterWorldPositionFromCoord(self.floorX, self.floorZ, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize)
end

function CityLegoWall:GetDecorations(indoor)
    local filter = self:GetAttachPointFilter()
    if indoor then
        return self:GetIndoorDecorations(filter)
    else
        return self:GetOutsideDecorations(filter)
    end
end

function CityLegoWall:HasIndoorPart()
    return self.payload:StyleIndoor() > 0
end

function CityLegoWall:HasOutsidePart()
    return self.payload:StyleOutside() > 0
end

function CityLegoWall:GetStyle(indoor)
    if indoor then
        return self.payload:StyleIndoor()
    else
        return self.payload:StyleOutside()
    end
end

---@private
function CityLegoWall:GetAttachPointFilter()
    if self.filter == nil then
        local blockCfg = ConfigRefer.LegoBlock:Find(self:GetCfgId())
        self.filter = {}
        for i = 1, blockCfg:AttachPointLength() do
            local attachPointCfgId = blockCfg:AttachPoint(i)
            local attachPointCfg = ConfigRefer.LegoBlockAttachPoint:Find(attachPointCfgId)
            if attachPointCfg then
                self.filter[attachPointCfg:Name()] = attachPointCfg:Outside()
            end
        end
    end
    return self.filter
end

---@private
function CityLegoWall:GetIndoorDecorations(filter)
    if self.indoorDecorations == nil then
        ---@type CityLegoAttachedDecoration[]
        self.indoorDecorations = {}
        for i = 1, self.payload:DecorationsLength() do
            local decorationCfg = self.payload:Decorations(i)
            local name = decorationCfg:AttachPoint()
            if not string.IsNullOrEmpty(name) and filter[name] == false then
                local decoration = CityLegoAttachedDecoration.new(self.legoBuilding, decorationCfg, self:GetCfgId())
                table.insert(self.indoorDecorations, decoration)
            end
        end
    end
    return self.indoorDecorations
end

---@private
function CityLegoWall:GetOutsideDecorations(filter)
    if self.outsideDecorations == nil then
        ---@type CityLegoAttachedDecoration[]
        self.outsideDecorations = {}
        for i = 1, self.payload:DecorationsLength() do
            local decorationCfg = self.payload:Decorations(i)
            local name = decorationCfg:AttachPoint()
            if not string.IsNullOrEmpty(name) and filter[name] == true then
                local decoration = CityLegoAttachedDecoration.new(self.legoBuilding, decorationCfg, self:GetCfgId())
                table.insert(self.outsideDecorations, decoration)
            end
        end
    end
    return self.outsideDecorations
end

function CityLegoWall:HasClockwiseCorner()
    local sameBaseWall = self.legoBuilding:GetWallsAtExceptSide(self.floorX, self.floorY, self.floorZ, self.side)
    if #sameBaseWall == 0 then
        return false
    end

    for i, v in ipairs(sameBaseWall) do
        if v.side == (self.side + 1) % 4 then
            return true
        end
    end

    return false
end

function CityLegoWall:HasAnticlockwiseCorner()
    local sameBaseWall = self.legoBuilding:GetWallsAtExceptSide(self.floorX, self.floorY, self.floorZ, self.side)
    if #sameBaseWall == 0 then
        return false
    end

    for i, v in ipairs(sameBaseWall) do
        if v.side == (self.side - 1) % 4 then
            return true
        end
    end

    return false
end

function CityLegoWall:HasAnticlockwiseNeighbourCorner()
    local offsetX = NeighborOffsetX[self.side]
    local offsetZ = NeighborOffsetZ[self.side]

    local base = self.legoBuilding:GetBaseAt(self.floorX + offsetX, self.floorY, self.floorZ + offsetZ)
    if base ~= nil then
        return false
    end

    local neighborX = self.floorX + NeighborCornerOffsetX[self.side]
    local neighborZ = self.floorZ + NeighborCornerOffsetZ[self.side]
    local sameBaseWall = self.legoBuilding:GetWallsAtExceptSide(neighborX, self.floorY, neighborZ, self.side)
    if #sameBaseWall == 0 then
        return false
    end

    for i, v in ipairs(sameBaseWall) do
        if v.side == (self.side - 1) % 4 then
            return true
        end
    end

    return false
end

return CityLegoWall