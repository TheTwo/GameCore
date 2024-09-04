local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local CityFurnitureConstructionSynthesizeState = require("CityFurnitureConstructionSynthesizeState")

---@class CityFurnitureConstructionSynthesizeStateWorking:CityFurnitureConstructionSynthesizeState
---@field new fun(host:CityFurnitureConstructionSynthesizeUIMediator):CityFurnitureConstructionSynthesizeStateWorking
---@field super CityFurnitureConstructionSynthesizeState
local CityFurnitureConstructionSynthesizeStateWorking = class('CityFurnitureConstructionSynthesizeStateWorking', CityFurnitureConstructionSynthesizeState)

function CityFurnitureConstructionSynthesizeStateWorking:GetName()
    require(self._host._stateKey.Working)
end

function CityFurnitureConstructionSynthesizeStateWorking:Enter()
    self._host._p_Input_quantity.interactable = false
    self._host._child_set_bar:SetInteractable(false)
end

function CityFurnitureConstructionSynthesizeStateWorking:Exit()
    self._host._p_Input_quantity.interactable = true
    self._host._child_set_bar:SetInteractable(true)
end

---@param old wds.CastleFurniture
---@param new wds.CastleFurniture
function CityFurnitureConstructionSynthesizeStateWorking:OnFurnitureDataChanged(old, new)
    if not new or not new.ProcessInfo or not new.ProcessInfo[1] or (new.ProcessInfo[1].LeftNum > 0 or new.ProcessInfo[1].Auto) then
        return
    end
    self._host:ChangeState(self._host._stateKey.Finished)
end

return CityFurnitureConstructionSynthesizeStateWorking