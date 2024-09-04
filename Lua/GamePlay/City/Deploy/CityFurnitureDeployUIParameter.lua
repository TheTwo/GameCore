local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityFurnitureDeployUIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityFurnitureDeployUIParameter
local CityFurnitureDeployUIParameter = class("CityFurnitureDeployUIParameter", CityCommonRightPopupUIParameter)

---@param cellTile CityFurnitureTile
---@param dataSrc CityFurnitureDeployUIDataSrc
function CityFurnitureDeployUIParameter:ctor(cellTile, dataSrc)
    CityCommonRightPopupUIParameter.ctor(self, cellTile)
    self.dataSrc = dataSrc
    self.city = self.cellTile:GetCity()
end

---@param mediator CityFurnitureDeployUIMediator
function CityFurnitureDeployUIParameter:OnMediatorOpened(mediator)
    self.mediator = mediator
    self.dataSrc:OnMediatorOpened(mediator)
end

function CityFurnitureDeployUIParameter:OnMediatorClosed(mediator)
    self.dataSrc:OnMediatorClosed(mediator)
    self.mediator = nil
end

return CityFurnitureDeployUIParameter