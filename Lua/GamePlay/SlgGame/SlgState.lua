local State = require("State")
local SlgScene = require("SlgScene")

---@class SlgState:State
local SlgState = class("SlgState", State)

SlgState.Name = "SlgState"

function SlgState:Enter()
    g_Game.SceneManager:EnterScene(SlgScene.Name)
end

function SlgState:Exit()
    g_Game.SceneManager:ExitScene(SlgScene.Name)
end

function SlgState:Tick(dt)
    
end

function SlgState:GetName()
    return SlgState.Name
end

return SlgState