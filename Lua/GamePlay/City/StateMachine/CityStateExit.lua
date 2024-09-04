local CityState = require("CityState")
---@class CityStateExit
local CityStateExit = class("CityStateExit", CityState)
local UIMediatorNames = require("UIMediatorNames")

function CityStateExit:Enter()
    CityState.Enter(self)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
end

return CityStateExit