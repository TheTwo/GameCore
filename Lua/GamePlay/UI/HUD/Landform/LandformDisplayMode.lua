---@class LandformDisplayMode
local LandformDisplayMode = {
    Hide = 0,
    Strategy = 1 << 0,
    Landform = 1 << 1,

    Both = 1 << 0 | 1 << 1,
}

return LandformDisplayMode