---@class CitySEMediator
---@field new fun(gestureEnable:boolean):CitySEMediator
local CitySEMediator = class("CitySEMediator")

---@param city City
function CitySEMediator:ctor(gestureEnable)
    self.gestureEnable = gestureEnable
    self.gestureHandle = CS.LuaGestureListener(self)
    ---@type SEEnvironment
    self.environment = nil
end

function CitySEMediator:Initialize(city)
    self.city = city
    g_Game.GestureManager:AddListener(self.gestureHandle)
end

function CitySEMediator:Release()
    self.environment = nil
    g_Game.GestureManager:RemoveListener(self.gestureHandle)
end

---@param seEnvironment SEEnvironment
function CitySEMediator:SetSeEnvironment(seEnvironment)
    self.environment = seEnvironment
end

function CitySEMediator:SetEnableGesture(flag)
    self.gestureEnable = flag
end

---@param gesture CS.DragonReborn.TapGesture
function CitySEMediator:OnPressDown(gesture)
    if not self.gestureEnable then return end
end

---@param gesture CS.DragonReborn.TapGesture
function CitySEMediator:OnPress(gesture)
    if not self.gestureEnable then return end
end

---@param gesture CS.DragonReborn.TapGesture
function CitySEMediator:OnRelease(gesture)
    if not self.gestureEnable then return end
end

---@param gesture CS.DragonReborn.TapGesture
function CitySEMediator:OnClick(gesture)
    if not self.gestureEnable then return end
end

---@param gesture CS.DragonReborn.DragGesture
function CitySEMediator:OnDrag(gesture)
    if not self.gestureEnable then return end
end

---@param gesture CS.DragonReborn.PinchGesture
function CitySEMediator:OnPinch(gesture)
    if not self.gestureEnable then return end
end

function CitySEMediator:GetGestureStatus()
end

function CitySEMediator:IsInputOverUI(inputIndex)
end

return CitySEMediator