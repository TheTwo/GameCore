local CityState = require("CityState")
---@class OtherCityStateNormal:CityState
---@field new fun():OtherCityStateNormal
local OtherCityStateNormal = class("OtherCityStateNormal", CityState)

local CityConst = require("CityConst")

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
function OtherCityStateNormal:OnClickTrigger(trigger, position)
    g_Logger.Log("点别人家的气泡干啥")
end

---@param gesture CS.DragonReborn.TapGesture
function OtherCityStateNormal:OnClick(gesture)
    local cellTile,x,y,hitPoint = self.city:RaycastCityCellTile(gesture.position)
    if x and y and hitPoint and self.city.gridConfig:IsLocationValid(x, y) then
        if self.city.zoneManager then
            local zone = self.city.zoneManager:GetZone(x, y)
            if not zone then
                return
            end
            if self:OnClickZone(zone, hitPoint) then
                return
            end
        end
    end
    if cellTile then
        self:OnClickCellTile(cellTile)
    else
        cellTile = self.city:RaycastFurnitureTile(gesture.position)
        if cellTile then
            self:OnClickFurnitureTile(cellTile)
        else
            self:OnClickEmpty(self.city:RaycastPostionOnPlane(gesture.position))
        end
    end
end

---@param zone CityZone
---@param hitPoint CS.UnityEngine.Vector3
---@return boolean @true - block click
function OtherCityStateNormal:OnClickZone(zone, hitPoint)
    return zone:NotExplore()
end

---@param cellTile CityCellTile
function OtherCityStateNormal:OnClickCellTile(cellTile)
    local gridCell = cellTile:GetCell()
    if gridCell:IsBuilding() then
        self.stateMachine:WriteBlackboard("building", cellTile)
        self.stateMachine:ChangeState(CityConst.STATE_BUILDING_SELECT)
    end
end

---@param furnitureTile CityFurnitureTile
function OtherCityStateNormal:OnClickFurnitureTile(furnitureTile)
    self.stateMachine:WriteBlackboard("furniture", furnitureTile)
    self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_SELECT)
end

---@param position CS.UnityEngine.Vector3
function OtherCityStateNormal:OnClickEmpty(position)
    
end

function OtherCityStateNormal:OnCameraSizeChanged(oldValue, newValue)
    local state = self.city:GetSuitableIdleState(newValue)
    if state ~= CityConst.STATE_NORMAL then
        self.stateMachine:ChangeState(state)
    end
end

return OtherCityStateNormal