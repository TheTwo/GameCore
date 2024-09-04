local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local CityUtils = require("CityUtils")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class SLGTouchInjectedSelectedTarget
---@field new fun(city:MyCity|City):SLGTouchInjectedSelectedTarget
local SLGTouchInjectedSelectedTarget = class('SLGTouchInjectedSelectedTarget')

function SLGTouchInjectedSelectedTarget:ctor(city)
    ---@type MyCity|City
    self.city = city
    ---@type SelectTroopData|nil
    self._selectedTroopData = nil
    ---@type number|nil
    self._troopPresetIdx = nil
end

---@param selectedTroopData SelectTroopData
function SLGTouchInjectedSelectedTarget:SetUpCtrlTroop(selectedTroopData)
    self._selectedTroopData = selectedTroopData
    self._troopPresetIdx = selectedTroopData and selectedTroopData.presetIndex
end

---@param screenPos CS.UnityEngine.Vector3
function SLGTouchInjectedSelectedTarget:OnDragStart(screenPos)
    local troopIdx = self._troopPresetIdx
    local selectedData = self._selectedTroopData
    self:CleanupDragExtra()
    self._selectedTroopData = selectedData
    self._troopPresetIdx = troopIdx
    self._lastDragPos = nil
    g_Logger.Log("OnDragStart, screenPosX:%s Y:%s", screenPos.x, screenPos.y)
end

---@param screenPos CS.UnityEngine.Vector3
function SLGTouchInjectedSelectedTarget:OnDragUpdate(screenPos)
    self._lastDragPos = screenPos
    if not self._troopPresetIdx then
        return
    end
    self:SelectNpcTile(screenPos)
    g_Logger.Log("OnDragUpdate, screenPosX:%s Y:%s", screenPos.x, screenPos.y)
end

function SLGTouchInjectedSelectedTarget:OnDragEnd(screenPos)
    g_Logger.Log("SLGTouchInjectedSelectedTarget, screenPosX:%s Y:%s", screenPos.x, screenPos.y)
    local ret = self:OnDragEndSelectTarget(screenPos)
    self:CleanupDragExtra()
    return ret
end

function SLGTouchInjectedSelectedTarget:OnDragCancel()
    self:CleanupDragExtra()
end

---@param screenPos CS.UnityEngine.Vector3
function SLGTouchInjectedSelectedTarget:SelectNpcTile(screenPos)
    local lastTile = self._lastSelectedTile
    local npcTile = self.city:RaycastNpcTile(screenPos)
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

---@param npcTile CityCellTile
function SLGTouchInjectedSelectedTarget:IsValidNpcTile(npcTile)
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

---@param screenPos CS.UnityEngine.Vector3
function SLGTouchInjectedSelectedTarget:OnDragEndSelectTarget(screenPos)
    if not self._troopPresetIdx then
        return false
    end
    local npcTile,x,y,point = self.city:RaycastNpcTile(screenPos)
    if not x or not y then
        return true
    end
    if self.city:IsFogMask(x, y) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_24008"))
        return true
    end
    if not self:IsValidNpcTile(npcTile) then
        npcTile = nil
    end
    if npcTile then
        if npcTile:IsPolluted() then
            self.city:OnClick({position = screenPos})
            return true
        end

        npcTile:SetSelected(true)
        local city = npcTile:GetCity()
        local cell = npcTile:GetCell()
        local eleConfig = ConfigRefer.CityElementData:Find(cell.configId)
        local elePos = eleConfig:Pos()
        local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
        local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcConfig) --CityUtils.SuggestCellCenterPositionWithHeight(city, cell, 0, true)

        ---@type ClickNpcEventContext
        local context = {}
        context.cityUid = city.uid
        context.elementConfigID = cell.configId
        context.targetPos = pos
        context.selectedTroopPresetIdx = self._troopPresetIdx
        context.isDragMoveToTarget = true
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
        return true
    else
        return self:StartTargetGround(point)
    end
end

---@param point CS.UnityEngine.Vector3
function SLGTouchInjectedSelectedTarget:StartTargetGround(point)
    if self._selectedTroopData and self._selectedTroopData.ctrl then
        self.city.cityExplorerManager:DoTeamTargetGround(point, nil, self._selectedTroopData.ctrl.ID)
        return true
    end
    return false
end

function SLGTouchInjectedSelectedTarget:CleanupDragExtra()
    self._troopPresetIdx = nil
    self._selectedTroopData = nil
    self._lastDragPos = nil
    if self._lastSelectedTile then
        self._lastSelectedTile:SetSelected(false)
    end
    self._lastSelectedTile = nil
end

return SLGTouchInjectedSelectedTarget