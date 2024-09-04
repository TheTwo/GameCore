local EventConst = require("EventConst")

local CityExplorerTeamState = require("CityExplorerTeamState")

---@class CityExplorerTeamStateIdle:CityExplorerTeamState
---@field new fun(team:CityExplorerTeam):CityExplorerTeamStateIdle
---@field super CityExplorerTeamState
local CityExplorerTeamStateIdle = class('CityExplorerTeamStateIdle', CityExplorerTeamState)

function CityExplorerTeamStateIdle:Enter()
    CityExplorerTeamState.Enter(self)
    self._team._teamData:MarkForceNotifyPosFlag()
end

return CityExplorerTeamStateIdle

