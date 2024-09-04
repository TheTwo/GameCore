local CityLegoBlock = require("CityLegoBlock")
---@class CityLegoRoof:CityLegoBlock
---@field new fun():CityLegoRoof
local CityLegoRoof = class("CityLegoRoof", CityLegoBlock)
local PrefabCustomInfoHolder = CS.PrefabCustomInfoHolder
local BottomCode = PrefabCustomInfoHolder.BOTTOM
local LeftCode = PrefabCustomInfoHolder.LEFT
local TopCode = PrefabCustomInfoHolder.TOP
local RightCode = PrefabCustomInfoHolder.RIGHT
local DirX = { [BottomCode] = 0, [LeftCode] = -1, [TopCode] = 0, [RightCode] = 1 }
local DirZ = { [BottomCode] = -1, [LeftCode] = 0, [TopCode] = 1, [RightCode] = 0 }

---@param legoBuilding CityLegoBuilding
---@param payload LegoBlockInstanceConfigCell
function CityLegoRoof:ctor(legoBuilding, payload)
    CityLegoBlock.ctor(self, legoBuilding, payload)

    if (self.x % 1 ~= 0) or (self.z % 1 ~= 0) then
        g_Logger.ErrorChannel("CityLegoRoof", "[BlockInstance:%d] 配置偏移非整数", payload:Id())
    end
end

function CityLegoRoof:UpdatePosition()
    CityLegoBlock.UpdatePosition(self)

    if self.payload and ((self.x % 1 ~= 0) or (self.z % 1 ~= 0)) then
        g_Logger.ErrorChannel("CityLegoRoof", "[BlockInstance:%d] 配置偏移非整数", self.payload:Id())
    end
end

function CityLegoRoof:GetNeighborMask()
    local hasTopNeighbor = self.legoBuilding:HasRoofNeighborAt(self.x, self.z, self:GetTopDir())
    local hasBottomNeighbor = self.legoBuilding:HasRoofNeighborAt(self.x, self.z, self:GetBottomDir())
    local hasLeftNeighbor = self.legoBuilding:HasRoofNeighborAt(self.x, self.z, self:GetLeftDir())
    local hasRightNeighbor = self.legoBuilding:HasRoofNeighborAt(self.x, self.z, self:GetRightDir())

    local maskValue = 0
    if hasTopNeighbor then
        maskValue = maskValue | (1 << TopCode)
    end
    if hasBottomNeighbor then
        maskValue = maskValue | (1 << BottomCode)
    end
    if hasLeftNeighbor then
        maskValue = maskValue | (1 << LeftCode)
    end
    if hasRightNeighbor then
        maskValue = maskValue | (1 << RightCode)
    end
    return maskValue
end

function CityLegoRoof:Epsilon(value)
    if math.abs(value) < 0.0001 then
        return 0
    end
    return value
end

---@private
function CityLegoRoof:GetNeighborDir(code)
    local basicDirX, basicDirZ = DirX[code], DirZ[code]
    local dirX = math.cos(math.rad(-self.axisYRot)) * basicDirX - math.sin(math.rad(-self.axisYRot)) * basicDirZ
    local dirZ = math.sin(math.rad(-self.axisYRot)) * basicDirX + math.cos(math.rad(-self.axisYRot)) * basicDirZ
    return self:Epsilon(dirX), self:Epsilon(dirZ)
end

---@private
function CityLegoRoof:GetTopDir()
    return self:GetNeighborDir(TopCode)
end

---@private
function CityLegoRoof:GetBottomDir()
    return self:GetNeighborDir(BottomCode)
end

---@private
function CityLegoRoof:GetLeftDir()
    return self:GetNeighborDir(LeftCode)
end

---@private
function CityLegoRoof:GetRightDir()
    return self:GetNeighborDir(RightCode)
end

return CityLegoRoof