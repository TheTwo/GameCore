local CityConst = require("CityConst")
local UIMediatorNames = require("UIMediatorNames")
local CityBuildingRepairSafeAreaBlockDatum = require("CityBuildingRepairSafeAreaBlockDatum")
local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local Delegate = require("Delegate")
local ModuleRefer = require('ModuleRefer')
local CityState = require("CityState")

---@class CityStateSafeAreaWallSelect:CityState
---@field new fun(city:City):CityStateSafeAreaWallSelect
---@field super CityState
local CityStateSafeAreaWallSelect = class('CityStateSafeAreaWallSelect', CityState)

function CityStateSafeAreaWallSelect:Enter()
    CityState.Enter(self)
    local x = self.stateMachine:ReadBlackboard("x")
    local y = self.stateMachine:ReadBlackboard("y")
    self._safeAreaWallMgr = self.city.safeAreaWallMgr
    self._wallId = self._safeAreaWallMgr:GetWallId(x, y)
    local match,centerGrid = self._safeAreaWallMgr:GetWallCenterGrid(self._wallId)
    self._wallCenter = match and centerGrid or nil
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self._safeAreaWallMgr:SelectWall(self._wallId)
    self:CameraFocus()
    self:OpenUI()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_REPAIR_BLOCK_CLOSED, Delegate.GetOrCreate(self, self.OnUIClosed))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE)
    self.tile = self._safeAreaWallMgr:GetTile(self._wallId)
    if self.tile then
        self.tile:SetSelected(true)
    end
end

function CityStateSafeAreaWallSelect:Exit()
    if self.tile  then
        self.tile:SetSelected(false)
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE)
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_REPAIR_BLOCK_CLOSED, Delegate.GetOrCreate(self, self.OnUIClosed))
    if self.runtimeId then
        g_Game.UIManager:Close(self.runtimeId)
    end
    self:ShowBottomHud()
    self.runtimeId = nil
    self._safeAreaWallMgr:SelectWall(nil)
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    CityState.Exit(self)
end

function CityStateSafeAreaWallSelect:OpenUI()
    self:HideBottomHud()
    local param = CityBuildingRepairSafeAreaBlockDatum.new()
    param:Setup(self.city, self._wallId)
    self.runtimeId = g_Game.UIManager:Open(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator, param)
end

function CityStateSafeAreaWallSelect:OnUIClosed()
    self:ExitToIdleState()
end

function CityStateSafeAreaWallSelect:CameraFocus()
    if ModuleRefer.GuideModule:GetGuideState() then
        return
    end
    if not self._wallCenter then
        return
    end
    local city = self.city
    local camera = city:GetCamera()
    camera:ForceGiveUpTween()
    local center = city:GetCenterWorldPositionFromCoord(self._wallCenter.x, self._wallCenter.y, 1, 1)
    camera:ZoomToWithFocus(CityConst.CITY_NEAR_CAMERA_SIZE, CS.UnityEngine.Vector3(0.5, 0.5), center, 0.2)
end

function CityStateSafeAreaWallSelect:HideBottomHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
end

function CityStateSafeAreaWallSelect:ShowBottomHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
end

return CityStateSafeAreaWallSelect