local EmptyStep = require("EmptyStep")
---@class WaitStateNormalStep:EmptyStep
---@field new fun():WaitStateNormalStep
local WaitStateNormalStep = class("WaitStateNormalStep", EmptyStep)
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function WaitStateNormalStep:ctor()
    self.finished = false
end

function WaitStateNormalStep:Start()
    g_Game.EventManager:AddListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChange))
end

function WaitStateNormalStep:End()
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChange))
end

function WaitStateNormalStep:TryExecuted()
    return self.finished
end

function WaitStateNormalStep:OnCityStateChange(city, oldState, newState)
    if newState:GetName() == "CityStateNormal" then
        self.finished = true
    end
end

return WaitStateNormalStep