local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local State = require("State")

---@class CityFurnitureConstructionSynthesizeState:State
---@field new fun(host:CityFurnitureConstructionSynthesizeUIMediator):CityFurnitureConstructionSynthesizeState
---@field super State
local CityFurnitureConstructionSynthesizeState = class('CityFurnitureConstructionSynthesizeState', State)

---@param host CityFurnitureConstructionSynthesizeUIMediator
function CityFurnitureConstructionSynthesizeState:ctor(host)
    self._host = host
end

return CityFurnitureConstructionSynthesizeState