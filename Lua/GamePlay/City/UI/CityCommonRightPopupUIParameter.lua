---@class CityCommonRightPopupUIParameter
---@field new fun():CityCommonRightPopupUIParameter
local CityCommonRightPopupUIParameter = class("CityCommonRightPopupUIParameter")

---@param cellTile CityFurnitureTile
function CityCommonRightPopupUIParameter:ctor(cellTile)
    self.cellTile = cellTile
end

function CityCommonRightPopupUIParameter:GetWorldTargetPos()
    return self.cellTile:GetWorldCenter()
end

function CityCommonRightPopupUIParameter:GetZoomSize()
    return self.cellTile:GetFurnitureTypesCell():FocusCameraSize()
end

function CityCommonRightPopupUIParameter:GetBasicCamera()
    return self.cellTile:GetCity():GetCamera()
end

return CityCommonRightPopupUIParameter