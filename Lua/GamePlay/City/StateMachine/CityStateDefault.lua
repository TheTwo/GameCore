local CityState = require("CityState")
---@class CityStateDefault:CityState
---@field new fun():CityStateDefault
local CityStateDefault = class("CityStateDefault", CityState)
local CityConst = require("CityConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityUtils = require("CityUtils")
local EventConst = require("EventConst")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local CityFurnitureTile = require("CityFurnitureTile")
local CityCitizenDefine = require("CityCitizenDefine")
local CreepStatus = require("CreepStatus")
local CityZoneStatus = require("CityZoneStatus")
local CityCellTile = require("CityCellTile")
local CityLegoBuildingTile = require("CityLegoBuildingTile")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local NpcServiceObjectType = require("NpcServiceObjectType")
local CityStateHelper = require("CityStateHelper")

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
---@return boolean 返回true时不渗透Click
function CityStateDefault:OnClickTrigger(trigger, position)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)

    --- 如果Trigger所属的地块本身阻止了Trigger的触发
    if trigger:IsTileBlockExecute() then
        return false
    end

    --- 判断Trigger自身归属坐标是否不在迷雾中
    local x, y = trigger:GetOwnerPos()
    if x and y and self.city.gridConfig:IsLocationValid(x, y) then
        if self.city.zoneManager then
            local zone = self.city.zoneManager:GetZone(x, y)
            --- 该坐标没有被划入任何zone则为非法对象
            if not zone then
                return true
            end
            local hitPoint = self.city:GetCenterPlanePositionFromCoord(x, y, 1, 1)
            if self:OnClickZone(zone, hitPoint) then
                return true
            end
        end
    end

    --- Trigger所属地块本身受污染
    if trigger:IsTilePolluted() then
        local x, y = self:GetClosestPollutedCoord(trigger:GetTile())
        if x > 0 and y > 0 then
            self:TryShowCreepToast(x, y)
            return self:OnClickCreep(x, y)
        end
    end
    
    return trigger:ExecuteOnClick()
end

function CityStateDefault:OnClick(gesture)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
    local count, x, y, hitPoint, furTile, cellTile, legoTile, safeWallFurTile = self.city:RaycastAnyTileBase(gesture.position)
    if x and y and hitPoint and self.city.gridConfig:IsLocationValid(x, y) then
        if self.city.zoneManager then
            local zone = self.city.zoneManager:GetZone(x, y)
            if not zone then
                return true
            end
            if self:OnClickZone(zone, hitPoint) then
                return true
            end
        end
    end

    if furTile and furTile:IsPolluted() then
        local x1, y1 = self:GetClosestPollutedCoord(furTile)
        if x1 > 0 and y1 > 0 then
            self:TryShowCreepToast(x1, y1)
            return self:OnClickCreep(x1, y1)
        end
    end

    if cellTile and cellTile:IsPolluted() then
        local x1, y1 = self:GetClosestPollutedCoord(cellTile)
        if x1 > 0 and y1 > 0 then
            self:TryShowCreepToast(x1, y1)
            return self:OnClickCreep(x1, y1)
        end
    end

    if self.city.creepManager:IsAffect(x, y) then
        return self:OnClickCreep(x, y)
    end

    local isGeneratingRes = self.city.gridLayer:IsGeneratingRes(x, y)
    if legoTile and not self.city.roofHide then
        return self:OnClickLegoBuilding(x, y)
    elseif furTile then
        return self:OnClickFurnitureTile(furTile)
    elseif cellTile then
        return self:OnClickCellTile(cellTile)
    elseif legoTile then
        return self:OnClickLegoBuilding(x, y)
    elseif isGeneratingRes then
        return self:OnClickGeneratingRes(x, y)
    elseif safeWallFurTile then
        return self:OnClickFurnitureTile(safeWallFurTile)
    else
        return self:OnClickEmpty(x, y)
    end
end

---@param cellTile CityCellTile
function CityStateDefault:OnClickCellTile(cellTile)
    local gridCell = cellTile:GetCell()
    if gridCell:IsBuilding() then
        local buildingInfo = cellTile:GetCastleBuildingInfo()
        if buildingInfo.Level == 1 and CityUtils.IsRepairing(buildingInfo.Status) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_upgrade_lv1_tips"))
        else
            self.stateMachine:WriteBlackboard("building", cellTile)
            self.stateMachine:ChangeState(CityConst.STATE_BUILDING_SELECT)
        end
        return true
    else
        if gridCell:IsNpc() then
            g_Logger.Log("Click Npc:%d", gridCell.tileId)
            local city = cellTile:GetCity()
            local cell = cellTile:GetCell()
            local elementCfg = ConfigRefer.CityElementData:Find(cell.tileId)
            local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
            if npcCfg:NoInteractable() then
                return false
            end
            if npcCfg:FinalNoInteractable() then
                local player = ModuleRefer.PlayerModule:GetPlayer()
                if player then
                    local npc = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[cell.tileId]
                    if npc and ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npc, true) then
                        return false
                    end
                end 
            end
            local elePos = elementCfg:Pos()
            local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcCfg)--CityUtils.SuggestCellCenterPositionWithHeight(city, cell, 0, true)

            ---@type ClickNpcEventContext
            local context = {}
            context.cityUid = city.uid
            context.elementConfigID = cell.tileId
            context.targetPos = pos
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
            return true
        elseif gridCell:IsCreepNode() then
            local city = cellTile:GetCity()
            local cell = cellTile:GetCell()
            local pos = CityUtils.SuggestCellCenterPositionWithHeight(city, cell, 0)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_CREEP_CLICK, city.uid, cell.tileId, pos)
            return true
        elseif gridCell:IsResource() then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_CLICK_RESOURCE, self.city, gridCell.tileId)
            return true
        end
    end
end

---@param furnitureTile CityTileBase|CityFurnitureTile
function CityStateDefault:OnClickFurnitureTile(furnitureTile)
    if furnitureTile and furnitureTile:IsPolluted() then
        local x1, y1 = self:GetClosestPollutedCoord(furnitureTile)
        if x1 > 0 and y1 > 0 then
            self:TryShowCreepToast(x1, y1)
            return self:OnClickCreep(x1, y1)
        end
    end

    if furnitureTile and furnitureTile:is(CityFurnitureTile) then
        local typeId = furnitureTile:GetFurnitureType()
        if typeId and CityCitizenDefine.IsFarmlandFurniture(typeId) then
            self.stateMachine:WriteBlackboard("furniture", furnitureTile)
            self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_FARMLAND_SELECT)
            return true
        end
    end

    if furnitureTile:IsConfigUnclickable() then
        return false
    end

    if furnitureTile:GetCell():GetCastleFurniture().Locked then
        local has, _ = ModuleRefer.PlayerServiceModule:HasInteractableServiceOnObject(NpcServiceObjectType.Furniture, furnitureTile:GetCell().singleId)
        if has then
            return furnitureTile:GetCell():RequestToRepair()
        end
    end

    self.stateMachine:WriteBlackboard("furniture", furnitureTile)
    self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_SELECT)
    return true
end

function CityStateDefault:OnClickCreep(x, y)
    self.stateMachine:WriteBlackboard("x", x)
    self.stateMachine:WriteBlackboard("y", y)
    self.stateMachine:ChangeState(CityConst.STATE_CLEAR_CREEP)
    return true
end

function CityStateDefault:OnClickGeneratingRes()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_resource_tree_growing"))
    return true
end

function CityStateDefault:OnClickEmpty(x, y)    
    ModuleRefer.SlgModule:SelectAndOpenTroopMenu(nil)
    if self.city.safeAreaWallMgr:IsSafeAreaWall(x, y)
            and self.city.safeAreaWallMgr:IsSafeAreaWallBroken(x, y)
            and self.city.safeAreaWallMgr:IsSafeAreaWallOrDoorAbilityValid(x, y)
    then
        if self.city:IsMyCity() then
            self.city:EnterRepairSafeAreaWallOrDoorState(x, y)
        end
    else
        self:ExitToIdleState()
    end
    return true
end

function CityStateDefault:TryShowCreepToast(x, y)
    CityStateHelper.TryShowCreepToast(self, x, y)
end

---@param tile CityTileBase|CityStaticObjectTile
function CityStateDefault:GetClosestPollutedCoord(tile)
    return CityStateHelper.GetClosestPollutedCoord(self, tile)
end

function CityStateDefault:ShowMoveArrowUI()
    if self.arrowUIRumtimeId then return end
    if self.pressTile then
        local param = {
            camera = self.city:GetCamera(),
            worldPos = CityUtils.GetCityCellCenterPos(self.city, self.pressTile:GetCell()),
            duration = CityConst.CITY_PRESS_DURATION,
        }
        self.arrowUIRumtimeId = g_Game.UIManager:Open(UIMediatorNames.CityMovingBuildingArrowUIMediator, param)
    end
end

function CityStateDefault:CloseMoveArrowUI()
    if self.arrowUIRumtimeId then
        g_Game.UIManager:Close(self.arrowUIRumtimeId)
        self.arrowUIRumtimeId = nil
    end
end

---@param trigger CityTrigger
function CityStateDefault:OnPressDown(gesture, trigger)
    if trigger then
        if trigger:Pressable() then
            self.pressTile = trigger:GetTile()
            self.pressTrigger = trigger
            self.pressTrigger:ExecuteOnPressDown()
            self.pressing = true
        end
    else

        local count, x, y, point, furTile, cellTile, legoTile = self.city:RaycastAnyTileBase(gesture.position)
        if count == 0 then return end
        if furTile then
            self.pressTile = furTile
            self:OnPressDownFurnitureTile(self.pressTile)
        elseif cellTile then
            self.pressTile = cellTile
            self:OnPressDownCellTile(self.pressTile)
        elseif legoTile then
            self.pressTile = legoTile
            self:OnPressDownLegoTile(self.pressTile)
        end
        self.pressing = true
    end
end

---@param tile CityCellTile
function CityStateDefault:OnPressDownCellTile(tile)
    if tile then
        self.pressStartTime = g_Game.RealTime.realtimeSinceStartup
    end
end

---@param tile CityFurnitureTile
function CityStateDefault:OnPressDownFurnitureTile(tile)
    if tile then
        self.pressStartTime = g_Game.RealTime.realtimeSinceStartup
    end
end

---@param tile CityLegoBuildingTile
function CityStateDefault:OnPressDownLegoTile(tile)
    if tile then
        self.pressStartTime = g_Game.RealTime.realtimeSinceStartup
    end
end

---@param trigger CityTrigger
function CityStateDefault:OnPressTrigger(trigger)
    if not trigger:Pressable() then
        return true
    end

    --- 如果Trigger所属的地块本身阻止了Trigger的触发
    if trigger:IsTileBlockExecute() then
        return false
    end

    --- 判断Trigger自身归属坐标是否不在迷雾中
    local x, y = trigger:GetOwnerPos()
    if x and y and self.city.gridConfig:IsLocationValid(x, y) then
        if self.city.zoneManager then
            local zone = self.city.zoneManager:GetZone(x, y)
            --- 该坐标没有被划入任何zone则为非法对象
            if not zone then
                return true
            end

            if zone.status ~= CityZoneStatus.Recovered then
                return true
            end
        end
    end

    --- Trigger所属地块本身受污染
    if trigger:IsTilePolluted() then
        return true
    end

    return trigger:ExecuteOnPress()
end

function CityStateDefault:OnPress(gesture)
    if not self.pressing then return end
    if not self.pressTile then return end

    local x, y = self.pressTile.x, self.pressTile.y
    if not x or not y then
        self.pressTile = nil
        self.pressing = false
        return
    end
    if self.city.zoneManager then
        local zone = self.city.zoneManager:GetZone(x, y)
        if not zone then return end
        if zone.status ~= CityZoneStatus.Recovered then return end
    end

    if self.pressTile:IsPolluted() then return end
    if self.pressTile:is(CityCellTile) then
        self:OnPressCellTile(self.pressTile)
    elseif self.pressTile:is(CityFurnitureTile) then
        self:OnPressFurnitureTile(self.pressTile)
    elseif self.pressTile:is(CityLegoBuildingTile) then
        self:OnPressLegoTile(self.pressTile)
    end
end

---@param tile CityCellTile
function CityStateDefault:OnPressCellTile(tile)
    if not self.pressing then return false end
	if not self.pressStartTime then return false end
    
    if self.pressStartTime + CityConst.CITY_PRESS_DELAY < g_Game.RealTime.realtimeSinceStartup then
        if not tile:Moveable() then
            local toast = tile:GetNotMovableReason()
            if not string.IsNullOrEmpty(toast) then
                ModuleRefer.ToastModule:AddSimpleToast(toast)
            end
            self.pressing = false
            return false
        end
        self:ShowMoveArrowUI()
    end

    if not tile:Moveable() then return false end

    if self.pressStartTime + CityConst.CITY_PRESS_DURATION + CityConst.CITY_PRESS_DELAY < g_Game.RealTime.realtimeSinceStartup then
        self.stateMachine:WriteBlackboard("MovingCell", tile)
        self.stateMachine:WriteBlackboard("RelativeFurniture", self.city:GetRelativeFurnitureTile(tile))
        self.stateMachine:WriteBlackboard("DragImmediate", true)
        self.stateMachine:ChangeState(CityConst.STATE_BUILDING_MOVING)
        self:CloseMoveArrowUI()
    end
    return true
end

---@param tile CityFurnitureTile
function CityStateDefault:OnPressFurnitureTile(tile)
    if not self.pressing then return false end
    if not self.pressStartTime then return false end
    if not tile:IsConfigMovable() then return false end
        
    if self.pressStartTime + CityConst.CITY_PRESS_DELAY < g_Game.RealTime.realtimeSinceStartup then
        if not tile:Moveable() then
            local toast = tile:GetNotMovableReason()
            if not string.IsNullOrEmpty(toast) then
                ModuleRefer.ToastModule:AddSimpleToast(toast)
            end
            self.pressing = false
            self.pressStartTime = nil
            return false
        end
        self:ShowMoveArrowUI()
    end

    if self.pressStartTime + CityConst.CITY_PRESS_DURATION + CityConst.CITY_PRESS_DELAY < g_Game.RealTime.realtimeSinceStartup then
        self.stateMachine:WriteBlackboard("MovingFurnitureCell", tile)
        self.stateMachine:WriteBlackboard("DragImmediate", true)
        self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_MOVING)
        self:CloseMoveArrowUI()
    end
    return true
end

---@param tile CityLegoBuildingTile
function CityStateDefault:OnPressLegoTile(tile)
    if not self.pressing then return false end
    if not self.pressStartTime then return false end

    if self.pressStartTime + CityConst.CITY_PRESS_DELAY < g_Game.RealTime.realtimeSinceStartup then
        if not tile:Movable() then
            local toast = tile:GetNotMovableReason()
            if not string.IsNullOrEmpty(toast) then
                ModuleRefer.ToastModule:AddSimpleToast(toast)
            end
            self.pressing = false
            self.pressStartTime = nil
            return false
        end
        self:ShowMoveArrowUI()
    end

    if self.pressStartTime + CityConst.CITY_PRESS_DURATION + CityConst.CITY_PRESS_DELAY < g_Game.RealTime.realtimeSinceStartup then
        self.stateMachine:WriteBlackboard("legoBuilding", tile:GetCell())
        self.stateMachine:ChangeState(CityConst.STATE_MOVING_LEGO_BUILDING)
        self:CloseMoveArrowUI()
    end
    return true
end

---@param tile CityCellTile
function CityStateDefault:OnPressUpCellTile(tile)
    --- do nothing
end

---@param tile CityFurnitureTile
function CityStateDefault:OnPressUpFurnitureTile(tile)
    --- do nothing
end

function CityStateDefault:OnRelease()
    if self.pressTrigger then
        self.pressTrigger:ExecuteOnPressUp()
    end

    self.pressing = false
    self.pressTile = nil
    self.pressTrigger = nil
    self.pressStartTime = nil
    self:CloseMoveArrowUI()
end

function CityStateDefault:OnDragStart(gesture)
    self.pressing = false
    self:CloseMoveArrowUI()
end

function CityStateDefault:OnPinch(gesture)
    self.pressing = false
    self:CloseMoveArrowUI()
end

function CityStateDefault:Exit()
    if self.pressing then
        self:OnRelease()
    end
end

function CityStateDefault:OnClickLegoBuilding(x, y)
    local legoBuilding = self.city.legoManager:GetLegoBuildingAt(x, y)
    if legoBuilding == nil then
        return false
    end

    if legoBuilding.roomLocked then
        local has, npcServiceCfg = ModuleRefer.PlayerServiceModule:HasInteractableServiceOnObject(NpcServiceObjectType.Building, legoBuilding.id)
        if has then
            legoBuilding:RequestToUnlock()
        else
            self.stateMachine:WriteBlackboard("legoBuilding", legoBuilding)
            self.stateMachine:WriteBlackboard("npcServiceCfg", npcServiceCfg)
            self.stateMachine:ChangeState(CityConst.STATE_LOCKED_BUILDING_SELECT)
        end
        return true
    end

    --- 点击房间不再进入房间界面，必须要点到家具上
    -- local param = CityLegoBuildingUIParameter.new(self.city, legoBuilding)
    -- g_Game.UIManager:Open(UIMediatorNames.CityLegoBuildingUIMediator, param)
    return true
end

return CityStateDefault
