---@class CityLegoBuildingUIParameter
---@field new fun(city, legoBuilding, selectFurnitureId):CityLegoBuildingUIParameter
local CityLegoBuildingUIParameter = sealedClass("CityLegoBuildingUIParameter")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local LegoUIPage_SpecialData = require("LegoUIPage_SpecialData")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")

---@priorityPage number|nil @1-制造；2-采集；3-种植；4-升级；5-详情；6-捉宠 : 界面大改，暂时弃用

---@param city City
---@param legoBuilding CityLegoBuilding
---@param selectFurnitureId id
function CityLegoBuildingUIParameter:ctor(city, legoBuilding, selectFurnitureId)
    self.city = city
    self.legoBuilding = legoBuilding
    self.selectFurnitureId = selectFurnitureId
end

---@return LegoUIPage_SpecialData 带全屏界面的家具入口数据
function CityLegoBuildingUIParameter:GetSpecialData(furnitureId)
    ---TODO:抽卡之类的要从家具入口进
    local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
    if furniture == nil then return nil end

    local furType = furniture.furType
    if furType == CityFurnitureTypeNames.fur_doghouse then
        if ModuleRefer.HeroCardModule:CheckIsOpenGacha() then
            return LegoUIPage_SpecialData.new("sp_activity_growth_img_hero_2", "system_gacha_title_short", "system_gacha_title_short", function()
                g_Game.UIManager:CloseByName(UIMediatorNames.CityLegoBuildingUIMediator)
                g_Game.UIManager:Open(UIMediatorNames.HeroCardMediator)
            end)
        end
    elseif furType == CityFurnitureTypeNames.fur_equipproduce then
        if ModuleRefer.HeroModule:CheckIsOpenEquip() then
            return LegoUIPage_SpecialData.new("sp_activity_growth_img_hero_2", "equip_build", "equip_build", function()
                g_Game.UIManager:CloseByName(UIMediatorNames.CityLegoBuildingUIMediator)
                g_Game.UIManager:Open(UIMediatorNames.HeroEquipForgeRoomUIMediator)
            end)
        end
    elseif furType == CityFurnitureTypeNames.radartable then
        if ModuleRefer.RadarModule:CheckIsUnlockRadar() then
            return LegoUIPage_SpecialData.new("sp_activity_growth_img_hero_2", "leida_title", "leida_title", function()
                ModuleRefer.RadarModule:SetRadarState(true)
                local param = {isInCity = true, stack = self.city.camera and self.city.camera:RecordCurrentCameraStatus()}
                g_Game.UIManager:CloseByName(UIMediatorNames.CityLegoBuildingUIMediator)
                g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)
            end)
        end
    elseif furType == ModuleRefer.ReplicaPVPModule:EntryCityFurnitureId() then
        if ModuleRefer.ReplicaPVPModule:CheckIsUnlock() then
            local text = ConfigRefer.ReplicaPvpConst:EntryText()
            return LegoUIPage_SpecialData.new("sp_activity_growth_img_hero_2", text, text, function()
                g_Game.UIManager:CloseByName(UIMediatorNames.CityLegoBuildingUIMediator)
                g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPMainMediator)
            end)
        end
    elseif furType == ModuleRefer.EarthRevivalModule:GetWorldTrendFurnitureId() then
        if ModuleRefer.EarthRevivalModule:CheckIsUnlock() then
            return LegoUIPage_SpecialData.new("sp_city_img_room_world", "worldstage_csjh", "worldstage_csjh", function()
                g_Game.UIManager:CloseByName(UIMediatorNames.CityLegoBuildingUIMediator)
                ModuleRefer.EarthRevivalModule:OpenEarthRevivalMediator()
            end)
        end
    end
    
    return nil
end

return CityLegoBuildingUIParameter