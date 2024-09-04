---@class CameraDataPerspective:CameraData
---@field minNear number
---@field maxNear number
---@field minFrustumLengthUnderGround number
---@field maxFrustumLengthUnderGround number

local schema = require("schema")
local CameraDataSchema = require("CameraDataSchema")
 
---@class CameraDataPerspectiveSchema
local CameraDataPerspectiveSchema = {
    -- 远近平面的计算相关的成员移到CameraPlaneDataSchema中了
}

schema.append(CameraDataPerspectiveSchema, CameraDataSchema)

return CameraDataPerspectiveSchema