local CityState = require("CityState")
---@class CityStateRepairBlock:CityState
---@field new fun():CityStateRepairBlock
---@field cellTile CityCellTile
---@field cfg BuildingBlockConfigCell
local CityStateRepairBlock = class("CityStateRepairBlock", CityState)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local CityBuildingRepairBlockBaseDatum = require("CityBuildingRepairBlockBaseDatum")
local CityBuildingRepairBlockWallDatum = require("CityBuildingRepairBlockWallDatum")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local CityConst = require("CityConst")

function CityStateRepairBlock:Enter()
    CityState.Enter(self)
    self.cellTile = self.stateMachine:ReadBlackboard("cellTile")
    self.cfg = self.stateMachine:ReadBlackboard("cfg")
    self.wallIdx = self.stateMachine:ReadBlackboard("wallIdx")
    self.repairWall = self.wallIdx > 0

    self.building = self.city.buildingManager:GetBuilding(self.cellTile:GetCell().tileId)
    self.repairBlock = self.building:GetRepairBlockByCfgId(self.cfg:Id())

    self:CameraFocus()
    self:HideBottomHud()
    self:OpenUI()
    self:HighlightTarget()
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    g_Game.EventManager:AddListener(EventConst.UI_CITY_REPAIR_BLOCK_CLOSED, Delegate.GetOrCreate(self, self.OnUIClosed))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE)
end

function CityStateRepairBlock:Exit()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE)
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_REPAIR_BLOCK_CLOSED, Delegate.GetOrCreate(self, self.OnUIClosed))
    self:CloseUI()
    self:ShowBottomHud()
    self:CancelHighlight()

    self.building = nil
    self.repairBlock = nil

    self.cellTile = nil
    self.cfg = nil
    self.wallIdx = nil
    self.repairWall = nil
    CityState.Exit(self)
end

function CityStateRepairBlock:HideBottomHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
end

function CityStateRepairBlock:ShowBottomHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
end

function CityStateRepairBlock:OpenUI()
    local param = (self.repairWall
        and CityBuildingRepairBlockWallDatum.new(self.repairBlock, self.wallIdx)
        or CityBuildingRepairBlockBaseDatum.new(self.repairBlock))
    self.runtimeId = g_Game.UIManager:Open(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator, param)
end

function CityStateRepairBlock:CloseUI()
    if self.runtimeId then
        g_Game.UIManager:Close(self.runtimeId)
    end
    self.runtimeId = nil
end

function CityStateRepairBlock:OnUIClosed()
    self:ExitToIdleState()
end

function CityStateRepairBlock:CameraFocus()
    local city = self.city
    local camera = city:GetCamera()
    local center
    camera:ForceGiveUpTween()
    if self.repairWall then
        local wallCfg = self.repairBlock.cfg:RepairWalls(self.wallIdx)
        local x, y = self.building.x + self.repairBlock.cfg:X() + wallCfg:OffsetX(), self.building.y + self.repairBlock.cfg:Y() + wallCfg:OffsetY()
        center = city:GetWorldPositionFromCoord(x, y)
    else
        center = city:GetCenterWorldPositionFromCoord(self.repairBlock.x, self.repairBlock.y, self.repairBlock.sizeX, self.repairBlock.sizeY)
    end
    
    local viewport = camera.mainCamera:WorldToViewportPoint(center)
    if 0.15 <= viewport.x and viewport.x <= 0.85 and 0.15 <= viewport.y and viewport.y <= 0.85 then
        return
    end
    camera:ZoomToWithFocus(CityConst.CITY_NEAR_CAMERA_SIZE, CS.UnityEngine.Vector3(0.5, 0.35), center, 0.2)
end

function CityStateRepairBlock:HighlightTarget()
    if self.repairWall then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_WALL_HIGHLIGHT, self.repairBlock, self.wallIdx, true)
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_BASE_HIGHLIGHT, self.repairBlock, true)
    end
end

function CityStateRepairBlock:CancelHighlight()
    if self.repairWall then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_WALL_HIGHLIGHT, self.repairBlock, self.wallIdx, false)
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_BASE_HIGHLIGHT, self.repairBlock, false)
    end
end

return CityStateRepairBlock