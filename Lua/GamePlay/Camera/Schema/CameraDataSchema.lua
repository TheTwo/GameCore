---@class CameraData
---@field minSize number
---@field maxSize number
---@field normalSize number
---@field minSizeBuffer number
---@field maxSizeBuffer number
---@field spherical Spherical

local SphericalSchema = require("SphericalSchema")
local CameraDataSchema = {
    {"minSize", typeof(CS.System.Double), 8},
    {"maxSize", typeof(CS.System.Double), 21},
    {"normalSize", typeof(CS.System.Double), 12},
    {"minSizeBuffer", typeof(CS.System.Double), 1},
    {"maxSizeBuffer", typeof(CS.System.Double), 1},
    {"spherical", SphericalSchema},
}

return CameraDataSchema