---@class CityPetAssignmentUICellData
---@field new fun():CityPetAssignmentUICellData
local CityPetAssignmentUICellData = class("CityPetAssignmentUICellData")

function CityPetAssignmentUICellData:ctor(handle, id)
    ---@type CityPetAssignHandle
    self.assignHandle = handle
    self.id = id
    self.petData = self.assignHandle:GetPetData(id)
end

function CityPetAssignmentUICellData:IsMultiSelection()
    return self.assignHandle.maxSelectCount > 1
end

function CityPetAssignmentUICellData:IsSelected()
    return self.assignHandle.selectedPetsId[self:GetPetData().id]
end

function CityPetAssignmentUICellData:GetPetName()
    return self.assignHandle:GetPetName(self:GetPetData().id)
end

function CityPetAssignmentUICellData:NeedShowBuff()
    return self.assignHandle:NeedShowBuff()
end

function CityPetAssignmentUICellData:GetWorkRelativeBuffData()
    return self.assignHandle:GetWorkRelativeBuffData(self.petData.id)
end

function CityPetAssignmentUICellData:GetPetData()
    return self.petData
end

function CityPetAssignmentUICellData:NeedShowPosition()
    return self.assignHandle:NeedShowPosition()
end

function CityPetAssignmentUICellData:IsFree()
    return self.assignHandle:IsFree(self)
end

function CityPetAssignmentUICellData:GetWorkPositionName()
    return self.assignHandle:GetWorkPositionName(self)
end

---@return boolean
function CityPetAssignmentUICellData:SwitchSelect()
    return self.assignHandle:SwitchSelect(self:GetPetData().id)
end

function CityPetAssignmentUICellData:IsLandNotFit()
    return self.assignHandle:IsLandNotFit(self)
end

function CityPetAssignmentUICellData:GetBloodPercent()
    return self.assignHandle:GetBloodPercent(self)
end

function CityPetAssignmentUICellData:IsInTroop()
    return self.assignHandle:IsInTroop(self)
end

function CityPetAssignmentUICellData:ShowLandNotFitHint(rectTransform)
    return self.assignHandle:ShowLandNotFitHint(self, rectTransform)
end

function CityPetAssignmentUICellData:NeedShowFeature()
    return self.assignHandle:NeedShowFeature()
end

function CityPetAssignmentUICellData:GetPetWorkCfgs()
    return self.assignHandle:GetPetWorkCfgs(self:GetPetData().id)
end

return CityPetAssignmentUICellData