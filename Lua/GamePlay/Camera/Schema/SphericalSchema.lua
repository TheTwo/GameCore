---@class Spherical
---@field radius number 半径
---@field azimuth number 经度
---@field altitude number 纬度

local SphericalSchema = {
    {"radius", typeof(CS.System.Double)},
    {"azimuth", typeof(CS.System.Double)},
    {"altitude", typeof(CS.System.Double)},
}

return SphericalSchema