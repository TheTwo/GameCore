
local CityExplorerTeamState = require("CityExplorerTeamState")

---@class CityExplorerTeamStateBackToBase:CityExplorerTeamState
---@field super CityExplorerTeamState
local CityExplorerTeamStateBackToBase = class("CityExplorerTeamStateBackToBase", CityExplorerTeamState)

function CityExplorerTeamStateBackToBase:Enter()
    self._team._mgr:SendDismissTeam(self._team)
end

return CityExplorerTeamStateBackToBase