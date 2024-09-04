---@class CityDoor
---@field new fun(idx, number, length, isHorizontal, cfgId, building):CityDoor
---@field Asset CityTileAssetDoor
local CityDoor = class("CityDoor")
local CityConst = require("CityConst")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Delegate = require("Delegate")

---@param idx number
---@param number number
---@param length number
---@param cfgId number
---@param isHorizontal boolean
---@param building CityBuilding
function CityDoor:ctor(idx, number, length, cfgId, isHorizontal, building)
    self.idx = idx
    self.number = number
    self.length = length
    self.cfgId = cfgId
    self.isHorizontal = isHorizontal
    self.building = building
end

function CityDoor:IsWall()
    return false
end

function CityDoor:LocalX()
    return self.isHorizontal and self.number or self.idx
end

function CityDoor:LocalY()
    return self.isHorizontal and self.idx or self.number
end

function CityDoor:LocalCenterX()
    return self.isHorizontal and self.number + self.length / 2 or self.idx
end

function CityDoor:LocalCenterY()
    return self.isHorizontal and self.idx or self.number + self.length / 2
end

function CityDoor:WorldCenterX()
    return self.building.x + self:LocalCenterX()
end

function CityDoor:WorldCenterY()
    return self.building.y + self:LocalCenterY()
end

function CityDoor:GetWorldRotation()
    return self.isHorizontal and CityConst.Quaternion[0] or CityConst.Quaternion[90]
end

function CityDoor:GetWorldCenter()
    return self.building.mgr.city:GetWorldPositionFromCoord(self:WorldCenterX(), self:WorldCenterY())
end

function CityDoor:GetPrefabName()
    local cfg = ConfigRefer.BuildingRoomDoor:Find(self.cfgId)
    return ArtResourceUtils.GetItem(cfg:Model())
end

function CityDoor:OnCreated()
    local x = self.building.x + self:LocalX() + (self.isHorizontal and -0.5 or -1)
    local y = self.building.y + self:LocalY() + (self.isHorizontal and -1 or -0.5)
    local sizeX = self.isHorizontal and (self.length + 1) or 2
    local sizeY = self.isHorizontal and 2 or (self.length + 1)
    self.listener = self.building.mgr.city.unitMoveGridEventProvider:AddListener(x, y, sizeX, sizeY, Delegate.GetOrCreate(self, self.OnEnter), Delegate.GetOrCreate(self, self.OnExit))
end

function CityDoor:OnDestroy()
    self.building.mgr.city.unitMoveGridEventProvider:RemoveListener(self.listener)
    self.listener = nil
end

function CityDoor:OnEnter(x, y, listener)
    ---TODO:开门动画
end

function CityDoor:OnExit(x, y, listener)
    ---TODO:关门动画
end

return CityDoor