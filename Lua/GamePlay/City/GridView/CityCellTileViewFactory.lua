---@class CityCellTileViewFactory
---@field new fun():CityCellTileViewFactory
local CityCellTileViewFactory = sealedClass("CityCellTileViewFactory")
local CityTileViewBuildingBase = require("CityTileViewBuildingBase")
local CityGridCell = require("CityGridCell")
local CityFurniture = require("CityFurniture")
local CitySafeAreaWallDoor = require("CitySafeAreaWallDoor")
local CityWorkProduceResGenUnit = require("CityWorkProduceResGenUnit")
local CityTileViewFurniture = require("CityTileViewFurniture")
local CityTileViewResource = require("CityTileViewResource")
local CityTileViewNpc = require("CityTileViewNpc")
local CityTileViewCitizenSpawnPlace = require("CityTileViewCitizenSpawnPlace")
local CityTileViewCreepNode = require("CityTileViewCreepNode")
local CityTileViewSafeAreaDoor = require("CityTileViewSafeAreaDoor")
local CityTileViewSafeAreaWall = require("CityTileViewSafeAreaWall")
local CityTileViewFarmland = require("CityTileViewFarmland")
local CityTileViewTrainSoldier = require("CityTileViewTrainSoldier")
local CityTileViewPetSystem = require("CityTileViewPetSystem")
local CityTileViewGeneratingRes = require("CityTileViewGeneratingRes")
local CityTileViewHetchEggFurniture = require("CityTileViewHetchEggFurniture")
local CityTileViewStoreroomFurniture = require("CityTileViewStoreroomFurniture")
local ConfigRefer = require("ConfigRefer")
local CityCitizenDefine = require("CityCitizenDefine")
local CityLegoBuilding = require("CityLegoBuilding")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local CityTileViewGachaDogHouse  = require("CityTileViewGachaDogHouse")

---@return CityCellTileViewFactory
function CityCellTileViewFactory.Instance()
    if not CityCellTileViewFactory.__instance then
        CityCellTileViewFactory.__instance = CityCellTileViewFactory.new()
    end
    return CityCellTileViewFactory.__instance
end

---@param cell CityGridCell|CityFurniture|CitySafeAreaWallDoor|CityWorkProduceResGenGridAgent
---@return CityTileView
function CityCellTileViewFactory:Create(cell)
    local ret = nil
    if cell:is(CityGridCell) then
        if cell:IsBuilding() then
            ret = CityTileViewBuildingBase.new()
        elseif cell:IsResource() then
            ret = CityTileViewResource.new()
        elseif cell:IsNpc() then
            ret = CityTileViewNpc.new()
        elseif cell:IsCreepNode() then
            ret = CityTileViewCreepNode.new()
        end
    elseif cell:is(CityFurniture) then
        ret = self:FurnitureTileCreate(cell)
    elseif cell:is(CitySafeAreaWallDoor) then
        if cell.isDoor then
            ret = CityTileViewSafeAreaDoor.new()
        else
            ret = CityTileViewSafeAreaWall.new()
        end
    elseif cell:is(CityWorkProduceResGenUnit) then
        ret = CityTileViewGeneratingRes.new()
    elseif cell:is(CityLegoBuilding) then
        ret = cell:GetOrCreateTileView()
    end

    return ret
end

---@param cell CityGridCell
---@return CityTileView
function CityCellTileViewFactory:FurnitureTileCreate(cell)
    local furnitureLvCfg = ConfigRefer.CityFurnitureLevel:Find(cell.configId)
    if furnitureLvCfg then
        local furnitureTypeId = furnitureLvCfg:Type()
        local furnitureTypeCfg = ConfigRefer.CityFurnitureTypes:Find(furnitureTypeId)
        if CityCitizenDefine.CitizenRecruitmentAgency[furnitureTypeCfg:Id()] then
            return CityTileViewCitizenSpawnPlace.new()
        end
        if CityCitizenDefine.IsFarmlandFurniture(furnitureTypeId) then
            return CityTileViewFarmland.new()
        end
        if CityCitizenDefine.IsTrainSoldier(furnitureTypeId) then
            return CityTileViewTrainSoldier.new()
        end
        if furnitureTypeId == CityFurnitureTypeNames.pet_system then
            return CityTileViewPetSystem.new()
        end
        if CityCitizenDefine.IsGachaDogHouse(furnitureTypeId) then
            return CityTileViewGachaDogHouse.new()
        end
        if CityCitizenDefine.IsHetchPet(furnitureTypeId) then
            return CityTileViewHetchEggFurniture.new()
        end
        if furnitureTypeId == ConfigRefer.CityConfig:StockRoomFurniture() then
            return CityTileViewStoreroomFurniture.new()
        end
    end
    return CityTileViewFurniture.new()
end

function CityCellTileViewFactory:Destroy(view)

end

return CityCellTileViewFactory