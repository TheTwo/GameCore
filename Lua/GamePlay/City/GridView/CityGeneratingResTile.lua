local CityTileBase = require("CityTileBase")
---@class CityGeneratingResTile:CityTileBase
---@field new fun():CityGeneratingResTile
local CityGeneratingResTile = class("CityGeneratingResTile", CityTileBase)
local CityConst = require("CityConst")
function CityGeneratingResTile:ctor(gridView, id, x, y)
    CityTileBase.ctor(self, gridView, x, y)
    self.furnitureId = id
end

function CityGeneratingResTile:GetCameraSize()
    return CityConst.OTHER_MAX_VIEW_SIZE
end

function CityGeneratingResTile:Moveable()
    return false
end

---@return CityWorkProduceResGenUnit
function CityGeneratingResTile:GetCell()
    return self.gridView.cityWorkManager:GetResGenUnit(self.furnitureId)
end

return CityGeneratingResTile