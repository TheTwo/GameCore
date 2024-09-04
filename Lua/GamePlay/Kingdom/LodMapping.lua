local KingdomConstant = require("KingdomConstant")

---@class LodMapping
local LodMapping = class("LodMapping")

local LodMin = wds.enum.PlayerLod.PlayerLod1
local LodMax = wds.enum.PlayerLod.PlayerLod7

LodMapping.mapping =
{
    [1] = 1,
    [2] = 2,
    [3] = 2,
    [4] = 3,
    [5] = 4,
    [6] = 5,
    [7] = 6,
    [8] = 7,
}

function LodMapping.ParseLod(lod)
    lod = LodMapping.mapping[lod]
    lod = math.clamp(lod, LodMin, LodMax)
    return lod
end

return LodMapping