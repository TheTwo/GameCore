---@type CS.UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3
local KingdomType = require("KingdomType")
local CameraUtils = require("CameraUtils")
local Utils = require("Utils")

local GMHeader = require("GMHeader")
local PLANE = CS.UnityEngine.Plane(CS.UnityEngine.Vector3.up, CS.UnityEngine.Vector3.zero)
---@class GMHeaderKingdomCoordinate:GMHeader
---@field new fun():GMHeaderKingdomCoordinate
---@field super GMHeader
local GMHeaderKingdomCoordinate = class("GMHeaderKingdomCoordinate", GMHeader)

function GMHeaderKingdomCoordinate:ctor()
    GMHeader.ctor(self)

    self._useCopyBtn = true
    self._screenCenterPos = Vector3(0.5, 0.5, 0)
end

function GMHeaderKingdomCoordinate:DoText()
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
    if scene:IsInCity() then
        return nil
    end
    if Utils.IsNull(scene.staticMapData)
        or Utils.IsNull(scene.basicCamera)
        or Utils.IsNull(scene.basicCamera.mainCamera) then
        return nil
    end
    local unitsPerTileX = scene.staticMapData.UnitsPerTileX or 0
    local UnitsPerTileZ = scene.staticMapData.UnitsPerTileZ or 0
    if unitsPerTileX <= 0 or UnitsPerTileZ <= 0 then
        return nil
    end
    local ray = scene.basicCamera.mainCamera:ViewportPointToRay(self._screenCenterPos)
    local pos = CameraUtils.GetHitPointLinePlane(ray, PLANE)
    if not pos then
        return nil
    end
    return string.format("[K]x:%0.2f,z:%0.2f,size:%0.2f", pos.x / unitsPerTileX , pos.z / UnitsPerTileZ, scene.basicCamera:GetSize())
end

return GMHeaderKingdomCoordinate