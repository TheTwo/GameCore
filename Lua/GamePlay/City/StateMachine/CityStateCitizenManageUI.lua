local CityConst = require("CityConst")
local EventConst = require("EventConst")

local CityState = require("CityState")

---@class CityStateCitizenManageUI:CityState
---@field new fun():CityStateCitizenManageUI
---@field super CityState
local CityStateCitizenManageUI = class('CityStateCitizenManageUI', CityState)

function CityStateCitizenManageUI:OnCameraSizeChanged(oldValue, newValue)
    if newValue > CityConst.CITY_FAR_CAMERA_SIZE then
        self.stateMachine:ChangeState(self.city:GetSuitableIdleState(self.city.cameraSize))
    end
end

function CityStateCitizenManageUI:Exit()
    local exitAction = self.stateMachine:ReadBlackboard("CityStateCitizenManageUIExitCallback")
    if exitAction then
        exitAction()
    end
    CityState.Exit(self)
end

function CityStateCitizenManageUI:OnClick(gesture)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE_CLICK, gesture)
end

return CityStateCitizenManageUI