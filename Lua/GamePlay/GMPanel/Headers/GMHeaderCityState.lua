local GMHeader = require("GMHeader")

---@class GMHeaderCityState:GMHeader
---@field new fun():GMHeaderCityState
---@field super GMHeader
local GMHeaderCityState = class('GMHeaderCityState', GMHeader)

function GMHeaderCityState:Init(panel)
    GMHeader.Init(self, panel)
end

function GMHeaderCityState:DoText()
    local scene = g_Game.SceneManager.current
    if not scene or not scene.stateMachine then return nil end

    local state = scene.stateMachine.currentState
    if not state then return nil end

    local city = state.city
    if not city then return nil end

    if city.stateMachine and city.stateMachine.currentState then
        return city.stateMachine.currentState:GetName()
    end
    return nil
end

function GMHeaderCityState:Release()
    GMHeader.Release(self) 
end

return GMHeaderCityState

