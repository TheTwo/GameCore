---@class CityFurnitureCircleMenuHelper
local CityFurnitureCircleMenuHelper = {}
local this = CityFurnitureCircleMenuHelper
local ConfigRefer = require("ConfigRefer")
local TouchMenuMainBtnGroupData = require("TouchMenuMainBtnGroupData")
local UIMediatorNames = require("UIMediatorNames")
local TouchMenuBasicInfoDatum = require("TouchMenuBasicInfoDatum")
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")
local CityCitizenDefine = require("CityCitizenDefine")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuPageDatum = require("TouchMenuPageDatum")
local CityFurnitureFunctionCollection = require("CityFurnitureFunctionCollection")
local TouchMenuUIDatum = require("TouchMenuUIDatum")
local TouchMenuHelper = require("TouchMenuHelper")

---@param tile CityFurnitureTile
function CityFurnitureCircleMenuHelper.GetTouchInfoData(tile)
    local cell = tile:GetCell()
    if cell == nil then
        return nil
    end

    local levelCell = cell.furnitureCell
    if levelCell == nil then
        return nil
    end

    local typCell = ConfigRefer.CityFurnitureTypes:Find(levelCell:Type())
    if typCell == nil then
        return nil
    end

    local furnitureInfo = tile:GetCastleFurniture()
    if furnitureInfo == nil then
        return nil
    end

    local btns = {}
    if not CityCitizenDefine.CityFurnitureProduceBoxTypeIds[levelCell:Type()] and not CityCitizenDefine.CityCollectBoxTypeIds[levelCell:Type()] then
        if levelCell:WorkAbilityLength() > 0 then
            this.GenerateFunctionalButton(btns, tile, typCell, levelCell, furnitureInfo)
        end
    end
    this.AddFunctionalButtons(btns, tile, typCell, levelCell, furnitureInfo)
    local basicData = TouchMenuBasicInfoDatum.new(I18N.Get(typCell:Name()), ArtResourceUtils.GetUIItem(typCell:Image()), ("X:%d Y:%d"):format(tile.x, tile.y))
    local buttonGroupData = TouchMenuHelper.GetRecommendButtonGroupDataArray(btns)
    local pageDatum = TouchMenuPageDatum.new(basicData, nil, buttonGroupData)
    return TouchMenuUIDatum.new(pageDatum):SetPos(tile:GetWorldCenter())
end

---@param btnArray TouchInfoCompDatum[]
---@param tile CityFurnitureTile
---@param typeCell CityFurnitureTypesConfigCell
---@param lvCell CityFurnitureLevelConfigCell
---@param info wds.CastleFurniture
function CityFurnitureCircleMenuHelper.GenerateFunctionalButton(btnArray, tile, typeCell, lvCell, info)
    local callback = function()
        local city = tile:GetCity()
        city.stateMachine:ChangeState(city:GetSuitableIdleState(city.cameraSize))
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureConstructionProcessUIMediator, {city = city,furniture = tile:GetCell()})
    end
    local item = TouchMenuMainBtnDatum.new(I18N.Get("crafting_btn_start"), callback)
    table.insert(btnArray, item)
end

---@private
---@param btnArray TouchInfoCompDatum[]
---@param tile CityFurnitureTile
---@param typeCell CityFurnitureTypesConfigCell
---@param lvCell CityFurnitureLevelConfigCell
---@param info wds.CastleFurniture
---家具具体的功能按钮
function CityFurnitureCircleMenuHelper.AddFunctionalButtons(btnArray, tile, typeCell, lvCell, info)
    local furnitureType = lvCell:Type()
    local itemGenerator = CityFurnitureFunctionCollection[furnitureType]
    if itemGenerator then
        local item = itemGenerator(tile, typeCell, lvCell, info)
        if item then
            table.insert(btnArray, item)
        end
    end
end

return CityFurnitureCircleMenuHelper