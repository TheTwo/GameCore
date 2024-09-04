local CityStateTileHandleDataWrap = require("CityStateTileHandleDataWrap")
---@class CityStateTileHandleCreateNewFurnitureData:CityStateTileHandleDataWrap
---@field new fun():CityStateTileHandleCreateNewFurnitureData
local CityStateTileHandleCreateNewFurnitureData = class("CityStateTileHandleCreateNewFurnitureData", CityStateTileHandleDataWrap)
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local FurnitureBuildSelectorDataWrap = require("FurnitureBuildSelectorDataWrap")
local Delegate = require("Delegate")
local Utils = require("Utils")
local CityConst = require("CityConst")

function CityStateTileHandleCreateNewFurnitureData:ctor(city, x, y, sizeX, sizeY, direction, lvCfgId, legoBuilding, dirSet)
    CityStateTileHandleDataWrap.ctor(self, city, x, y, sizeX, sizeY, direction, legoBuilding, dirSet)
    self.lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    self.typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCfg:Type())
    self.prefabName, self.scale = ArtResourceUtils.GetItemAndScale(self.lvCfg:Model())
    self.rotation = ArtResourceUtils.GetItem(self.lvCfg:Model(), "ModelRotation", 2) or 0
    if self.scale == 0 then
        self.scale = 1
    end
    if self.typCfg:RotationControl() == 90 then
        self.dirSet = {0, 90}
    elseif self.typCfg:RotationControl() == -90 then
        self.dirSet = {0, 270}
    else
        self.dirSet = {0, 90, 180, 270}
    end
end

function CityStateTileHandleCreateNewFurnitureData:GetSelectorDataWrap()
    return FurnitureBuildSelectorDataWrap.new(self.city, self.x, self.y, self.sizeX, self.sizeY, self.direction, self.lvCfg:Id(), self.legoBuilding, self.dirSet)
end

---@param handle CityStateTileHandle
function CityStateTileHandleCreateNewFurnitureData:OnHandleInitialize(handle)
    CityStateTileHandleDataWrap.OnHandleInitialize(self, handle)
    self:LoadModel()
end

---@param handle CityStateTileHandle
function CityStateTileHandleCreateNewFurnitureData:OnHandleRelease(handle)
    self:ReleaseModel()
    CityStateTileHandleDataWrap.OnHandleRelease(self, handle)
end

function CityStateTileHandleCreateNewFurnitureData:LoadModel()
    local createHelper = self.city.createHelper
    self.handle = createHelper:Create(self.prefabName, self.city:GetRoot().transform, Delegate.GetOrCreate(self, self.OnModelLoaded), nil, 0, true)
end

function CityStateTileHandleCreateNewFurnitureData:ReleaseModel()
    if self.handle == nil then return end
    if Utils.IsNotNull(self.go) then
        self.city.flashMatController:StopFlash(self.go)
    end

    self:OnReleasePreviewModelAnimator()
    local createHelper = self.city.createHelper
    createHelper:Delete(self.handle)
    self.handle = nil
    self.go = nil
    self.trans = nil
    self.targetAnimator = nil
end

function CityStateTileHandleCreateNewFurnitureData:OnModelLoaded(go, userdata, handle)
    if Utils.IsNull(go) then
        g_Logger.ErrorChannel("City", ("Load %s failed"):format(self.prefabName))
        self.city.stateMachine.currentState:ExitToIdleState()
        return
    end

    self.go = go
    self.go:SetLayerRecursively("City")
    self.trans = go.transform
    self.trans.localScale = CS.UnityEngine.Vector3.one * self.scale
    self:UpdatePosition(self.x, self.y)
    self.targetAnimator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator), true)
    if Utils.IsNotNull(self.targetAnimator) then
        self.targetAnimator.enabled = true
    end
    self:PreViewUpAni()
    self.city.flashMatController:StartFlash(go)
end

function CityStateTileHandleCreateNewFurnitureData:PreViewUpAni()
    if Utils.IsNotNull(self.targetAnimator) then
        if self.targetAnimator:HasParameter("work") then
            self.targetAnimator:SetBool("work", false)
        end
        if self.targetAnimator:HasParameter("work_fast") then
            self.targetAnimator:SetBool("work_fast", false)
        end
        if self.targetAnimator:HasParameter("up") then
            self.targetAnimator:SetBool("up", true)
        end
    end
end

function CityStateTileHandleCreateNewFurnitureData:OnReleasePreviewModelAnimator()
    if Utils.IsNotNull(self.targetAnimator) then
        if self.targetAnimator:HasParameter("work") then
            self.targetAnimator:SetBool("work", false)
        end
        if self.targetAnimator:HasParameter("work_fast") then
            self.targetAnimator:SetBool("work_fast", false)
        end
        if self.targetAnimator:HasParameter("up") then
            self.targetAnimator:SetBool("up", false)
        end
    end
    self.targetAnimator = nil
end

function CityStateTileHandleCreateNewFurnitureData:UpdatePosition(x, y, easeYAxis)
    CityStateTileHandleDataWrap.UpdatePosition(self, x, y, easeYAxis)
    if Utils.IsNotNull(self.trans) then
        local position = self.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY) + self.RiseOffset
        local rotation = CityConst.Quaternion[self.direction] * CS.UnityEngine.Quaternion.Euler(0, self.rotation, 0)
        self.trans:SetPositionAndRotation(position, rotation)
    end
end

function CityStateTileHandleCreateNewFurnitureData:Rotate(anticlockwise)
    CityStateTileHandleDataWrap.Rotate(self, anticlockwise)
    if Utils.IsNotNull(self.trans) then
        local position = self.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY) + self.RiseOffset
        local rotation = CityConst.Quaternion[self.direction] * CS.UnityEngine.Quaternion.Euler(0, self.rotation, 0)
        self.trans:SetPositionAndRotation(position, rotation)
    end
end

function CityStateTileHandleCreateNewFurnitureData:TileHandleType()
    return CityConst.TileHandleType.Furniture
end

function CityStateTileHandleCreateNewFurnitureData:FurnitureLevelCfgId()
    return self.lvCfg:Id()
end

return CityStateTileHandleCreateNewFurnitureData