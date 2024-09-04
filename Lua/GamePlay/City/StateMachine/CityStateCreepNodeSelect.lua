local CityState = require("CityState")
---@class CityStateCreepNodeSelect:CityState
---@field new fun():CityStateCreepNodeSelect
---@field cellTile CityCellTile
local CityStateCreepNodeSelect = class("CityStateCreepNodeSelect", CityState)
local CityUtils = require("CityUtils")
local CityCreepNodeCircleMenuHelper = require("CityCreepNodeCircleMenuHelper")
local UIMediatorNames = require("UIMediatorNames")
local CityConst = require("CityConst")

function CityStateCreepNodeSelect:Enter()
    CityState.Enter(self)
    self.cellTile = self.stateMachine:ReadBlackboard("cellTile")
    self.camera = self.city:GetCamera()
    self:CameraLookAt()
end

function CityStateCreepNodeSelect:Exit()
    self:StopCameraDoTween()
    self:CloseUI()
    self.camera = nil
    self.cellTile = nil
    CityState.Exit(self)
end

function CityStateCreepNodeSelect:CameraLookAt()
    local position = CityUtils.GetCityCellCenterPos(self.cellTile:GetCity(), self.cellTile:GetCell())
    local camera = self.camera.mainCamera
    local viewPoint = camera:WorldToViewportPoint(position)
    if viewPoint.x <= 0 or viewPoint.y <= 0 or viewPoint.x >= 1 or viewPoint.y >= 1 then
        self.camera:LookAt(position, 0.5, function()
            self:OpenUI()
        end)
    else
        self:OpenUI()
    end
end

function CityStateCreepNodeSelect:StopCameraDoTween()
    self.camera:ForceGiveUpTween()
end

function CityStateCreepNodeSelect:OpenUI()
    if self.runTimeId ~= nil then return end

    local param = self.cellTile:GetTouchInfoData()
    self.runTimeid = g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, param)
end

function CityStateCreepNodeSelect:CloseUI()
    if not self.runTimeid then return end
    g_Game.UIManager:Close(self.runTimeid)
end

function CityStateCreepNodeSelect:OnClick(gesture)
    self.stateMachine:ChangeState(CityConst.STATE_NORMAL)
    self.stateMachine.currentState:OnClick(gesture)
end

function CityStateCreepNodeSelect:OnCameraSizeChanged(oldValue, newValue)
    local state = self.city:GetSuitableIdleState(newValue)
    if state ~= CityConst.STATE_NORMAL then
        self.stateMachine:ChangeState(state)
    end
end

return CityStateCreepNodeSelect