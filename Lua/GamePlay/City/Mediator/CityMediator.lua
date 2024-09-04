---@class CityMediator
---@field new fun():CityMediator
local CityMediator = class("CityMediator")
local physics = physics
local EventConst = require("EventConst")
local GesturePhase = CS.DragonReborn.GesturePhase
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local CityConst = require("CityConst")
local CityUtils = require("CityUtils")
local KingdomLayer = CS.UnityEngine.LayerMask.NameToLayer("Kingdom") -- Layer:Kingdom  for soldiers
local CityFurniturePlaceUIParameter = require("CityFurniturePlaceUIParameter")

function CityMediator:ctor()
    self.gestureHandle = CS.LuaGestureListener(self)
    ---@type CityTrigger
    self._lastPressTrigger = nil
    self._checkPressUpTriggerClickFlag = false
    self._pressStart = nil
    self._pressStartTime = nil
end

---@param city City
function CityMediator:Initialize(city)
    self.city = city
    self.raycastDistance = 1000
    self.raycastLayerMask = -1
    self.gestureEnable = true
    g_Game.GestureManager:AddListener(self.gestureHandle)
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.OnEditModeExit))
end

function CityMediator:Release()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.OnEditModeExit))
    g_Game.GestureManager:RemoveListener(self.gestureHandle)
    self.city = nil
end

function CityMediator:SetEnableGesture(flag)
    self.gestureEnable = flag
end

---@param gesture CS.DragonReborn.TapGesture
function CityMediator:OnPressDown(gesture)
    g_Logger.Log("UIManager-CityMediator:OnPressDown, time:" .. g_Game.Time.frameCount)
    self._checkPressUpTriggerClickFlag = true
    self._pressStart = gesture and gesture.position
    self._pressStartTime = CS.UnityEngine.Time.realtimeSinceStartup
    if not self.gestureEnable then return end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GESTURE_PRESS_DOWN)
    local flag, trigger = self:PressTriggerAni(gesture)
    self.city:OnPressDown(gesture, trigger)
    self.pressDownTrigger = trigger
end

function CityMediator:CheckPressNoClickFlag(gesture)
    if self._checkPressUpTriggerClickFlag and self._pressStart and gesture and gesture.position then
        local offset = gesture.position - self._pressStart
        offset.z = 0
        if offset.sqrMagnitude > 10 then
            self._checkPressUpTriggerClickFlag = false
        end
    end
end

---@param gesture CS.DragonReborn.TapGesture
function CityMediator:PressTriggerAni(gesture)
    local flag, trigger = self:RaycastAny(gesture.position)
    if flag and trigger then
        if self._lastPressTrigger ~= trigger then
            if self._lastPressTrigger then
                self._lastPressTrigger:OnPressUpAnim()
            end
            if self.gestureEnable then
                if trigger then
                    trigger:OnPressDownAnim()
                end
                self._lastPressTrigger = trigger
            end
        end
    else
        if self._lastPressTrigger then
            self._lastPressTrigger:OnPressUpAnim()
        end
        self._lastPressTrigger = nil
    end
    return flag,trigger
end

---@param gesture CS.DragonReborn.TapGesture
function CityMediator:OnPress(gesture)
    self:CheckPressNoClickFlag(gesture)
    if not self.gestureEnable then return end
    if self.pressDownTrigger and self.city:OnPressTrigger(self.pressDownTrigger) then
        return
    end
    self.city:OnPress(gesture)
end

---@param gesture CS.DragonReborn.TapGesture
function CityMediator:OnRelease(gesture)
    g_Logger.Log("UIManager-CityMediator:OnRelease, time:" .. g_Game.Time.frameCount)
    self:CheckPressNoClickFlag(gesture)
    self.pressDownTrigger = nil
    self._pressStart = nil
    local checkClick = self._checkPressUpTriggerClickFlag
    local pressStartTime = self._pressStartTime
    self._pressStartTime = nil
    self._checkPressUpTriggerClickFlag = false
    if self._lastPressTrigger then
        self._lastPressTrigger:OnPressUpAnim()
    end
    self._lastPressTrigger = nil
    if not self.gestureEnable then return end
    -- if checkClick and pressStartTime and (CS.UnityEngine.Time.realtimeSinceStartup - pressStartTime) > 0.16 then
    --     self:OnClick(gesture)
    -- end
    self.city:OnRelease(gesture)
end

---@param gesture CS.DragonReborn.TapGesture
function CityMediator:OnClick(gesture,ignoreTrigger)
    self._checkPressUpTriggerClickFlag = false
    if not self.gestureEnable then return end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GESTURE_CLICK)
    
    if UNITY_EDITOR then
        local worldPos = self.city:GetCamera():GetHitPoint(gesture.position)
        local x, y = self.city:GetCoordFromPosition(worldPos)
        g_Logger.TraceChannel("CityMediator", ("Click On [%d,%d]"):format(x, y))
    end
    
    if not ignoreTrigger then
        local flag, trigger = self:RaycastAny(gesture.position)
        if flag then
            if trigger and self.city:OnClickTrigger(trigger, gesture.position) then
                return
            end
        end
    end

    self.city:OnClick(gesture)
end

function CityMediator:OnPinch(gesture)
    if not self.gestureEnable then return end
    self.city:OnPinch(gesture)
end

---@param position CS.UnityEngine.Vector3
---@return boolean,CityTrigger|nil 是否射线打到东西了,优先打中气泡UI的Trigger(因为它们总是绘制在最前面)
function CityMediator:RaycastAny(position)
    if self.city == nil then
        return nil,nil
    end

    local ray = self.city:GetCamera():GetRayFromScreenPosition(position)
    local result, retArray = physics.raycastnonalloc(ray, self.raycastDistance, self.raycastLayerMask)
    ---@type CityTrigger[]
    local triggers = {}    
    if result > 0 then
        for i = 1, result do
            local comp = retArray[i]:GetLuaBehaviourInParent("CityTrigger", true)
            if comp ~= nil then
                table.insert(triggers, comp.Instance)
            end            
        end

        if #triggers > 0 then
            for i, v in ipairs(triggers) do
                if v:IsUIBubble() then
                    return true, v
                end
            end            
        end

        if #triggers > 0 then
            return true,triggers[1]
        end        
    end
    return false,nil
end

---@param gesture CS.DragonReborn.DragGesture
function CityMediator:OnDrag(gesture)
    if not self.gestureEnable then return end
    if gesture.phase == GesturePhase.Started then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_GESTURE_TOUCH_START)
        self.city:OnDragStart(gesture)
    elseif gesture.phase == GesturePhase.Updated then
        self.city:OnDragUpdate(gesture)
    elseif gesture.phase == GesturePhase.Ended then
        self.city:OnDragEnd(gesture)
    end
end

function CityMediator:OnEditModeExit()
    if self.city and self.city:IsMyCity() then
        self.city:ExitEditMode()
        g_Game.UIManager:CloseByName(UIMediatorNames.CityFurniturePlaceUIMediator)
    end
end

function CityMediator:EnterEditMode(legoBuilding, focusConfigId)
    if self.city and self.city:IsMyCity() then
        self.city:EnterEditMode(legoBuilding)
        local param = CityFurniturePlaceUIParameter.new(self.city, focusConfigId, legoBuilding ~= nil)
        g_Game.UIManager:Open(UIMediatorNames.CityFurniturePlaceUIMediator, param)
    end
end

function CityMediator:SimClickTriggerScreenPos(screenPos)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GESTURE_CLICK)

    local flag, trigger = self:RaycastAny(screenPos)
    if not flag or not trigger then
        return
    end
    self.city:OnClickTrigger(trigger, screenPos)
end

function CityMediator:SimClickCoord(x, y)
    local worldPos = self.city:GetWorldPositionFromCoord(x, y)
    local screenPos = self.city:GetCamera().mainCamera:WorldToScreenPoint(worldPos)
    screenPos.z = 0
    self:OnClick({position = screenPos})
end

---@param tile CityTileBase
function CityMediator:SimClickTileBase(tile)
    if tile == nil then
        return
    end

    local worldPos = CityUtils.GetCityCellCenterPos(self.city, tile)
    local screenPos = self.city:GetCamera().mainCamera:WorldToScreenPoint(worldPos)
    screenPos.z = 0
    self:OnClick({position = screenPos})
end

return CityMediator