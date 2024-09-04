local ModuleRefer = require("ModuleRefer")
local State = require("State")

---@class MapStateNormal : State
local MapStateNormal = class("MapStateNormal", State)
MapStateNormal.Name = "MapStateNormal"

function MapStateNormal:Enter()
    ModuleRefer.SlgModule:EnableTouch(true)
end

function MapStateNormal:Exit()
    ModuleRefer.SlgModule:EnableTouch(false)
end

return MapStateNormal