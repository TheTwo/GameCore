local Utils = require("Utils")
---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local Delegate = require("Delegate")

---@class SetPortraitCallBack
---@field new fun():SetPortraitCallBack
local SetPortraitCallBack = class('SetPortraitCallBack')

function SetPortraitCallBack:ctor()
    self._giveUp = false
    ---@type CS.UnityEngine.GameObject
    self._target = nil
    ---@type CS.UnityEngine.Vector3
    self._localScale = nil
    ---@type CS.UnityEngine.Vector2
    self._pivot = nil
    self._useFlipX = false
    ---@type CS.UnityEngine.UI.MaskableGraphic
    self._spineGraphic = nil
end

function SetPortraitCallBack:Release()
    self._color = nil
    self._spineGraphic = nil
    self._giveUp = true
    if Utils.IsNotNull(self._target) then
        GameObjectCreateHelper.DestroyGameObject(self._target)
    end
    self._target = nil
end

---@param spineInfo ArtResourceUIConfigCell
function SetPortraitCallBack:IsSameSpineInfo(spineInfo,  useFlipX)
    return spineInfo == self._spineInfo and useFlipX == self._useFlipX
end

---@return fun(g:CS.UnityEngine.GameObject)
function SetPortraitCallBack:GetCallBack()
    return Delegate.GetOrCreate(self, self.OnCallBack)
end

---@param g CS.UnityEngine.GameObject
function SetPortraitCallBack:OnCallBack(g)
    self._spineGraphic = nil
    if self._giveUp then
        if Utils.IsNotNull(g) then
            GameObjectCreateHelper.DestroyGameObject(g)
        end
        return
    end
    self._target = g
    if Utils.IsNotNull(self._target) then
        ---@type CS.UnityEngine.RectTransform
        local rectTrans = self._target:GetComponent(typeof(CS.UnityEngine.RectTransform))
        if Utils.IsNotNull(rectTrans) then
            if not self._pivot then
                self._pivot = CS.UnityEngine.Vector2(0.5, 0.5)
            end
            rectTrans.pivot = self._pivot
            if not self._localScale then
                self._localScale = CS.UnityEngine.Vector3.one
            end
            rectTrans.localScale = self._localScale
        else
            local trans = self._target.transform
            trans.localScale = self._localScale
        end
        ---@type CS.Spine.Unity.SkeletonGraphic
        local spineGraphic = self._target:GetComponentInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
        if Utils.IsNotNull(spineGraphic) then
            if spineGraphic.initialFlipX ~= self._useFlipX then
                spineGraphic.initialFlipX = self._useFlipX
                spineGraphic:Initialize(true)
            end
        end
        self._spineGraphic = self._target:GetComponentInChildren(typeof(CS.UnityEngine.UI.MaskableGraphic))
        if self._color then
            self._spineGraphic.color = self._color
        end
    end
end

---@param color CS.UnityEngine.Color
function SetPortraitCallBack:SetColor(color)
    self._color = color
    if Utils.IsNotNull(self._spineGraphic) then
        self._spineGraphic.color = color
    end
end

---@param spineInfo ArtResourceUIConfigCell
---@param useFlipX boolean
function SetPortraitCallBack:SetSpineInfo(spineInfo, useFlipX)
    self._spineInfo = spineInfo
    if spineInfo then
        if spineInfo:SpineScaleLength() > 1 then
            self._localScale = CS.UnityEngine.Vector3(spineInfo:SpineScale(1), spineInfo:SpineScale(2), 1)
        else
            self._localScale = CS.UnityEngine.Vector3.one
        end
        if spineInfo:SpinePivotLength() > 1 then
            self._pivot = CS.UnityEngine.Vector2(spineInfo:SpinePivot(1), spineInfo:SpinePivot(2))
        else
            self._pivot = CS.UnityEngine.Vector2(0.5, 0.5)
        end
    else
        self._localScale = CS.UnityEngine.Vector3.one
        self._pivot = CS.UnityEngine.Vector2(0.5, 0.5)
    end
    self._useFlipX = useFlipX
end

return SetPortraitCallBack