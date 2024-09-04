---@class CityLegoBlock
---@field new fun(legoBuilding, payload):CityLegoBlock
local CityLegoBlock = class("CityLegoBlock")
local Quaternion = CS.UnityEngine.Quaternion
local Vector3 = CS.UnityEngine.Vector3
local CityLegoAttachedDecoration = require("CityLegoAttachedDecoration")
local CityLegoDefine = require("CityLegoDefine")
local ConfigRefer = require("ConfigRefer")

---@param legoBuilding CityLegoBuilding
---@param payload LegoBlockInstanceConfigCell
function CityLegoBlock:ctor(legoBuilding, payload)
    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.manager.city
    self:UpdatePayload(payload)
end

---@param payload LegoBlockInstanceConfigCell
function CityLegoBlock:UpdatePayload(payload)
    local coord = payload:RelPos()
    self.x = coord:X() + self.legoBuilding.x
    self.y = coord:Y()
    self.z = coord:Z() + self.legoBuilding.z
    self.axisYRot = payload:Rotate()
    self.payload = payload
    self.filter = nil
    self.indoorDecorations = nil
    self.outsideDecorations = nil
end

function CityLegoBlock:UpdatePosition()
    if not self.payload then return end

    local coord = self.payload:RelPos()
    self.x = coord:X() + self.legoBuilding.x
    self.y = coord:Y()
    self.z = coord:Z() + self.legoBuilding.z
end

function CityLegoBlock:GetRotation()
    return Quaternion.Euler(0, self.axisYRot, 0)
end

function CityLegoBlock:GetCfgId()
    return self.payload:Type()
end

function CityLegoBlock:GetWorldPosition()
    return self.city:GetCenterWorldPositionFromCoord(self.x, self.z, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize) + (self.city.scale * self.y) * Vector3.up
end

function CityLegoBlock:GetWorldRotation()
    return Quaternion.Euler(0, self.axisYRot, 0)
end

function CityLegoBlock:GetDecorations(indoor)
    local filter = self:GetAttachPointFilter()
    if indoor then
        return self:GetIndoorDecorations(filter)
    else
        return self:GetOutsideDecorations(filter)
    end
end

function CityLegoBlock:HasIndoorPart()
    return self.payload:StyleIndoor() > 0
end

function CityLegoBlock:HasOutsidePart()
    return self.payload:StyleOutside() > 0
end

function CityLegoBlock:GetStyle(indoor)
    if indoor then
        return self.payload:StyleIndoor()
    else
        return self.payload:StyleOutside()
    end
end

---@private
function CityLegoBlock:GetAttachPointFilter()
    if self.filter == nil then
        local blockCfg = ConfigRefer.LegoBlock:Find(self:GetCfgId())
        self.filter = {}
        for i = 1, blockCfg:AttachPointLength() do
            local attachPointCfgId = blockCfg:AttachPoint(i)
            local attachPointCfg = ConfigRefer.LegoBlockAttachPoint:Find(attachPointCfgId)
            if attachPointCfg then
                self.filter[attachPointCfg:Name()] = attachPointCfg:Outside()
            end
        end
    end
    return self.filter
end

---@private
function CityLegoBlock:GetIndoorDecorations(filter)
    if self.indoorDecorations == nil then
        ---@type CityLegoAttachedDecoration[]
        self.indoorDecorations = {}
        for i = 1, self.payload:DecorationsLength() do
            local decorationCfg = self.payload:Decorations(i)
            local name = decorationCfg:AttachPoint()
            if not string.IsNullOrEmpty(name) and filter[name] == false then
                local decoration = CityLegoAttachedDecoration.new(self.legoBuilding, decorationCfg, self:GetCfgId())
                table.insert(self.indoorDecorations, decoration)
            end
        end
    end
    return self.indoorDecorations
end

---@private
function CityLegoBlock:GetOutsideDecorations(filter)
    if self.outsideDecorations == nil then
        ---@type CityLegoAttachedDecoration[]
        self.outsideDecorations = {}
        for i = 1, self.payload:DecorationsLength() do
            local decorationCfg = self.payload:Decorations(i)
            local name = decorationCfg:AttachPoint()
            if not string.IsNullOrEmpty(name) and filter[name] == true then
                local decoration = CityLegoAttachedDecoration.new(self.legoBuilding, decorationCfg, self:GetCfgId())
                table.insert(self.outsideDecorations, decoration)
            end
        end
    end
    return self.outsideDecorations
end

return CityLegoBlock