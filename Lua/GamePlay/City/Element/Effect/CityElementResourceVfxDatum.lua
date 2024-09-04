---@class CityElementResourceVfxDatum
---@field new fun():CityElementResourceVfxDatum
local CityElementResourceVfxDatum = class("CityElementResourceVfxDatum")
local QuadTreeLeaf = require("QuadTreeLeaf")
local Delegate = require("Delegate")
local Utils = require("Utils")
local Vector3One = CS.UnityEngine.Vector3.one
local QuatIdentity = CS.UnityEngine.Quaternion.identity

---@param manager CityElementResourceVfxPlayManager
---@param go CS.UnityEngine.GameObject
---@param tile CityCellTile
function CityElementResourceVfxDatum:ctor(manager, go, tile)
    self.manager = manager
    self.go = go
    self.tile = tile

    self.playing = false
    local attachPointComp = self.go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNotNull(attachPointComp) then
        self.attachPoint = attachPointComp:GetAttachPoint(self.manager.attachPoint)
    else
        self.attachPoint = self.go.transform
    end
end

function CityElementResourceVfxDatum:PlayVfx()
    if self.handle then
        self.handle:Delete()
        self.manager:MarkPlay(self.handle, false)
    end

    self.handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    self.handle:Create(self.manager.vfxName,
        "city_element_hint_vfx",
        self.manager.city:GetRoot().transform,
        Delegate.GetOrCreate(self, self.OnVfxCreated),
        nil,
        0,
        false,
        false,
        Delegate.GetOrCreate(self, self.OnVfxDeleted)
    )
    self.manager:MarkPlay(self.handle, true)
end

function CityElementResourceVfxDatum:StopVfx()
    if self.handle then
        self.handle:Delete()
        self.manager:MarkPlay(self.handle, false)
    end
    self.handle = nil
end

---@param go CS.UnityEngine.GameObject
---@param handle CS.DragonReborn.VisualEffect.VisualEffectHandle
function CityElementResourceVfxDatum:OnVfxCreated(isSuccess, userdata, handle)
    if not isSuccess then return end

    local gameObject = handle.Effect.gameObject
    gameObject:SetLayerRecursively("City")
    local transform = gameObject.transform
    transform.localScale = Vector3One
    transform:SetPositionAndRotation(self.attachPoint.position, QuatIdentity)
end

function CityElementResourceVfxDatum:OnVfxDeleted()
    self.manager:MarkPlay(self.handle, false)
end

function CityElementResourceVfxDatum:ToQuadLeaf()
    return QuadTreeLeaf.new(self.tile:GetRect(), self)
end

function CityElementResourceVfxDatum:InScreen()
    if Utils.IsNull(self.attachPoint) then return false end

    local worldPosition = self.attachPoint.position
    local camera = self.manager.city:GetCamera().mainCamera
    local viewportPosition = camera:WorldToViewportPoint(worldPosition)
    local x, y = viewportPosition.x, viewportPosition.y
    return x >= 0 and x <= 1 and y >= 0 and y <= 1
end

function CityElementResourceVfxDatum:IsFogMask()
    return self.manager.city:IsFogMask(self.tile.x, self.tile.y)
end

return CityElementResourceVfxDatum