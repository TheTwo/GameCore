---@class SelectorDataWrap
---@field new fun():SelectorDataWrap
local SelectorDataWrap = class("SelectorDataWrap")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityGridLayerMask = require("CityGridLayerMask")

---@param city City
---@param legoBuilding CityLegoBuilding
function SelectorDataWrap:ctor(city, x, y, sizeX, sizeY, direction, legoBuilding, dirSet)
    self.city = city
    self.x, self.y = x, y
    self.sizeX, self.sizeY = sizeX, sizeY
    self.direction = direction
    self.legoBuilding = legoBuilding

    if not dirSet or #dirSet == 0 then
        g_Logger.Error("SelectorDataWrap:ctor dirSet is nil or empty!")
        return
    end
    
    self.dirSet = dirSet
    self.dirIndex = 1
    for i, v in ipairs(self.dirSet) do
        if v == self.direction then
            self.dirIndex = i
            break
        end
    end
end

---@return number, number
function SelectorDataWrap:GetPos()
    return self.x, self.y
end

---@return number, number
function SelectorDataWrap:GetSize()
    return self.sizeX, self.sizeY
end

---@return boolean
function SelectorDataWrap:Besides(x, y)
    return false
end

---@return boolean
function SelectorDataWrap:IsMilitary()
    return false
end

---@param selector CityFurnitureSelector
function SelectorDataWrap:AttachSelector(selector)
    self.selector = selector
end

function SelectorDataWrap:DetachSelector()
    self.selector = nil
end

function SelectorDataWrap:UpdatePosition(x, y)
    self.x, self.y = x, y
    if self.selector then
        local bottomLeftPos = self.selector.city:GetWorldPositionFromCoord(self.x, self.y)
        local centerPos = self.selector.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
        self.selector.transform.position = CS.UnityEngine.Vector3(bottomLeftPos.x, centerPos.y, bottomLeftPos.z)
        self.selector:UpdateData()
        self.selector.meshDrawer:UpdateAllColor(self.selector.data)
    end
end

function SelectorDataWrap:Rotate(anticlockwise)
    if self:RotateImp(anticlockwise) and self.selector ~= nil then
        local bottomLeftPos = self.selector.city:GetWorldPositionFromCoord(self.x, self.y)
        local centerPos = self.selector.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
        self.selector.transform.position = CS.UnityEngine.Vector3(bottomLeftPos.x, centerPos.y, bottomLeftPos.z)
        self.selector:UpdateData()
        self.selector:InitMesh()
        if self.selector.showArrow then
            self.selector:InitArrowPos(self.sizeX, self.sizeY)
        end
    end
end

function SelectorDataWrap:RotateImp(anticlockwise)
    if self.dirIndex == nil then
        if anticlockwise then
            self.direction = (self.direction - 90) % 360
        else
            self.direction = (self.direction + 90) % 360
        end
    else
        if anticlockwise then
            self.dirIndex = self.dirIndex - 1
            if self.dirIndex < 1 then
                self.dirIndex = #self.dirSet
            end
        else
            self.dirIndex = self.dirIndex + 1
            if self.dirIndex > #self.dirSet then
                self.dirIndex = 1
            end
        end
        self.direction = self.dirSet[self.dirIndex]
    end

    ---长宽不等时需要调整 curX, curY, sizeX, sizeY
    if self.sizeX ~= self.sizeY then
        local offsetX = self.sizeX / 2 - self.sizeY / 2
        local offsetY = self.sizeY / 2 - self.sizeX / 2
        self.x = math.floor(math.abs(offsetX)) * math.sign(offsetX) + self.x
        self.y = math.floor(math.abs(offsetY)) * math.sign(offsetY) + self.y

        self.sizeX, self.sizeY = self.sizeY, self.sizeX
        return true
    end
    return false
end

function SelectorDataWrap:GetSelectorBehaviourName()
    return "CityFurnitureSelector"
end

function SelectorDataWrap:GetSelectorPrefabName()
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_map_building_selector)
end

---@return boolean, boolean @是否可以放室内，是否可以放室外
function SelectorDataWrap:GetFurniturePlaceType()
    return true, true
end

---@return number @CityFurnitureTypes-Id
function SelectorDataWrap:GetFurnitureTypeCfgId()
    return 0
end

---@return number @1可以，0不可以
function SelectorDataWrap:CanPlaceAt(x, y)
    if self.legoBuilding == nil then return 1 end

    return self.legoBuilding.floorPosMap:Contains(x, y) and 1 or 0
end

function SelectorDataWrap:UpdateData(data)
    local sizeX, sizeY = self:GetSize()
    local canInLego, canOutLego = self:GetFurniturePlaceType()
    local furnitureType = self:GetFurnitureTypeCfgId()
    local inLego, outLego = 0, 0
    for j = 0, sizeY - 1 do
        for i = 0, sizeX - 1 do
            local index = j * sizeX + i + 1
            local x, y = i + self.x, j + self.y
            local isInLego = self.city:IsInLego(x, y)
            if isInLego then
                inLego = inLego + 1
            else
                outLego = outLego + 1
            end

            if not canInLego and isInLego or not canOutLego and not isInLego then
                data[index] = 0
                goto continue
            end

            if isInLego then
                local legoBuilding = self.city.legoManager:GetLegoBuildingAt(x, y)
                if legoBuilding ~= nil and legoBuilding.blackTypeMap[furnitureType] then
                    data[index] = 0
                    goto continue
                end
            end

            if self:Besides(x, y) then
                data[index] = 1
                goto continue
            end

            local mask = self.city.gridLayer:Get(x, y)
            if not CityGridLayerMask.CanPlaceFurniture(mask) then
                data[index] = 0
            elseif not CityGridLayerMask.IsSafeArea(mask) then
                data[index] = 0
            elseif not isInLego and not self.city.safeAreaWallMgr:IsValidSafeArea(x, y) then
                data[index] = 0
            elseif self.city.creepManager:IsAffect(x, y) then
                data[index] = 0
            elseif self.city:IsFogMask(x, y) then
                data[index] = 0
            else
                data[index] = self:CanPlaceAt(x, y)
            end

            ::continue::
        end
    end

    --- 如果室内块和室外块都有时，根据多的一方来决定另一种块是不可放置的颜色
    if inLego > 0 and outLego > 0 then
        for j = 0, sizeY - 1 do
            for i = 0, sizeX - 1 do
                local index = j * sizeX + i + 1
                local x, y = i + self.x, j + self.y
    
                local isInLego = self.city:IsInLego(x, y)
                if isInLego and outLego >= inLego then
                    data[index] = 0
                elseif not isInLego and outLego < inLego then
                    data[index] = 0
                end
            end
        end
    end
end

return SelectorDataWrap