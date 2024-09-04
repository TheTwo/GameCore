local Utils = require("Utils")
local Delegate = require("Delegate")

---@class UnitModel
---@field new fun(asset:string,goCreator:CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper):UnitModel
local UnitModel = class('UnitModel')

---@param asset string
---@param goCreator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
function UnitModel:ctor(asset, goCreator)
    self._asset = asset
    self._goCreator = goCreator
    self._handle = nil
    self._go = nil
    self._animator = nil
    self._ready = false
    self._overrideLayerName = nil
    self._isHide = false
    self._animators = nil
    self._animatorCount = 0
end

function UnitModel:IsReady()
    return self._ready
end

---@param parent CS.UnityEngine.Transform
---@param whenReady fun(model:UnitModel)
function UnitModel:InitAsync(parent, whenReady)
    self._readyCallback = whenReady
    self:SetParent(parent)
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._handle = self._goCreator:Create(self._asset, self._parent, Delegate.GetOrCreate(self, self.OnAssetReady))
end

function UnitModel:Release()
    self._ready = false
    if Utils.IsNotNull(self._handle) then
        self._handle:Delete()
    end
    self._goCreator = nil
    self._animator = nil
    self._go = nil
    self._handle = nil
    self._animators = nil
    self._animatorCount = 0
end

---@param go CS.UnityEngine.GameObject
---@param userData CS.System.Object
function UnitModel:OnAssetReady(go, userData)
    if Utils.IsNull(go) then 
        g_Logger.Error("nil Asset : %s", self._asset) 
        return
    end
    go:SetVisible(not self._isHide)
    self._go = go
    go.transform:SetParent(self._parent, false)
    if not string.IsNullOrEmpty(self._overrideLayerName) then
        self._go:SetLayerRecursively(self._overrideLayerName)
        self._overrideLayerName = nil
    end
    local animators = go:GetComponentsInChildren(typeof(CS.UnityEngine.Animator), true)
    self._animators = {}
    for i = 0, animators.Length - 1 do
        table.insert(self._animators, animators[i])
        if i == 0 then
            self._animator = animators[0]
        end
    end
    self._animatorCount = #self._animators

    self._ready = true
    if self._readyCallback then
        local call = self._readyCallback
        self._readyCallback = nil
        call(self)
    end
end

---@param trans CS.UnityEngine.Transform
function UnitModel:SetParent(trans)
    self._parent = trans
    if self._go and self._go.transform.parent ~= trans then
        self._go.transform:SetParent(trans, true)
    end
end

---@param layerName string
function UnitModel:SetGoLayer(layerName)
    if Utils.IsNull(self._go) then
        self._overrideLayerName = layerName
    else
        self._go:SetLayerRecursively(layerName)
    end
end

---@return CS.UnityEngine.Animator
function UnitModel:Animator()
    return self._animator
end

function UnitModel:Animators()
    return self._animators
end

function UnitModel:AnimatorCount()
    return self._animatorCount
end

function UnitModel:SetScale(scale)
    self._go.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
end

function UnitModel:Transform()
    if Utils.IsNull(self._go) then
        return nil
    end
    return self._go.transform
end

---@param position CS.UnityEngine.Vector3
---@param direction CS.UnityEngine.Quaternion
function UnitModel:SetWorldPositionAndDir(position, direction)
    if position and direction then
        self._go.transform:SetPositionAndRotation(position, direction)
    elseif position then
        self._go.transform.position = position
    elseif direction then
        self._go.transform.rotation = direction
    end
end

function UnitModel:SetHide(isHide)
    self._isHide = isHide
    if Utils.IsNotNull(self._go) then
        self._go:SetVisible(not isHide)
    end
end

return UnitModel