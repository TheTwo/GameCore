---@class AABB
---@field new fun():AABB
local AABB = sealedClass("AABB", nil, true);

function AABB:ctor(x, y, sizeX, sizeY)
    self.posX = x;
    self.posY = y;
    self.sizeX = sizeX;
    self.sizeY = sizeY;
end

---@param aabb AABB
---@return boolean 是否真包含aabb
function AABB:Contains(aabb)
    return self.posX <= aabb.posX and self.posY <= aabb.posY and
        self.posX + self.sizeX >= aabb.posX + aabb.sizeX and
        self.posY + self.sizeY >= aabb.posY + aabb.sizeY;
end

---@param aabb AABB
---@return boolean 是否相交(相切时返回false)
function AABB:Intersect(aabb)
    local dx = math.max(math.abs(self.posX + self.sizeX - aabb.posX), math.abs(aabb.posX + aabb.sizeX - self.posX));
    local dy = math.max(math.abs(self.posY + self.sizeY - aabb.posY), math.abs(aabb.posY + aabb.sizeY - self.posY));
    return dx < self.sizeX + aabb.sizeX and dy < self.sizeY + aabb.sizeY;
end

return AABB