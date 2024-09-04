local State = require("State")

---@class CityExplorerState:State
---@field new fun(actor:CityUnitExplorer):CityExplorerState
local CityExplorerState = class('CityExplorerState', State)

---@param explorer CityUnitExplorer
function CityExplorerState:ctor(explorer)
    self._explorer = explorer
end

return CityExplorerState