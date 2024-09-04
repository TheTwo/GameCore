---@class CityFurnitureDeployHeroCellData
---@field new fun():CityFurnitureDeployHeroCellData
local CityFurnitureDeployHeroCellData = class("CityFurnitureDeployHeroCellData")

function CityFurnitureDeployHeroCellData:GetPrefabIndex()
    return 1
end

---@return HeroConfigCache
function CityFurnitureDeployHeroCellData:GetHeroData()
    ---override this
    return nil
end

---@return string
function CityFurnitureDeployHeroCellData:GetHeroName()
    ---override this
    return nil
end

---@return string
function CityFurnitureDeployHeroCellData:GetHeroLv()
    ---override this
    return nil
end

function CityFurnitureDeployHeroCellData:IsShareTarget()
    return false
end

return CityFurnitureDeployHeroCellData