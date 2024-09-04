local State = require("State")
---@class SETeamState:State
local SETeamState = class("SETeamState", State)

---@param seTeam SETeam
function SETeamState:ctor(seTeam)
    self._team = seTeam
end

function SETeamState:Enter()

end

function SETeamState:Exit()

end

function SETeamState:Tick(dt)

end

return SETeamState