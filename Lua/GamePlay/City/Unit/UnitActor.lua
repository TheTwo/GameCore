local Delegate = require("Delegate")
local UnitModel = require("UnitModel")
local Vector2 = CS.UnityEngine.Vector2
local Utils = require("Utils")

---@class UnitActor
---@field new fun(id:number, type:UnitActorType):UnitActor
---@field id number
---@field type UnitActorType
---@field protected currentPosition CS.UnityEngine.Vector2
---@field protected currentDirection CS.UnityEngine.Vector2
---@field protected model UnitModel
local UnitActor = class('UnitActor')

---@param id number
---@param type UnitActorType
function UnitActor:ctor(id, type)
    self.id = id
    self.type = type
    self.currentPosition = Vector2.zero
    self.currentDirection = Vector2.zero
    self.model = nil
    self._assetReady = false
    ---@type CS.UnityEngine.Animator
    self._animator = nil
    ---@type CS.UnityEngine.Animator[]
    self._animators = nil
    self._animatorCount = 0
    self._isHide = false
    self._needSyncInfectionVfx = nil
end

---@param asset string
---@param creator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
function UnitActor:Init(asset, creator)
    self.model = UnitModel.new(asset, creator)
    if self.model then
        self.model:SetHide(self._isHide)
    end
end

function UnitActor:LoadModelAsync(parent)
    if self.model then
        self.model:InitAsync(parent, Delegate.GetOrCreate(self, self.WhenModelReady))
    end
end

function UnitActor:WhenModelReady(model)
    self._assetReady = true
    self._animator = self.model:Animator()
    self._animators = self.model:Animators()
    self._animatorCount = self.model:AnimatorCount()
end

function UnitActor:IsModelReady()
    return self.model and self.model:IsReady() and self._assetReady or false
end

function UnitActor:GetTransform()
    if self.model then
        return self.model:Transform()
    end
    return nil
end

function UnitActor:Tick(delta)

end

function UnitActor:Dispose()
    self._assetReady = false
    if self.model then
        self.model:Release()
    end
    self.model = nil
end

function UnitActor:SetIsHide(isHide)
    self._isHide = isHide
    if self.model then
        self.model:SetHide(isHide)
    end
end

return UnitActor