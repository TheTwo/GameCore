local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local SEJoystickDefine = require("SEJoystickDefine")

---@class SEJoystickControlModule:BaseModule
local SEJoystickControlModule = class('SEJoystickControlModule', BaseModule)

function SEJoystickControlModule:OnRegister()
    self._isDragging = {}
    self._dirX, self._dirY = {}, {}
    self._intencity = {}
    self._inCancelRange = {}
    self._currentSelectedBallId = nil

    g_Game.EventManager:AddListener(EventConst.SE_JOYSTICK_POINTER_DOWN, Delegate.GetOrCreate(self, self.OnJoystickPointerDown))
    g_Game.EventManager:AddListener(EventConst.SE_JOYSTICK_POINTER_UP, Delegate.GetOrCreate(self, self.OnJoystickPointerUp))
    g_Game.EventManager:AddListener(EventConst.SE_JOYSTICK_POINTER_CANCEL, Delegate.GetOrCreate(self, self.OnJoystickPointerUpCancel))
    g_Game.EventManager:AddListener(EventConst.SE_JOYSTICK_VALUE_CHANGED, Delegate.GetOrCreate(self, self.OnJoystickValueChanged))
    g_Game.EventManager:AddListener(EventConst.SE_JOYSTICK_VALUE_CLEAR, Delegate.GetOrCreate(self, self.OnJoystickValueClear))
end

function SEJoystickControlModule:OnRemove()
    g_Game.EventManager:RemoveListener(EventConst.SE_JOYSTICK_POINTER_DOWN, Delegate.GetOrCreate(self, self.OnJoystickPointerDown))
    g_Game.EventManager:RemoveListener(EventConst.SE_JOYSTICK_POINTER_UP, Delegate.GetOrCreate(self, self.OnJoystickPointerUp))
    g_Game.EventManager:RemoveListener(EventConst.SE_JOYSTICK_POINTER_CANCEL, Delegate.GetOrCreate(self, self.OnJoystickPointerUpCancel))
    g_Game.EventManager:RemoveListener(EventConst.SE_JOYSTICK_VALUE_CHANGED, Delegate.GetOrCreate(self, self.OnJoystickValueChanged))
    g_Game.EventManager:RemoveListener(EventConst.SE_JOYSTICK_VALUE_CLEAR, Delegate.GetOrCreate(self, self.OnJoystickValueClear))
end

function SEJoystickControlModule:OnJoystickPointerDown(joystickIdx)
    self._isDragging[joystickIdx] = true
    self._dirX[joystickIdx] = 0
    self._dirY[joystickIdx] = 0
    self._intencity[joystickIdx] = 0
    self._inCancelRange[joystickIdx] = false
end

function SEJoystickControlModule:OnJoystickPointerUp(joystickIdx)
    self._isDragging[joystickIdx] = false
    self._inCancelRange[joystickIdx] = false
end

function SEJoystickControlModule:OnJoystickPointerUpCancel(joystickIdx)
    self._isDragging[joystickIdx] = false
    self._inCancelRange[joystickIdx] = true
end

---@param vector2 CS.UnityEngine.Vector2
function SEJoystickControlModule:OnJoystickValueChanged(joystickIdx, vector2, inCancelRange)
    if not self._isDragging[joystickIdx] then
        return
    end

    local normalized = vector2.normalized
    self._dirX[joystickIdx] = normalized.x
    self._dirY[joystickIdx] = normalized.y
    self._intencity[joystickIdx] = vector2.magnitude
    self._inCancelRange[joystickIdx] = inCancelRange or false
end

function SEJoystickControlModule:IsJoystickMoving(checkIntencity)
    if not checkIntencity then
        return self._isDragging[SEJoystickDefine.JoystickType.Move] == true
    else
        return self._isDragging[SEJoystickDefine.JoystickType.Move] == true and self._intencity[SEJoystickDefine.JoystickType.Move] >= SEJoystickDefine.Threshold
    end
end

---@return number, number, number @x, y, intencity
function SEJoystickControlModule:GetMovingParam()
    local x = self._dirX[SEJoystickDefine.JoystickType.Move] or 0
    local y = self._dirY[SEJoystickDefine.JoystickType.Move] or 0
    local intensity = self._intencity[SEJoystickDefine.JoystickType.Move] or 0
    return x, y, intensity
end

function SEJoystickControlModule:IsJoystickThrowIndicatorShow()
    local isPressDown = self._isDragging[SEJoystickDefine.JoystickType.Ball] == true
    local value = self._intencity[SEJoystickDefine.JoystickType.Ball] or 0
    local isNotInDeadZone = value >= SEJoystickDefine.Threshold
    return isPressDown and isNotInDeadZone, isPressDown
end

---@return number, number, number, boolean, number @x, y, intencity, inCancelRange, PetPocketBallId
function SEJoystickControlModule:GetThrowBallParam()
    local x = self._dirX[SEJoystickDefine.JoystickType.Ball] or 0
    local y = self._dirY[SEJoystickDefine.JoystickType.Ball] or 0
    local intensity = self._intencity[SEJoystickDefine.JoystickType.Ball] or 0
    local inCancelRange = self._inCancelRange[SEJoystickDefine.JoystickType.Ball] or false
    return x, y, intensity, inCancelRange, self._currentSelectedBallId or 0
end

function SEJoystickControlModule:SetCurrentSelectedBallItemId(pocketBallId)
    self._currentSelectedBallId = pocketBallId
end

function SEJoystickControlModule:OnJoystickValueClear(...)
    local joystickids = {...}
    for _, idx in ipairs(joystickids) do
        self._isDragging[idx] = false
        self._dirX[idx] = 0
        self._dirY[idx] = 0
        self._intencity[idx] = 0
        self._inCancelRange[idx] = false
    end
end

return SEJoystickControlModule