local State = require("State")
---@class CityState:State
---@field new fun():CityState
---@field city City|MyCity
local CityState = class("CityState", State)
local UIMediatorNames = require("UIMediatorNames")
local CityZoneStatus = require("CityZoneStatus")
local EventConst = require("EventConst")
local CityConst = require("CityConst")
local SdkCrashlytics = require("SdkCrashlytics")

function CityState:ctor(city)
    self.city = city
end

function CityState:Enter()
    SdkCrashlytics.RecordCityState(GetClassName(self), false)
end

function CityState:Exit()
    SdkCrashlytics.RecordCityState(GetClassName(self), true)
end

---@param trigger CityTrigger
function CityState:OnPressTrigger(trigger)
    --- override this
end

---@param gesture CS.DragonReborn.TapGesture
function CityState:OnPressDown(gesture)
    --- override this
end

---@param gesture CS.DragonReborn.TapGesture
function CityState:OnPress(gesture)
    --- override this
end

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
function CityState:OnClickTrigger(trigger, position)
    --- override this
    return false
end

---@param gesture CS.DragonReborn.TapGesture
function CityState:OnClick(gesture)
    --- override this
end

---@param gesture CS.DragonReborn.DragGesture
function CityState:OnDragStart(gesture)
    --- override this
end

---@param gesture CS.DragonReborn.DragGesture
function CityState:OnDragUpdate(gesture)
    --- override this
end

---@param gesture CS.DragonReborn.DragGesture
function CityState:OnDragEnd(gesture)
    --- override this
end

---@param gesture CS.DragonReborn.TapGesture
function CityState:OnRelease(gesture)
    --- override this
end

---@param gesture CS.DragonReborn.PinchGesture
function CityState:OnPinch(gesture)
    --- override this
end

function CityState:OnCameraSizeChanged(oldSize, newSize)
    --- override this
end

---@param zone CityZone
---@param hitPoint CS.UnityEngine.Vector3
---@return boolean @true - block click
function CityState:OnClickZone(zone, hitPoint)
    if zone and zone.status == CityZoneStatus.NotExplore then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_TRY_UNLOCK_ZONE, self.city.uid, zone, hitPoint)
        return true
    end
    return false
end

function CityState:BlockCamera()
    local camera = self.city:GetCamera()
    if camera ~= nil then
        camera.enableDragging = false
    end
end

function CityState:RecoverCamera()
    local camera = self.city:GetCamera()
    if camera then
        camera.enableDragging = true
    end
end

function CityState:ChangeAndCacheCameraSmoothing(value)
    local camera = self.city:GetCamera()
    if camera then
        self.smoothing, camera.smoothing = camera.smoothing, value
    end
end

function CityState:RecoverCameraSmoothingFromCache()
    local camera = self.city:GetCamera()
    if camera and self.smoothing then
        self.smoothing, camera.smoothing = nil, self.smoothing
    end
end

function CityState:ChangeAndCacheHudRootAlpha(value, tween)
    local root = g_Game.UIManager:GetRootForType(g_Game.UIManager.UIMediatorType.Hud)
    if root then
        local canvasGroup = root:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        if canvasGroup then
            self.alpha = canvasGroup.alpha
            if tween then
                self.alphaTweener = CS.DOTweenExt.DOFloatTween(self.alpha, function(v)
                    if canvasGroup then
                        canvasGroup.alpha = v
                    end
                end, value, 0.2):OnComplete(function()
                    self.alphaTweener = nil
                end)
            else
                canvasGroup.alpha = value
            end
        end
    end
end

function CityState:RecoverHudRootAlphaFromCache(tween)
    local root = g_Game.UIManager:GetRootForType(g_Game.UIManager.UIMediatorType.Hud)
    if root then
        local canvasGroup = root:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        if canvasGroup and self.alpha then
            if self.alphaTweener then
                self.alphaTweener:Kill()
            end
            if tween then
                self.alphaTweener = CS.DOTweenExt.DOFloatTween(canvasGroup.alpha, function(v)
                    if canvasGroup then
                        canvasGroup.alpha = v
                    end
                end, self.alpha, 0.2):OnComplete(function()
                    self.alphaTweener = nil
                end)
            else
                canvasGroup.alpha = self.alpha
            end
            self.alpha = nil
        end
    end
end

function CityState:ExitToIdleState()
    self.stateMachine:ChangeState(self.city:GetSuitableIdleState(self.city.cameraSize))
end

function CityState:ShowCityCircleMenu()
    if self.circleRuntimeId then
        return
    end

    local param = self:GetCircleMenuUIParameter()
    self.circleRuntimeId = g_Game.UIManager:Open(UIMediatorNames.CityCircleMenuUIMediator, param)
end

function CityState:HideCityCircleMenu(param)
    if not self.circleRuntimeId then
        return
    end
    g_Game.UIManager:Close(self.circleRuntimeId, param)
    self.circleRuntimeId = nil
end

function CityState:GetCircleMenuUIParameter()
    return nil
end

function CityState:TryChangeToAirView(oldValue, newValue)
    -- if newValue > CityConst.AIR_VIEW_THRESHOLD then
    --     self.stateMachine:ChangeState(CityConst.STATE_AIR_VIEW)
    -- end
end

return CityState