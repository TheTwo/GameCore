local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local CityFurnitureConstructionSynthesizeState = require("CityFurnitureConstructionSynthesizeState")

---@class CityFurnitureConstructionSynthesizeStateDrag:CityFurnitureConstructionSynthesizeState
---@field new fun():CityFurnitureConstructionSynthesizeStateDrag
---@field super CityFurnitureConstructionSynthesizeState
local CityFurnitureConstructionSynthesizeStateDrag = class('CityFurnitureConstructionSynthesizeStateDrag', CityFurnitureConstructionSynthesizeState)


function CityFurnitureConstructionSynthesizeStateDrag:GetName()
    require(self._host._stateKey.Drag)
end

function CityFurnitureConstructionSynthesizeStateDrag:Enter()
    self._host._p_cell_group:SetState(1)
    self._lastDragIndex = -1
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
---@return boolean
function CityFurnitureConstructionSynthesizeStateDrag:OnFormulaCellBeginDrag(cellData, data)
    if self._host._isNotFunctional then
        return false
    end
    if self._lastDragIndex > 0 then
        return false
    end
    self._lastDragIndex = cellData.index
    local screenPos = data.position
    self._dragPos = screenPos
    self._host:ShowDragCell(cellData, screenPos)
    return true
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionSynthesizeStateDrag:OnFormulaCellDrag(cellData, data)
    if self._host._isNotFunctional then
        return false
    end
    if self._lastDragIndex ~= cellData.index then
        return
    end
    local screenPos = data.position
    self._dragPos = screenPos
    self._host:SetupDragPosWithScreenPos(screenPos)
end


---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionSynthesizeStateDrag:OnFormulaCellEndDrag(cellData, data)
    if self._lastDragIndex ~= cellData.index then
        return
    end
    self._dragPos = nil
    self._lastDragIndex = -1
    self._host:DragSelectedCleanup()
    if self._host._isNotFunctional then
        return
    end
    local contains,localPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._host._p_cell_group_rect, data.position, g_Game.UIManager:GetUICamera())
    if not contains then
        self._host:ChangeState(self._host._stateKey.Idle)
        return
    end
    local rect = self._host._p_cell_group_rect.rect
    local r = math.min(rect.size.x, rect.size.y) * 0.5
    local center = rect.center
    local sX = localPoint.x - center.x
    local sY = localPoint.y - center.y
    if (sX * sX + sY * sY) > (r * r) then
        self._host:ChangeState(self._host._stateKey.Idle)
        return
    end
    self._host:WriteBlackboard("FormulaCellParameter", cellData, true)
    self._host:ChangeState(self._host._stateKey.Selected)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionSynthesizeStateDrag:OnFormulaCellCancelDrag(cellData)
    if self._lastDragIndex ~= cellData.index then
        return
    end
    self._dragPos = nil
    self._lastDragIndex = -1
    self._host:DragSelectedCleanup()
    self._host:ChangeState(self._host._stateKey.Idle)
end

return CityFurnitureConstructionSynthesizeStateDrag