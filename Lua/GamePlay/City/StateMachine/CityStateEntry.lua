local CityState = require("CityState")
local EventConst = require("EventConst")
---@class CityStateEntry:CityState
---@field new fun():CityStateEntry
local CityStateEntry = class("CityStateEntry", CityState)

function CityStateEntry:Enter()
    CityState.Enter(self)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_DEFAULT)
    self.stateMachine:ChangeState(self.city:GetSuitableIdleState(self.city.cameraSize))
end

return CityStateEntry