local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")

local CityFurnitureConstructionSynthesizeState = require("CityFurnitureConstructionSynthesizeState")

---@class CityFurnitureConstructionSynthesizeStateFinished:CityFurnitureConstructionSynthesizeState
---@field new fun(host:CityFurnitureConstructionSynthesizeUIMediator):CityFurnitureConstructionSynthesizeStateFinished
---@field super CityFurnitureConstructionSynthesizeState
local CityFurnitureConstructionSynthesizeStateFinished = class('CityFurnitureConstructionSynthesizeStateFinished', CityFurnitureConstructionSynthesizeState)

function CityFurnitureConstructionSynthesizeStateFinished:GetName()
    require(self._host._stateKey.Finished)
end

function CityFurnitureConstructionSynthesizeStateFinished:Enter()
    local furnitureData = self._host._furniture:GetCastleFurniture()
    if furnitureData and furnitureData.ProcessInfo then
        local processInfo = furnitureData.ProcessInfo[1]
        if processInfo then
            local processId = processInfo.ConfigId
            local process = ConfigRefer.CityProcess:Find(processId)
            if process then
                local outputItem = process:Output(1)
                ---@type CityFurnitureConstructionSynthesizeSuccessMediatorParameter
                local parameter = {}
                parameter.itemId = outputItem:ItemId()
                parameter.count = processInfo.FinishNum * outputItem:Count()
                parameter.onCloseCallback = Delegate.GetOrCreate(self, self.OnClickCollectBtn)
                g_Game.UIManager:Open(UIMediatorNames.CityFurnitureConstructionSynthesizeSuccessMediator, parameter)
            end
            return
        end
    end
    self._host:ChangeState(self._host._stateKey.Idle)
end

function CityFurnitureConstructionSynthesizeStateFinished:OnClickCollectBtn(trans, context)
    self._host._citizenMgr:GetProcessOutput(trans, self._host._furniture:UniqueId(),function(context, isSuccess, data)
        self._host:ChangeState(self._host._stateKey.Idle)
    end, {0})
end

return CityFurnitureConstructionSynthesizeStateFinished