local CityState = require("CityState")
---@class OtherCityStateBuildingSelect:CityState
---@field new fun():OtherCityStateBuildingSelect
local OtherCityStateBuildingSelect = class("OtherCityStateBuildingSelect", CityState)
local EventConst = require("EventConst")
local CityConst = require("CityConst")
local Delegate = require("Delegate")

function OtherCityStateBuildingSelect:Enter()
    CityState.Enter(self)
    self.cellTile = self.stateMachine:ReadBlackboard("building", true)
    self.cellTile:SetSelected(true)
    self:CreateSelector()
    g_Game.EventManager:AddListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.OnTouchInfoClose))
end

function OtherCityStateBuildingSelect:ReEnter()
    self:Exit()
    self:Enter()
end

function OtherCityStateBuildingSelect:Exit()
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.OnTouchInfoClose))
    self:DeleteSelector()
    self.cellTile:SetSelected(false)
    self.cellTile = nil
    CityState.Exit(self)
end

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
function OtherCityStateBuildingSelect:OnClickTrigger(trigger, position)
    g_Logger.Log("点别人家的气泡干啥")
end

---@param gesture CS.DragonReborn.TapGesture
function OtherCityStateBuildingSelect:OnClick(gesture)
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
function OtherCityStateBuildingSelect:OnClickZone(zone, hitPoint)
    return zone:NotExplore()
end

---@param cellTile CityCellTile
function OtherCityStateBuildingSelect:OnClickCellTile(cellTile)
    local gridCell = cellTile:GetCell()
    if gridCell:IsBuilding() then
        self.stateMachine:WriteBlackboard("building", cellTile)
        self.stateMachine:ChangeState(CityConst.STATE_BUILDING_SELECT)
    end
end

---@param furnitureTile CityFurnitureTile
function OtherCityStateBuildingSelect:OnClickFurnitureTile(furnitureTile)
    if self.cellTile == furnitureTile then return end

    self.stateMachine:WriteBlackboard("furniture", furnitureTile)
    self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_SELECT)
end

---@param position CS.UnityEngine.Vector3
function OtherCityStateBuildingSelect:OnClickEmpty(position)
    self.stateMachine:ChangeState(self.city:GetSuitableIdleState(self.city.cameraSize))
end

function OtherCityStateBuildingSelect:CreateSelector()
    self.handler = self.city.createHelper:Create(self.cellTile:GetSelectorPrefabName(), self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnSelectorCreated), nil, 0, true)
end

function OtherCityStateBuildingSelect:DeleteSelector()
    if self.handler then
        self.city.createHelper:Delete(self.handler)
        self.handler = nil
    end
    self.selector = nil
end

---@param go CS.UnityEngine.GameObject
function OtherCityStateBuildingSelect:OnSelectorCreated(go, userdata)
    if go == nil then
        g_Logger.Error("Load city_map_building_selector failed!")
        return
    end

    local cell = self.cellTile:GetCell()
    ---@type CityBuildingSelector
    self.selector = go:GetLuaBehaviour("CityBuildingSelector").Instance
    self.selector:Init(self.city, cell.x, cell.y, cell.sizeX, cell.sizeY, cell)
end

function OtherCityStateBuildingSelect:OnTouchInfoClose()
    self:ExitToIdleState()
end

function OtherCityStateBuildingSelect:OnCameraSizeChanged(oldValue, newValue)
    self:TryChangeToAirView(oldValue, newValue)
end

return OtherCityStateBuildingSelect