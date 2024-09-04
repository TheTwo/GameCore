local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local EventConst = require("EventConst")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local FurniturePageDefine = require("FurniturePageDefine")
local ModuleRefer = require("ModuleRefer")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local TypeNone = 0

---@type table<number, fun(CityFurnitureTile, CityFurnitureTypesConfigCell, CityFurnitureLevelConfigCell, wds.CastleFurniture):TouchInfoCompDatum|nil>
local CityFurnitureFunctionCollection = {
    [CityFurnitureTypeNames.wood_station or TypeNone] = nil,
    [CityFurnitureTypeNames.stone_station or TypeNone] = nil,
    [CityFurnitureTypeNames.herb_produce or TypeNone] = nil,
    [CityFurnitureTypeNames.food_produce or TypeNone] = nil,
    [CityFurnitureTypeNames.rolin_produce or TypeNone] = nil,
    [CityFurnitureTypeNames.soilder_recuite or TypeNone] = function(cellTile)
        local callback = function()
            -- local param = CityLegoBuildingUIParameter.new(cellTile:GetCity(), nil, cellTile:GetCell():UniqueId())
            -- g_Game.UIManager:Open('CityLegoBuildingUIMediator', param)
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Get("menu_btn_gearbuild"), callback)
        return item
    end,
    [CityFurnitureTypeNames.creep_system or TypeNone] = nil,
    [CityFurnitureTypeNames.creep_num or TypeNone] = nil,
    [CityFurnitureTypeNames.pet_system or TypeNone] = nil,
    [CityFurnitureTypeNames.rader_system or TypeNone] = function(cellTile)
        local callback = function()
            local basicCamera = cellTile:GetCity().camera
            basicCamera.ignoreLimit = true
            ModuleRefer.RadarModule:SetRadarState(true)
            basicCamera:ZoomToMaxSize(0.2, function()
                g_Game.UIManager:Open(UIMediatorNames.RadarMediator, {isInCity = true})
            end)
        end
        return TouchMenuMainBtnDatum.new(I18N.Get("leida_title"), callback)
    end,
    [CityFurnitureTypeNames.soilder_system or TypeNone] = nil,
    [CityFurnitureTypeNames.bed or TypeNone] = nil,
    [CityFurnitureTypeNames.box or TypeNone] = function(cellTile)
        local callback = function()
            ---@type CityCitizenResourceAutoCollectMediatorParameter
            local uiParameter = {}
            uiParameter.cityUid = cellTile:GetCity().uid
            uiParameter.furnitureId = cellTile:GetCell():UniqueId()
            g_Game.UIManager:Open(UIMediatorNames.CityCitizenResourceAutoCollectMediator, uiParameter)
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Get("crafting_process_auto_button"), callback)
        return item
    end,
    [CityFurnitureTypeNames.CITIZEN_RECRUITMENT_AGENCY or TypeNone] = function(cellTile)
        ---@type CityFurniture
        local cell = cellTile:GetCell()
        local singleId = cell.singleId
        ---@type City
        local city = cellTile:GetCity()
        local callback = function()
            g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SPAWN_CLICK, city.uid, singleId)
        end
        local enableFunc = function()
            local furniture = city.furnitureManager:GetFurnitureById(singleId)
            if not furniture then
                return false
            end
            local castle = city:GetCastle()
            local furnitureData = castle.CastleFurniture[singleId]
            local waitingCitizenQueue = furnitureData and furnitureData.WaitingCitizens or nil
            return waitingCitizenQueue and not table.isNilOrZeroNums(waitingCitizenQueue) or false
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Get("furniture_citizen_recieve_but"), callback)
        item:SetEnable(enableFunc())
        return item
    end,
    [CityFurnitureTypeNames.PRODUCE_BOX or TypeNone] = function(cellTile)
        local callback = function()
            ---@type CityCitizenAutoProcessFurnitureMediatorParameter
            local uiParameter = {}
            uiParameter.furnitureId = cellTile:GetCell():UniqueId()
            uiParameter.city = cellTile:GetCity()
            g_Game.UIManager:Open(UIMediatorNames.CityCitizenAutoProcessFurnitureMediator, uiParameter)
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Temp().btn_auto_produce, callback)
        return item
    end,
    [CityFurnitureTypeNames.sciencetable or TypeNone] = function(cellTile)
        local callback = function()
            g_Game.UIManager:Open('UIScienceMediator')
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Get("tech_info_title"), callback)
        return item
    end,
    [CityFurnitureTypeNames.equipmentstation or TypeNone] = function(cellTile)
        local callback = function()
            g_Game.UIManager:Open('HeroEquipForgeRoomUIMediator')
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Get("tech_info_title"), callback)
        return item
    end,
    [CityFurnitureTypeNames.doghouse or TypeNone] = function(cellTile)
        local callback = function()
            g_Game.UIManager:Open('HeroCardMediator', 1)
        end
        local item = TouchMenuMainBtnDatum.new(I18N.Get(""), callback)
        return item
    end,
}

return CityFurnitureFunctionCollection
