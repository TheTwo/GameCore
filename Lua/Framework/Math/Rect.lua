---@class Rect
---@field new fun(x, y, sizeX, sizeY):Rect
local Rect = class("Rect")

function Rect:ctor(x, y, sizeX, sizeY)
    self.x = x
    self.y = y
    self.sizeX = sizeX
    self.sizeY = sizeY
end

function Rect:Center()
    return self.x + self.sizeX / 2, self.y + self.sizeY / 2
end

---@param rect Rect
function Rect:Intersect(rect)
    local cx, cy = self:Center()
    local tcx, tcy = rect:Center()

    local offsetx = math.abs(cx - tcx)
    local offsety = math.abs(cy - tcy)

    return offsetx < (self.sizeX + rect.sizeX) / 2 and offsety < (self.sizeY + rect.sizeY) / 2
end

---@param rect Rect
function Rect:Contains(rect)
    -- 比对方小必不能包含对方
    if self.sizeX < rect.sizeX or self.sizeY < rect.sizeY then
        return false
    end

    local cx, cy = self:Center()
    local tcx, tcy = rect:Center()

    local offsetx = math.abs(cx - tcx)
    local offsety = math.abs(cy - tcy)

    local dx = self.sizeX - rect.sizeX
    local dy = self.sizeY - rect.sizeY

    return offsetx <= dx / 2 and offsety <= dy / 2
end

---@param rect Rect
function Rect:Equals(rect)
    return self.x == rect.x and self.y == rect.y and self.sizeX == rect.sizeX and self.sizeY == rect.sizeY
end

---@param base Rect
---@return Rect[]
function Rect:Difference(base)
    if not self:Intersect(base) then
        return {self}
    end
    
    local ret = {}
    if self.y < base.y then
        table.insert(ret, Rect.new(self.x, self.y, self.sizeX, base.y - self.y))
    end
    if self.y + self.sizeY > base.y + base.sizeY then
        table.insert(ret, Rect.new(self.x, base.y + base.sizeY, self.sizeX, self.y + self.sizeY - base.y - base.sizeY))
    end
    if self.x < base.x then
        table.insert(ret, Rect.new(self.x, math.max(self.y, base.y), base.x - self.x, math.min(self.sizeY, base.y + base.sizeY - self.y)))
    end
    if self.x + self.sizeX > base.x + base.sizeX then
        table.insert(ret, Rect.new(base.x + base.sizeX, math.max(self.y, base.y), self.x + self.sizeX - base.x - base.sizeX, math.min(self.sizeY, base.y + base.sizeY - self.y)))
    end
    return ret
end

return Rect