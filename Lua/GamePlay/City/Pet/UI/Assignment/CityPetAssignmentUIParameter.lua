---@class CityPetAssignmentUIParameter
---@field new fun(title, handle, features, assignCallback, closeAfterAssign):CityPetAssignmentUIParameter
local CityPetAssignmentUIParameter = class("CityPetAssignmentUIParameter")

---@param title string
---@param handle CityPetAssignHandle
---@param features number[] @enum-PetWorkType
---@param assignCallback fun(selectedPetsId:table<number, boolean>, onConfirmTwiceCancel:fun()):boolean @return true to close the UI
---@param closeAfterAssign boolean
function CityPetAssignmentUIParameter:ctor(title, handle, features, assignCallback, closeAfterAssign)
    self.title = title
    self.handle = handle
    self.features = features
    self.assignCallback = assignCallback
    self.needClose = closeAfterAssign

    self.selectedPetsId = {}
    for id, flag in pairs(handle.selectedPetsId) do
        self.selectedPetsId[id] = flag
    end
end

function CityPetAssignmentUIParameter:GetTitle()
    return self.title
end

function CityPetAssignmentUIParameter:NeedShowFeature()
    return self.features ~= nil
end

function CityPetAssignmentUIParameter:GetFeatures()
    return self.features
end

function CityPetAssignmentUIParameter:IsDirty()
    for id, flag in pairs(self.selectedPetsId) do
        if self.handle.selectedPetsId[id] ~= flag then
            return true
        end
    end

    for id, flag in pairs(self.handle.selectedPetsId) do
        if self.selectedPetsId[id] ~= flag then
            return true
        end
    end

    return false
end

function CityPetAssignmentUIParameter:RequestAssign(selectedPetsId, onAsyncAssignCallback)
    if self.assignCallback then
        return self.assignCallback(selectedPetsId, onAsyncAssignCallback)
    end
    return true
end

function CityPetAssignmentUIParameter:CloseAfterAssign()
    return self.needClose
end

function CityPetAssignmentUIParameter:NeedShowExtraHint()
    return self.handle:NeedShowExtraHint()
end

function CityPetAssignmentUIParameter:GetExtraHintText(fontSize)
    return self.handle:GetExtraHintText(fontSize)
end

---@param mediator CityPetAssignmentUIMediator
function CityPetAssignmentUIParameter:OnMediatorOpended(mediator)
    self.mediator = mediator
    self.handle:OnMediatorOpened(mediator)
end

---@param mediator CityPetAssignmentUIMediator
function CityPetAssignmentUIParameter:OnMediatorClosed(mediator)
    self.handle:OnMediatorClosed(mediator)
    self.mediator = nil
end

---@vararg number
function CityPetAssignmentUIParameter:OnMultiSelectChange(...)
    self.handle:OnMultiSelectChange(...)
end

return CityPetAssignmentUIParameter