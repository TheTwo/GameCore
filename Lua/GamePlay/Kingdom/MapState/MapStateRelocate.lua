local State = require("State")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")

---@class MapStateRelocate : State
local MapStateRelocate = class("MapStateRelocate", State)
MapStateRelocate.Name = "MapStateRelocate"

function MapStateRelocate:Enter()
    g_Game.EventManager:TriggerEvent(EventConst.MAP_RESET_SELECTION)
end

function MapStateRelocate:Tick(dt)
    ModuleRefer.KingdomPlacingModule:Tick()
end

return MapStateRelocate