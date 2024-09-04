local CityStateDefault = require("CityStateDefault")
local CityConst = require("CityConst")
---@class CityStateBuildingSelect:CityStateDefault
---@field new fun():CityStateBuildingSelect
---@field cellTile CityCellTile|nil
local CityStateBuildingSelect = class("CityStateBuildingSelect", CityStateDefault)
local ConfigRefer = require("ConfigRefer")
local CityUtils = require("CityUtils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CastleBuildingActivateParameter = require("CastleBuildingActivateParameter")
local UIMediatorNames = require("UIMediatorNames")
--local TDEnvironment = require("TDEnvironment")

function CityStateBuildingSelect:Enter()
    CityStateDefault.Enter(self)
    self.cellTile = self.stateMachine:ReadBlackboard("building", true)

    if self.cellTile and CityUtils.IsStatusWaitRibbonCutting(self.cellTile:GetCastleBuildingInfo().Status) then
        self.city:RibbonCut(self.cellTile:GetCell().tileId)
        self:ExitToIdleState()
        return
    end

    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self.cellTile:SetSelected(true)
    -- local tdInstance = TDEnvironment.Instance()
    -- if tdInstance then
    --     tdInstance:HighlightUnitFromTile(self.cellTile, true)
    -- end

    self:OpenUI()
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingActivateParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRibbonCut))
    g_Game.EventManager:AddListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_UPGRADE_BUILDING_UI_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
end

function CityStateBuildingSelect:ReEnter()
    self:Exit()
    self:Enter()
end

function CityStateBuildingSelect:Exit()
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_UPGRADE_BUILDING_UI_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingActivateParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRibbonCut))
    self:DeleteSelector()
    self:CloseUI()
    self.cellTile:SetSelected(false)
    -- local tdInstance = TDEnvironment.Instance()
    -- if tdInstance then
    --     tdInstance:HighlightUnitFromTile(self.cellTile, false)
    -- end
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    self.cellTile = nil
    self.runtimeId = nil
    CityStateDefault.Exit(self)
end

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
---@return boolean 返回true时不渗透Click
function CityStateBuildingSelect:OnClickTrigger(trigger, position)
    local x,y = trigger:GetOwnerPos()
    if x ~= self.cellTile.x or y ~= self.cellTile.y then
        self:ExitToIdleState()
        return true
    end

    return CityStateDefault.OnClickTrigger(self, trigger, position)
end

---@param cellTile CityCellTile
function CityStateBuildingSelect:OnClickCellTile(cellTile)
    if self.cellTile == cellTile then
        return true
    end

    return CityStateDefault.OnClickCellTile(self, cellTile)
end

function CityStateBuildingSelect:OnCameraSizeChanged(oldValue, newValue)
    self:TryChangeToAirView(oldValue, newValue)
end

function CityStateBuildingSelect:OpenUI()
    local buildingInfo = self.cellTile:GetCastleBuildingInfo()
    if buildingInfo == nil then
        g_Logger.Error(("找不到建筑数据 at X:%d, Y:%d"):format(self.cellTile.x, self.cellTile.y))
        return
    end
    local gridCell = self.cellTile:GetCell()
    local levelCell = ConfigRefer.BuildingLevel:Find(gridCell.configId)
    if levelCell == nil then
        g_Logger.Error(("读不到建筑配置, configId:%d"):format(gridCell.configId))
        return
    end

    local typeCell = ConfigRefer.BuildingTypes:Find(levelCell:Type())
    if typeCell == nil then
        g_Logger.Error(("读不到建筑配置, configId:%d"):format(gridCell.configId))
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.CityBuildUpgradeUIMediator, {cellTile = self.cellTile})
end

function CityStateBuildingSelect:CloseUI()
    g_Game.UIManager:CloseByName(UIMediatorNames.CityBuildUpgradeUIMediator)
end

---Obsolete
function CityStateBuildingSelect:CreateSelector()
    self.handler = self.city.createHelper:Create(self.cellTile:GetSelectorPrefabName(), self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnSelectorCreated), nil, 1000, true)
end

function CityStateBuildingSelect:DeleteSelector()
    if self.handler then
        self.city.createHelper:Delete(self.handler)
        self.handler = nil
    end
    self.selector = nil
end

---@param go CS.UnityEngine.GameObject
function CityStateBuildingSelect:OnSelectorCreated(go, userdata)
    if go == nil then
        g_Logger.Error("Load city_map_building_selector failed!")
        return
    end

    local cell = self.cellTile:GetCell()
    ---@type CityBuildingSelector
    self.selector = go:GetLuaBehaviour("CityBuildingSelector").Instance
    self.selector:Init(self.city, cell.x, cell.y, cell.sizeX, cell.sizeY, cell)
end

function CityStateBuildingSelect:OnRibbonCut(isSuccess, rsp)
    if isSuccess then
        self:ExitToIdleState()
    end
end

return CityStateBuildingSelect
