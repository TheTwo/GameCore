local CityFurnitureConstructionSynthesizeState = require("CityFurnitureConstructionSynthesizeState")

---@class CityFurnitureConstructionSynthesizeStateIdle:CityFurnitureConstructionSynthesizeState
---@field new fun(host:CityFurnitureConstructionSynthesizeUIMediator):CityFurnitureConstructionSynthesizeStateIdle
---@field super CityFurnitureConstructionSynthesizeState
local CityFurnitureConstructionSynthesizeStateIdle = class('CityFurnitureConstructionSynthesizeStateIdle', CityFurnitureConstructionSynthesizeState)

function CityFurnitureConstructionSynthesizeStateIdle:GetName()
    require(self._host._stateKey.Idle)
end

function CityFurnitureConstructionSynthesizeStateIdle:Enter()
    self._host._p_cell_group:SetState(0)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
---@return boolean
function CityFurnitureConstructionSynthesizeState:OnFormulaCellBeginDrag(cellData, data)
    self._host:ChangeState(self._host._stateKey.Drag)
    local state = self._host._stateMachine:GetCurrentState()
    if not state then
        return false
    end
    return state.OnFormulaCellBeginDrag and state.OnFormulaCellBeginDrag(state, cellData, data)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionSynthesizeStateIdle:OnClickFormulaCell(cellData)
    self._host:WriteBlackboard("FormulaCellParameter", cellData, true)
    self._host:ChangeState(self._host._stateKey.Selected)
end

return CityFurnitureConstructionSynthesizeStateIdle