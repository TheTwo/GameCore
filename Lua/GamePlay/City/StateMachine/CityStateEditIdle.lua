local CityStateDefault = require("CityStateDefault")
---@class CityStateEditIdle:CityStateDefault
---@field new fun():CityStateEditIdle
local CityStateEditIdle = class("CityStateEditIdle", CityStateDefault)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local CityUtils = require("CityUtils")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityConst = require("CityConst")

function CityStateEditIdle:Enter()
    CityStateDefault.Enter(self)
    self.city:ShowMapGridView()
    self.city.camera.enablePinch = false
    
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToBuildingState))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToMovingState))
    g_Game.EventManager:AddListener(EventConst.CITY_ROOM_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToRoomBuildState))
    g_Game.EventManager:AddListener(EventConst.CITY_FLOOR_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToChangeFloorState))
    g_Game.EventManager:AddListener(EventConst.CITY_CHANGE_MOVING_LEGO_STATE, Delegate.GetOrCreate(self, self.OnChangeMovingLegoState))
    self.city:RefreshBorderParams()

    if self.city.enableMovingLego then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_SHOW_NAME, self.city)
    end
end

function CityStateEditIdle:Exit()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToBuildingState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToMovingState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ROOM_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToRoomBuildState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FLOOR_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToChangeFloorState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CHANGE_MOVING_LEGO_STATE, Delegate.GetOrCreate(self, self.OnChangeMovingLegoState))

    if self.city.camera then
        self.city.camera.enablePinch = true
    end
    self.city:HideMapGridView()
    self.city:RefreshBorderParams()
    CityStateDefault.Exit(self)
end

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
---@return boolean 返回true时不渗透Click
function CityStateEditIdle:OnClickTrigger(trigger, position)
    ---编辑模式下不响应任何气泡
    return false
end

---@param cellTile CityCellTile|CityFurnitureTile
function CityStateEditIdle:OnClickCellTile(cellTile)
    return false
end

---@param furnitureTile CityFurnitureTile
function CityStateEditIdle:OnClickFurnitureTile(furnitureTile)
    if furnitureTile:GetCastleFurniture().Polluted then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_polluted_cant_move", furnitureTile:GetName()))
        return true
    end

    if not furnitureTile:Moveable() then
        local toast = furnitureTile:GetNotMovableReason()
        if not string.IsNullOrEmpty(toast) then
            ModuleRefer.ToastModule:AddSimpleToast(toast)
        end
        return true
    end

    self.stateMachine:WriteBlackboard("MovingFurnitureCell", furnitureTile)
    self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_MOVING)
    return true
end

function CityStateEditIdle:OnClickEmpty(x, y)
    ---DO Nothing
end

function CityStateEditIdle:OnClickCreep(x, y)
    ---DO Nothing
end

function CityStateEditIdle:OnClickZone(zone, hitPoint)
    ---DO Nothing
end

function CityStateEditIdle:OnSelectToBuildingState(data, pos)
    if self.city and self.city:IsMyCity() and self.city:IsEditMode() then
        self.stateMachine:WriteBlackboard("data", data)
        self.stateMachine:WriteBlackboard("screenPos", pos)
        self.stateMachine:ChangeState(CityConst.STATE_BUILDING)
    end
end

function CityStateEditIdle:OnSelectToMovingState(furniture, pos)
    if self.city and self.city:IsMyCity() and self.city:IsEditMode() then
        local furTile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
        self.stateMachine:WriteBlackboard("MovingFurnitureCell", furTile)
        self.stateMachine:WriteBlackboard("screenPos", pos)
        self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_MOVING)
    end
end

function CityStateEditIdle:OnSelectToRoomBuildState(data, pos)
    if self.city:IsMyCity() and self.city:IsEditMode() then
        self.stateMachine:WriteBlackboard("data", data)
        self.stateMachine:WriteBlackboard("screenPos", pos)
        -- self.stateMachine:ChangeState(CityConst.STATE_ROOM_BUILDING)
    end
end

function CityStateEditIdle:OnSelectToChangeFloorState(data)
    if self.city:IsMyCity() and self.city:IsEditMode() then
        self.stateMachine:WriteBlackboard("data", data)
        self.stateMachine:ChangeState(CityConst.STATE_CHANGE_FLOOR)
    end
end

function CityStateEditIdle:OnChangeMovingLegoState(flag)
    if flag then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_SHOW_NAME, self.city)
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_HIDE_NAME, self.city)
    end
end

---@param legoTile CityLegoBuildingTile
function CityStateEditIdle:OnPressLegoTile(legoTile)
    if self.city.editBuilding ~= nil then return false end
    if not self.city.enableMovingLego then return false end

    return CityStateDefault.OnPressLegoTile(self, legoTile)
end

function CityStateEditIdle:OnClickLegoBuilding(x, y)
    if not self.city.enableMovingLego then
        return false
    end

    local legoBuilding = self.city.legoManager:GetLegoBuildingAt(x, y)
    if legoBuilding ~= nil then
        if legoBuilding:Movable() then
            self.stateMachine:WriteBlackboard("legoBuilding", legoBuilding, true)
            self.stateMachine:ChangeState(CityConst.STATE_MOVING_LEGO_BUILDING)
        else
            local toast = legoBuilding:GetNotMovableReason()
            if not string.IsNullOrEmpty(toast) then
                ModuleRefer.ToastModule:AddSimpleToast(toast)
            end
        end
    end
end

return CityStateEditIdle