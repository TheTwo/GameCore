local State = require("State")

---@class CityExplorerTeamState:State
---@field new fun(team:CityExplorerTeam):CityExplorerTeamState
---@field super State
local CityExplorerTeamState = class('CityExplorerTeamState', State)

---@param team CityExplorerTeam
function CityExplorerTeamState:ctor(team)
    self._team = team
end

return CityExplorerTeamState

