---@type CS.UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3
local KingdomType = require("KingdomType")

local GMHeader = require("GMHeader")

---@class GMHeaderCityCoordinate
---@field new fun():GMHeaderCityCoordinate
local GMHeaderCityCoordinate = class('GMHeaderCityCoordinate', GMHeader)

function GMHeaderCityCoordinate:ctor()
    GMHeader.ctor(self)

    self._useCopyBtn = true
    self._screenCenterPos = Vector3(0.5, 0.5, 0)
end

function GMHeaderCityCoordinate:DoText()
    local GotoUtils = require("GotoUtils")
    if GotoUtils.GetCurrentKingdomType() ~= KingdomType.Kingdom then
        return nil
    end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then
        return nil
    end
    if scene:GetName() ~= "KingdomScene" then
        return nil
    end
    if not scene:IsInCity() then
        return nil
    end
    ---@type City
    local city = scene.stateMachine.currentState.city
    if not city then
        return nil
    end
    local camera = city.camera
    if not camera then
        return nil
    end
    local position = camera:GetUnityCamera():ViewportToScreenPoint(self._screenCenterPos)
    local point = camera:GetHitPoint(position)
    local x, y = city:GetCoordFromPosition(point)
    return string.format("[C]x:%d,z:%d,size:%0.2f,altitude:%0.2f", x , y, scene.basicCamera:GetSize(), scene.basicCamera:GetAltitude())
end

return GMHeaderCityCoordinate

