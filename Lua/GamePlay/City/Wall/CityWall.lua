---@class CityWall
---@field new fun(idx:number, number:number, isHorizontal:boolean, cfgId:number, building:CityBuilding):CityWall
---@field Asset CityTileAssetWall
local CityWall = class("CityWall")
local CityConst = require("CityConst")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")

---@param idx number
---@param number number
---@param isHorizontal boolean
---@param cfgId number
---@param building CityBuilding
function CityWall:ctor(idx, number, isHorizontal, cfgId, building)
    self.idx = idx
    self.number = number
    self.isHorizontal = isHorizontal
    self.cfgId = cfgId
    self.building = building
end

function CityWall:IsWall()
    return true
end

function CityWall:LocalX()
    return self.isHorizontal and self.number or self.idx
end

function CityWall:LocalY()
    return self.isHorizontal and self.idx or self.number
end

function CityWall:LocalCenterX()
    return self.isHorizontal and self.number + 0.5 or self.idx
end

function CityWall:LocalCenterY()
    return self.isHorizontal and self.idx or self.number + 0.5
end

function CityWall:WorldCenterX()
    return self.building.x + self:LocalCenterX()
end

function CityWall:WorldCenterY()
    return self.building.y + self:LocalCenterY()
end

---@return CS.UnityEngine.Quaternion
function CityWall:GetWorldRotation()
    return self.isHorizontal and CityConst.Quaternion[0] or CityConst.Quaternion[90]
end

function CityWall:GetWorldCenter()
    return self.building.mgr.city:GetWorldPositionFromCoord(self:WorldCenterX(), self:WorldCenterY())
end

function CityWall:GetPrefabName()
    local cfg = ConfigRefer.BuildingRoomWall:Find(self.cfgId)
    return ArtResourceUtils.GetItem(cfg:Model())
end

return CityWall