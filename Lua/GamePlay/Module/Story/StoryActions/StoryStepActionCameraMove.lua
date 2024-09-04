local GotoUtils = require("GotoUtils")
local KingdomType = require('KingdomType')
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionCameraMove:StoryStepActionBase
---@field new fun():StoryStepActionCameraMove
---@field super StoryStepActionBase
local StoryStepActionCameraMove = class('StoryStepActionCameraMove', StoryStepActionBase)

function StoryStepActionCameraMove:ctor()
    StoryStepActionBase.ctor(self)
    ---@type number @float
    self._gridX = nil
    ---@type number @float
    self._gridY = nil
    ---@type number @float
    self._cameraSize = nil
    ---@type number @float
    self._moveTime = nil
    self._moveStart = false
    ---@type BasicCamera
    self._runtimeCamera = nil
    ---@type CS.UnityEngine.Vector3
    self._runtimeTargetPos = nil
end

function StoryStepActionCameraMove:LoadConfig(actionParam)
    local sp = string.split(actionParam, ',')
    self._gridX = tonumber(sp[1])
    self._gridY = tonumber(sp[2])
    self._cameraSize = tonumber(sp[3])
    if #sp > 3 then
        self._moveTime = tonumber(sp[4])
    else
        self._moveTime = 0
    end
end

function StoryStepActionCameraMove:OnEnter()
    self:SetGestureBlock()
    self._moveStart = self:TryStart()
end

function StoryStepActionCameraMove:OnLeave()
    if self._runtimeCamera then
        self._runtimeCamera:ForceGiveUpTween()
        self._runtimeCamera = nil
    end
    self:UnSetGestureBlock()
end

function StoryStepActionCameraMove:OnExecute()
    if self._moveStart then
        return
    end
    self._moveStart = self:TryStart()
end

function StoryStepActionCameraMove:TryStart()
    local current = g_Game.SceneManager.current
    if not current then
        return false
    end
   
    if GotoUtils.GetCurrentKingdomType() == KingdomType.Kingdom then
        self._runtimeCamera = KingdomMapUtils.GetBasicCamera()
        if not self._runtimeCamera then
            return false
        end
        if ModuleRefer.CityModule.myCity.showed then
            local targetPos = ModuleRefer.CityModule.myCity:GetWorldPositionFromCoord(self._gridX, self._gridY)
            self._runtimeTargetPos = targetPos
            self._runtimeCamera:ForceGiveUpTween()
            self._runtimeCamera:ZoomToWithFocus(self._cameraSize, CS.UnityEngine.Vector3(0.5, 0.5, 0.5), self._runtimeTargetPos, self._moveTime, Delegate.GetOrCreate(self, self.OnCameraArrived))
            return true
        end
    end
    return false
end

function StoryStepActionCameraMove:OnSetEndStatus(isRestore)
    if isRestore then
        if ModuleRefer.CityModule.myCity.showed then
            self._runtimeCamera = ModuleRefer.CityModule.myCity:GetCamera()
            local targetPos = ModuleRefer.CityModule.myCity:GetWorldPositionFromCoord(self._gridX, self._gridY)
            self._runtimeTargetPos = targetPos
        end
    end
    if self._runtimeCamera then
        self._runtimeCamera:ForceGiveUpTween()
        self._runtimeCamera:ZoomToWithFocus(self._cameraSize, CS.UnityEngine.Vector3(0.5, 0.5, 0.5), self._runtimeTargetPos, 0)
    end
end

function StoryStepActionCameraMove:OnCameraArrived()
    if self.IsDone or self.IsFailure then return end
    self:EndAction(true)
end

return StoryStepActionCameraMove