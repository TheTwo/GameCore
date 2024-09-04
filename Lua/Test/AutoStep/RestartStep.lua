local EmptyStep = require("EmptyStep")
---@class RestartStep:EmptyStep
---@field new fun():RestartStep
local RestartStep = class("RestartStep", EmptyStep)

function RestartStep:TryExecuted(lastReturn)
    if lastReturn == true then
        return true
    end

    if lastReturn == false then
        local RuntimeDebugSettings = require("RuntimeDebugSettings")
        RuntimeDebugSettings:ClearOverrideAccountConfig()
        g_Game:RestartGame()
        return true
    end

    return false
end

return RestartStep