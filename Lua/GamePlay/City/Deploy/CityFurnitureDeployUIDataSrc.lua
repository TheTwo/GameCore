---@class CityFurnitureDeployUIDataSrc
---@field new fun():CityFurnitureDeployUIDataSrc
local CityFurnitureDeployUIDataSrc = class("CityFurnitureDeployUIDataSrc")

---@param name string
---@param desc string
---@param features number[] @enum-PetWorkType
function CityFurnitureDeployUIDataSrc:ctor(name, desc, features)
    self.name = name
    self.desc = desc
    self.features = features
end

function CityFurnitureDeployUIDataSrc:GetMainHint()
    return string.Empty
end

---@return boolean
function CityFurnitureDeployUIDataSrc:ShowMainTitle()
    return self:ShowName() or self:ShowFeature()
end

---@return boolean
function CityFurnitureDeployUIDataSrc:ShowName()
    return not string.IsNullOrEmpty(self.name)
end

---@return boolean
function CityFurnitureDeployUIDataSrc:ShowFeature()
    return self.features ~= nil and #self.features > 0
end

---@return boolean
function CityFurnitureDeployUIDataSrc:ShowDesc()
    return not string.IsNullOrEmpty(self.desc)
end

function CityFurnitureDeployUIDataSrc:ShowHint()
    return not string.IsNullOrEmpty(self:GetHint())
end

function CityFurnitureDeployUIDataSrc:ShowBuffValue()
    return false
end

function CityFurnitureDeployUIDataSrc:GetBuffTitle()
    return nil
end

function CityFurnitureDeployUIDataSrc:GetBuffData()
    return {}
end

function CityFurnitureDeployUIDataSrc:GetHint()
    return nil
end

function CityFurnitureDeployUIDataSrc:ShowMemberTitle()
    return self:ShowLeftTitle() or self:ShowRightTitle()
end

---@return boolean
function CityFurnitureDeployUIDataSrc:ShowLeftTitle()
    return not string.IsNullOrEmpty(self:GetLeftTitle())
end

---@return boolean
function CityFurnitureDeployUIDataSrc:ShowRightTitle()
    return not string.IsNullOrEmpty(self:GetRightTitle())
end

---@return string
function CityFurnitureDeployUIDataSrc:GetLeftTitle()
    return nil
end

---@return string
function CityFurnitureDeployUIDataSrc:GetRightTitle()
    return nil
end

---@return CityFurnitureDeployCellData[]
function CityFurnitureDeployUIDataSrc:GetTableViewCellData()
    return {}
end

---@param mediator CityFurnitureDeployUIMediator
function CityFurnitureDeployUIDataSrc:OnMediatorOpened(mediator)
    
end

---@param mediator CityFurnitureDeployUIMediator
function CityFurnitureDeployUIDataSrc:OnMediatorClosed(mediator)
    
end

return CityFurnitureDeployUIDataSrc