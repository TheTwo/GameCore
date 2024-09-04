local BuildingType = require("BuildingType")
local CityCitizenDefine = require("CityCitizenDefine")
local UIMediatorNames = require("UIMediatorNames")
local TouchInfoHelper = require("TouchInfoHelper")
local TouchInfoDefine = require("TouchInfoDefine")
local I18N = require("I18N")

---@type table<number, fun(CityCellTile, BuildingTypesConfigCell, wds.CastleBuildingInfo):TouchInfoCompDatum|nil>
local CityBuildingFunctionCollection = {
    [BuildingType.Stronghold] = nil,
    [BuildingType.Wall] = nil,
    [BuildingType.ArcherCamp] = nil,
    [BuildingType.ExplorerCamp] = function(cellTile, typeCell, buildingInfo)
        ---@type City
        local city = cellTile:GetCity()
        if not city or not city.furnitureManager then
            return nil
        end
        ---@type CityFurnitureTile[]
        local furnitureArray = city:GetRelativeFurnitureTile(cellTile)
        if not furnitureArray or #furnitureArray <= 0 then
            return nil
        end
        for _, f in pairs(furnitureArray) do
            local furniture = f:GetCell()
            if furniture and furniture.furnitureCell then
                if CityCitizenDefine.CityFurnitureExplorerTeamTypeIds[furniture.furnitureCell:Type()] then
                    local callback = function()
                        city.stateMachine:ChangeState(city:GetSuitableIdleState(city.cameraSize))
                        g_Game.UIManager:Open(UIMediatorNames.SEHudTroopMediator)
                    end
                    local item = TouchInfoHelper.GenerateButtonCompData(callback, nil, TouchInfoDefine.ButtonIcons.IconSESkillCard, I18N.Get("menu_btn_cardgroupedit"), TouchInfoDefine.ButtonBacks.BackNormal)
                    return item
                end
            end
        end
        return nil
    end,
    [BuildingType.CitizenHouse] = nil,
}

return CityBuildingFunctionCollection
