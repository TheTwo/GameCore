local State = require("State")
local NewbieScene = require("NewbieScene")

---@class NewbieState:State
local NewbieState = class("NewbieState", State)

NewbieState.Name = "NewbieState"

function NewbieState:Enter()
    g_Game.SceneManager:EnterScene(NewbieScene.Name)
end

function NewbieState:Exit()
    g_Game.SceneManager:ExitScene(NewbieScene.Name)
end

function NewbieState:GetName()
    return NewbieState.Name
end

return NewbieState