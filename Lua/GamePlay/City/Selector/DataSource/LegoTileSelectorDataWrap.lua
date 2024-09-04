---@class LegoTileSelectorDataWrap
---@field new fun():LegoTileSelectorDataWrap
local LegoTileSelectorDataWrap = class("LegoTileSelectorDataWrap")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityGridLayerMask = require("CityGridLayerMask")

---@param legoBuilding CityLegoBuilding
function LegoTileSelectorDataWrap:ctor(x, y, sizeX, sizeY, legoBuilding)
    self.x, self.y = x, y
    self.sizeX, self.sizeY = sizeX, sizeY
    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.city
end

---@return number, number
function LegoTileSelectorDataWrap:GetPos()
    return self.x, self.y
end

---@return number, number
function LegoTileSelectorDataWrap:GetSize()
    return self.sizeX, self.sizeY
end

---@return boolean
function LegoTileSelectorDataWrap:Besides(x, y)
    return self.legoBuilding:Besides(x, y)
end

---@return boolean
function LegoTileSelectorDataWrap:IsMilitary()
    return false
end

---@param selector CityFurnitureSelector
function LegoTileSelectorDataWrap:AttachSelector(selector)
    self.selector = selector
end

function LegoTileSelectorDataWrap:DetachSelector()
    self.selector = nil
end

function LegoTileSelectorDataWrap:UpdatePosition(x, y)
    self.x, self.y = x, y
    if self.selector then
        local bottomLeftPos = self.selector.city:GetWorldPositionFromCoord(self.x, self.y)
        local centerPos = self.selector.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
        self.selector.transform.position = CS.UnityEngine.Vector3(bottomLeftPos.x, centerPos.y, bottomLeftPos.z)
        self.selector:UpdateData()
        self.selector.meshDrawer:UpdateAllColor(self.selector.data)
    end
end

function LegoTileSelectorDataWrap:GetSelectorBehaviourName()
    return "CityFurnitureSelector"
end

function LegoTileSelectorDataWrap:GetSelectorPrefabName()
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_map_building_selector)
end

function LegoTileSelectorDataWrap:UpdateData(data)
    local sizeX, sizeY = self:GetSize()
    for j = 0, sizeY - 1 do
        for i = 0, sizeX - 1 do
            local index = j * sizeX + i + 1
            local x, y = i + self.x, j + self.y

            if self:Besides(x, y) then
                data[index] = 1
                goto continue
            end

            local mask = self.city.gridLayer:Get(x, y)
            if CityGridLayerMask.IsPlaced(mask) then
                data[index] = 0
            elseif not self.city:IsLocationValidForConstruction(x, y) then
                data[index] = 0
            elseif not CityGridLayerMask.IsSafeArea(mask) then
                data[index] = 0
            elseif not self.city.safeAreaWallMgr:IsValidSafeArea(x, y) then
                data[index] = 0
            elseif self.city.creepManager:IsAffect(x, y) then
                data[index] = 0
            else
                data[index] = 1
            end

            ::continue::
        end
    end
end

return LegoTileSelectorDataWrap