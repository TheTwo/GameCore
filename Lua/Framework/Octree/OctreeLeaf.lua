---@class OctreeLeaf
---@field new fun():OctreeLeaf
---@field bounds Bounds
local OctreeLeaf = sealedClass("OctreeLeaf")

function OctreeLeaf:ctor(bounds, value)
    self.bounds = bounds
    self.value = value
end

return OctreeLeaf