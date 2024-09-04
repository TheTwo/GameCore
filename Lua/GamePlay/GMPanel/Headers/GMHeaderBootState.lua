local GMHeader = require("GMHeader")

---@class GMHeaderBootState:GMHeader
local GMHeaderBootState = class('GMHeaderBootState', GMHeader)

function GMHeaderBootState:DoText()
    if (not g_Game) or (not g_Game.bootStateMachine) then
        return string.Empty
    end
    return string.format("%s", g_Game.bootStateMachine:GetCurrentStateName())
end

return GMHeaderBootState