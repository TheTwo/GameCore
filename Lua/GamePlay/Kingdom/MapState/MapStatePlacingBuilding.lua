local State = require("State")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")

---@class MapStatePlacingBuilding : State
local MapStatePlacingBuilding = class("MapStatePlacingBuilding", State)
MapStatePlacingBuilding.Name = "MapStatePlacingBuilding"

function MapStatePlacingBuilding:Enter()
    g_Game.EventManager:TriggerEvent(EventConst.MAP_RESET_SELECTION)
end

function MapStatePlacingBuilding:Tick(dt)
    ModuleRefer.KingdomPlacingModule:Tick()
end

return MapStatePlacingBuilding