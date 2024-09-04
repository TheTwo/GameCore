local UnityEngine = CS.UnityEngine
local GUI = UnityEngine.GUI
local Screen = UnityEngine.Device.Screen
local Matrix4x4 = UnityEngine.Matrix4x4
local Rect = UnityEngine.Rect

---@class GUIPanelScope
local GUIPanelScope = class('GUIPanelScope')

function GUIPanelScope:ctor()
    self.V3Zero = CS.UnityEngine.Vector3.zero
    self.QIdentity = CS.UnityEngine.Quaternion.identity
end

---@return "Rect"
function GUIPanelScope:Begin(targetX, targetY)
    self._originMatrix = GUI.matrix
    local safeArea = Screen.safeArea
    local screenX = safeArea.width
    local screenY = Screen.height
    local screenRate = screenX / screenY
    local targetRate = targetX / targetY
    local scale = 1
    if screenRate > targetRate then
        scale = screenY / targetY
        targetX = screenX / scale
    else
        scale = screenX / targetX
        targetY = screenY / scale
    end
    GUI.matrix = Matrix4x4.TRS(self.V3Zero, self.QIdentity, UnityEngine.Vector3(scale, scale, 1))
    local ret = Rect(safeArea.x / scale, 0, targetX, targetY)
    return ret
end

function GUIPanelScope:End()
    GUI.matrix = self._originMatrix
end

return GUIPanelScope