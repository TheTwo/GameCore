---prefab:vx_ui_touch_feedback_01

local Delegate = require("Delegate")
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@class UIClickScreenEffect
---@field new fun():UIClickScreenEffect
local UIClickScreenEffect = sealedClass('UIClickScreenEffect')

function UIClickScreenEffect:ctor()
    ---@type CS.UnityEngine.GameObject
    self._effectGo = nil
    ---@type CS.Coffee.UIExtensions.UIParticle
    self._effect = nil
    self._isReleased = false
    ---@type CS.UnityEngine.Transform
    self._root = nil
    ---@type CS.UnityEngine.Camera
    self._uiCamera = nil
    ---@type CS.UnityEngine.Vector2
    self._lastPos = nil
    self._goCreator = GameObjectCreateHelper.Create()
    self._inAssetLoading = false
    self._allowedPlayEffect = false
end

function UIClickScreenEffect:Initialize(root, uiCamera)
    self._root = root
    self._uiCamera = uiCamera
    self._gestureListener = CS.LuaGestureListener(self)
    g_Game.GestureManager:AddListener(self._gestureListener)
end

function UIClickScreenEffect:Reset()
    self._goCreator:CancelAllCreate()
    self._isReleased = true
    if Utils.IsNotNull(self._effectGo) then
        GameObjectCreateHelper.DestroyGameObject(self._effectGo)
    end
    self._inAssetLoading = false
    self._lastPos = nil
    self._effectGo = nil
    self._effect = nil
    self._root = nil
    self._uiCamera = nil
    self._allowedPlayEffect = false
    g_Game.GestureManager:RemoveListener(self._gestureListener)
    self._gestureListener = nil
end

function UIClickScreenEffect:SetEffectSwitch(isOn)
    self._allowedPlayEffect = isOn
end

---@param vector2 CS.UnityEngine.Vector2|{x:number,y:number} @screenPosition
function UIClickScreenEffect:PlayOnScreen(vector2)
    if self._isReleased then
        return
    end
    if not self._allowedPlayEffect then
        return
    end
    if Utils.IsNull(self._root) then
        return
    end
    self._lastPos = vector2
    if Utils.IsNotNull(self._effect) then
        self:DoPlayOnScreenPos(vector2)
    elseif Utils.IsNull(self._effectGo) and not self._inAssetLoading then
        if not CS.DragonReborn.VersionControl.VersionReadyFlag or not g_Game.AssetManager or not g_Game.AssetManager:IsInitialized() then
            return
        end
        self._inAssetLoading = true
        self._goCreator:Create(ManualResourceConst.vx_ui_touch_feedback_01, self._root, Delegate.GetOrCreate(self, self.OnAssetReady))
    end
end

---@param go CS.UnityEngine.GameObject
function UIClickScreenEffect:OnAssetReady(go)
    if Utils.IsNull(go) then
        return
    end
    if self._isReleased then
        GameObjectCreateHelper.DestroyGameObject(go)
        return
    end
    self._inAssetLoading = false
    self._effectGo = go
    self._effect = go:GetComponentInChildren(typeof(CS.Coffee.UIExtensions.UIParticle))
    if Utils.IsNotNull(self._effect) then
        self._effectGo:SetVisible(true)
        for i = 0, self._effect.particles.Count - 1 do
            ---@type CS.UnityEngine.ParticleSystem
            local p = self._effect.particles[i]
            if Utils.IsNotNull(p) then
                ---@type CS.UnityEngine.ParticleSystemRenderer
                local render = p.gameObject:GetComponent(typeof(CS.UnityEngine.ParticleSystemRenderer))
                if Utils.IsNotNull(render) then
                    render.enabled = false
                end
            end
        end
    end
    if Utils.IsNotNull(self._effect) and self._lastPos then
        self:DoPlayOnScreenPos(self._lastPos)
    end
end

---@param vector2 CS.UnityEngine.Vector2|{x:number,y:number} @screenPosition
function UIClickScreenEffect:DoPlayOnScreenPos(vector2)
    local uiPos = self._uiCamera:ScreenToWorldPoint(CS.UnityEngine.Vector3(vector2.x, vector2.y))
    local localPos = self._root:InverseTransformPoint(uiPos)
    self._effect.transform.localPosition = localPos
    self._effect:Stop()
    self._effect:Play()
end

---IGestureListener
---@param gesture CS.DragonReborn.TapGesture
function UIClickScreenEffect:OnPressDown(gesture)
end

---@param gesture CS.DragonReborn.TapGesture
function UIClickScreenEffect:OnPress(gesture)
end

---@param gesture CS.DragonReborn.TapGesture
function UIClickScreenEffect:OnRelease(gesture)
end

---@param gesture CS.DragonReborn.TapGesture
function UIClickScreenEffect:OnClick(gesture)
    g_Logger.Log("onclick:%s", gesture.position)
    self:PlayOnScreen({x=gesture.position.x,y=gesture.position.y})
end

---@param gesture CS.DragonReborn.DragGesture
function UIClickScreenEffect:OnDrag(gesture)
end

---@param gesture CS.DragonReborn.PinchGesture
function UIClickScreenEffect:OnPinch(gesture)
end

return UIClickScreenEffect