---@class QuadTreeLeaf
---@field new fun(rect, value):QuadTreeLeaf
---@field rect Rect
local QuadTreeLeaf = sealedClass("QuadTreeLeaf")

---@param rect Rect
---@param value any
function QuadTreeLeaf:ctor(rect, value)
    self.rect = rect
    self.value = value
end

return QuadTreeLeaf