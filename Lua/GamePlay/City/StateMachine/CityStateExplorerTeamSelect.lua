local CityConst = require("CityConst")
local CityExplorerTeamDragMask = CS.UnityEngine.LayerMask.GetMask("City")
local EventConst = require("EventConst")
local CityUtils = require("CityUtils")
local ConfigRefer = require("ConfigRefer")
local CityUnitPathLine = require("CityUnitPathLine")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ColorUtility = CS.UnityEngine.ColorUtility
local physics = physics

local CityState = require("CityState")

---@class CityStateExplorerTeamSelect:CityState
---@field new fun():CityStateExplorerTeamSelect
---@field super CityState
local CityStateExplorerTeamSelect = class('CityStateExplorerTeamSelect', CityState)
CityStateExplorerTeamSelect.DragConfig = {
    --屏幕边框进区域
    MinX = 0.1,
    MaxX = 0.9,
    MinY = 0.2,
    MaxY = 0.8,
    --根据高度计算当前摄像机移动速度
    MaxSpeed = 20,
    MinSpeed = 5,
}
local success,color = ColorUtility.TryParseHtmlString("#ffffffcc")
CityStateExplorerTeamSelect.SelectLineColor = success and color or CS.UnityEngine.Color.white

function CityStateExplorerTeamSelect:ctor(city)
    CityState.ctor(self, city)
    self._dragIsFromTeam = false
    ---@type CityUnitPathLine
    self._targetLine = nil
    self._selectPathCalculating = false
    ---@type CityCellTile
    self._lastSelectedTile = nil
    self._dragCamTimer = 0
    ---@type CS.UnityEngine.Vector3
    self._lastDragPos = nil
    self._focusOnTeam = false
end

function CityStateExplorerTeamSelect:Enter()
    CityState.Enter(self)
    g_Logger.Log("Enter")
    self._focusOnTeam = self.stateMachine:ReadBlackboard("FOCUS_ON_TEAM", true)
    self._lastDragPos = nil
    self._dragIsFromTeam = false
    self._dragCamTimer = 0
    self:Tick(0)
    self:BlockCamera()
    --self.city.cityExplorerManager:SetTeamSelected(true)
end

function CityStateExplorerTeamSelect:Exit()
    --self.city.cityExplorerManager:SetTeamSelected(false)
    self:CleanupDragExtra()
    self._dragIsFromTeam = false
    self:RecoverCamera()
    CityState.Exit(self)
end

function CityStateExplorerTeamSelect:OnClick(gesture)
    self.stateMachine:ChangeState(CityConst.STATE_NORMAL)
end

function CityStateExplorerTeamSelect:OnClickTrigger(trigger, position)
    self.stateMachine:ChangeState(CityConst.STATE_NORMAL)
end

function CityStateExplorerTeamSelect:Tick(dt)
    if not self._dragIsFromTeam and self._focusOnTeam then
        local teamPos = self.city.cityExplorerManager:GetTeamPosition()
        if not teamPos then
            return
        end
        ---@type CS.UnityEngine.Vector3
        local viewPortPos = CS.UnityEngine.Vector3(0.5, 0.45, 0.0)
        local camera = self.city:GetCamera()
        camera:ForceGiveUpTween()
        camera:ZoomToWithFocus(camera:GetSize(), viewPortPos, teamPos)
    elseif self._lastDragPos then
        self:OnScreenEdgeMove(self._lastDragPos, dt)
    end
end

function CityStateExplorerTeamSelect:OnDragStartExternal(gesture)
    self._dragCamTimer = 0
    self._lastDragPos = nil
    self._dragIsFromTeam = false
    if not self._selectPathCalculating then
        self._dragIsFromTeam = true
    end
    if not self._dragIsFromTeam then
        self:ExitToIdleState()
    else
        self._targetLine = CityUnitPathLine.GetOrCreate(self.city.CityExploreRoot, ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_pathline))
        self._targetLine:SetLineColor(CityStateExplorerTeamSelect.SelectLineColor)
    end
    g_Logger.Log("OnDragStartExternal team:%s", self._dragIsFromTeam)
end

function CityStateExplorerTeamSelect:OnDragStart(gesture)
    self._dragCamTimer = 0
    self._lastDragPos = nil
    self._dragIsFromTeam = false
    if not self._selectPathCalculating then
        local ray = self.city.camera:GetRayFromScreenPosition(gesture.position)
        CS.UnityEngine.Debug.DrawRay(ray.origin, ray.direction * 1000, CS.UnityEngine.Color.magenta, 20, false)
        local hitCount,hitResults = physics.raycastnonalloc(ray, 1000, CityExplorerTeamDragMask)
        if hitCount > 0 then
            for _, v in pairs(hitResults) do
                if v:CompareTag("ExplorerTeamTrigger") then
                    self._dragIsFromTeam = true
                    break
                end
            end
        end
    end
    if not self._dragIsFromTeam then
        self:ExitToIdleState()
    else
        self._targetLine = CityUnitPathLine.GetOrCreate(self.city.CityExploreRoot, ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_pathline))
        self._targetLine:SetLineColor(CityStateExplorerTeamSelect.SelectLineColor)
    end
    g_Logger.Log("OnDragStart team:%s", self._dragIsFromTeam)
end

function CityStateExplorerTeamSelect:OnDragUpdate(gesture)
    if not self._dragIsFromTeam then
        return
    end
    if self._selectPathCalculating then
        return
    end
    self._lastDragPos = gesture.position
    local hitPos = self.city:GetCamera():GetHitPoint(gesture.position)
    self:UpdateTargetLine(hitPos)
    self:SelectNpcTile(gesture)
    g_Logger.Log("OnDragUpdate team:%s", self._dragIsFromTeam)
end

---@param screenPos CS.UnityEngine.Vector3
---@param delta number
function CityStateExplorerTeamSelect:OnScreenEdgeMove(screenPos, delta)
    local camera = self.city:GetCamera()
    if camera:IsOnScreenBoard(screenPos, CityStateExplorerTeamSelect.DragConfig) then
        local offset = camera:GetScrollingOffset(screenPos)
        self._dragCamTimer = self._dragCamTimer + delta
        local moveSpeed = math.lerp(
                CityStateExplorerTeamSelect.DragConfig.MinSpeed,
                CityStateExplorerTeamSelect.DragConfig.MaxSpeed,
                math.clamp01( self._dragCamTimer / 2.0)
        )
        camera:MoveCameraOffset(offset * moveSpeed  * delta)
    else
        self._dragCamTimer = 0
    end
end

function CityStateExplorerTeamSelect:OnDragEnd(gesture)
    if not self._dragIsFromTeam then
        return
    end
    self:CleanupDragExtra()
    if self._selectPathCalculating then
        return
    end
    g_Logger.Log("OnDragEnd team:%s", self._dragIsFromTeam)
    self._dragIsFromTeam = false
    self:OnDragEndSelectTarget(gesture)
    self:ExitToIdleState()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateExplorerTeamSelect:SelectNpcTile(gesture)
    local lastTile = self._lastSelectedTile
    local npcTile = self.city:RaycastNpcTile(gesture.position)
    if not self:IsValidNpcTile(npcTile) then
        npcTile = nil
    end
    if npcTile ~= lastTile then
        if lastTile then
            lastTile:SetSelected(false)
        end
        if npcTile then
            npcTile:SetSelected(true)
        end
    end
    self._lastSelectedTile = npcTile
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateExplorerTeamSelect:OnDragEndSelectTarget(gesture)
    local npcTile,_,_,point = self.city:RaycastNpcTile(gesture.position)
    if not self:IsValidNpcTile(npcTile) then
        npcTile = nil
    end
    if npcTile then
        npcTile:SetSelected(true)
        local city = npcTile:GetCity()
        local cell = npcTile:GetCell()
        local eleConfig = ConfigRefer.CityElementData:Find(cell.configId)
        local elePos = eleConfig:Pos()
        local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
        local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcConfig)--CityUtils.SuggestCellCenterPositionWithHeight(city, cell, 0, true)

        ---@type ClickNpcEventContext
        local context = {}
        context.cityUid = city.uid
        context.elementConfigID = cell.configId
        context.targetPos = pos
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
    else
        self:StartTargetGround(point)
    end
end

---@param npcTile CityCellTile
function CityStateExplorerTeamSelect:IsValidNpcTile(npcTile)
    if not npcTile then
        return false
    end
    local eleConfig = ConfigRefer.CityElementData:Find(npcTile:GetCell().configId)
    if not eleConfig then
        return false
    end
    local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
    if not npcConfig then
        return false
    end
    return not npcConfig:NoInteractable()
end

---@param p1 CS.UnityEngine.Vector3
function CityStateExplorerTeamSelect:StartTargetGround(point)
    if self._selectPathCalculating then
        return
    end
    self._selectPathCalculating = true
    self.city.cityExplorerManager:DoTeamTargetGround(point, function() self._selectPathCalculating = false end)
end

---@param p1 CS.UnityEngine.Vector3
function CityStateExplorerTeamSelect:UpdateTargetLine(p1)
    if not self._targetLine then
        return
    end
    local p0 = self.city.cityExplorerManager:GetTeamPosition()
    self._targetLine:UpdatePoints(p0, p1)
end

function CityStateExplorerTeamSelect:CleanupDragExtra()
    self._lastDragPos = nil
    self._dragCamTimer = 0
    if self._targetLine then
        CityUnitPathLine.Delete(self._targetLine)
        self._targetLine = nil
    end
    if self._lastSelectedTile then
        self._lastSelectedTile:SetSelected(false)
    end
    self._lastSelectedTile = nil
end

return CityStateExplorerTeamSelect