local CityState = require("CityState")
---@class CityStateAirView:CityState
---@field new fun():CityStateAirView
local CityStateAirView = class("CityStateAirView", CityState)
local CityConst = require("CityConst")

---@param gesture CS.DragonReborn.TapGesture
function CityStateAirView:OnClick(gesture)
    local count, x, y, point, furTile, cellTile, legoTile = self.city:RaycastAnyTileBase(gesture.position)
    if count > 0 then
        local anchor = self.city:GetCamera():GetPlaneHitPoint(gesture.position)
        local delta = CityConst.AIR_VIEW_THRESHOLD - self.city.cameraSize
        self.city:GetCamera():ZoomWithAnchor(delta, anchor, 0.25, function()
            self.city:OnClick(gesture)
        end)
    end
end

function CityStateAirView:OnCameraSizeChanged(oldValue, newValue)
    if newValue <= CityConst.AIR_VIEW_THRESHOLD then
        self.stateMachine:ChangeState(CityConst.STATE_NORMAL)
    end
    if self.stateMachine.currentName ~= CityConst.STATE_AIR_VIEW then
        self.stateMachine.currentState:OnCameraSizeChanged(oldValue, newValue)
    end
end

function CityStateAirView:Enter()
    CityState.Enter(self)
    self.city:ExitEditMode()
end

function CityStateAirView:Exit()
    CityState.Exit(self)
end

return CityStateAirView