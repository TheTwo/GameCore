---@class Bounds
---@field new fun():Bounds
local Bounds = sealedClass("Bounds")

function Bounds:ctor(x, y, z, sizeX, sizeY, sizeZ)
    self.x = x
    self.y = y
    self.z = z
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.sizeZ = sizeZ
end

function Bounds:Center()
    return self.x + self.sizeX / 2, self.y + self.sizeY / 2, self.z + self.sizeZ / 2
end

---@param bounds Bounds
function Bounds:Intersect(bounds)
    local cx, cy, cz = self:Center()
    local tcx, tcy, tcz = bounds:Center()

    local offsetx = math.abs(cx - tcx)
    local offsety = math.abs(cy - tcy)
    local offsetz = math.abs(cz - tcz)

    return offsetx < (self.sizeX + bounds.sizeX) / 2 and offsety < (self.sizeY + bounds.sizeY) / 2 and offsetz < (self.sizeZ + bounds.sizeZ) / 2
end

---@param bounds Bounds
function Bounds:Contains(bounds)
    -- 比对方小必不能包含对方
    if self.sizeX < bounds.sizeX or self.sizeY < bounds.sizeY or self.sizeZ < bounds.sizeZ then
        return false
    end

    local cx, cy, cz = self:Center()
    local tcx, tcy, tcz = bounds:Center()

    local offsetx = math.abs(cx - tcx)
    local offsety = math.abs(cy - tcy)
    local offsetz = math.abs(cz - tcz)

    local dx = self.sizeX - bounds.sizeX
    local dy = self.sizeY - bounds.sizeY
    local dz = self.sizeZ - bounds.sizeZ

    return offsetx <= dx / 2 and offsety <= dy / 2 and offsetz <= dz / 2
end

---@param bounds Bounds
function Bounds:Equals(bounds)
    return self.x == bounds.x and self.y == bounds.y and self.z == bounds.z and self.sizeX == bounds.sizeX and self.sizeY == bounds.sizeY and self.sizeZ == bounds.sizeZ
end

---@param bounds Bounds
function Bounds:Merge(bounds)
    local x = math.min(self.x, bounds.x)
    local y = math.min(self.y, bounds.y)
    local z = math.min(self.z, bounds.z)
    local sizeX = math.max(self.x + self.sizeX, bounds.x + bounds.sizeX) - x
    local sizeY = math.max(self.y + self.sizeY, bounds.y + bounds.sizeY) - y
    local sizeZ = math.max(self.z + self.sizeZ, bounds.z + bounds.sizeZ) - z
    return Bounds.new(x, y, z, sizeX, sizeY, sizeZ)
end

return Bounds