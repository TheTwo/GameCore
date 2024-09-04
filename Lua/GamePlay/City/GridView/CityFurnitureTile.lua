local CityTileBase = require("CityTileBase")
---@class CityFurnitureTile:CityTileBase
---@field new fun(gridView:CityGridView, x:number, y:number):CityFurnitureTile
local CityFurnitureTile = class("CityFurnitureTile", CityTileBase)
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local CityTilePriority = require("CityTilePriority")
local CityConst = require("CityConst")
local CityGridLayerMask = require("CityGridLayerMask")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityCitizenDefine = require("CityCitizenDefine")
local CityUtils = require("CityUtils")
local CityWorkType = require("CityWorkType")
local CityStateI18N = require("CityStateI18N")

function CityFurnitureTile:GetPriority()
    return CityTilePriority.FURNITURE
end

function CityFurnitureTile:GetCameraSize()
    return CityConst.OTHER_MAX_VIEW_SIZE
end

function CityFurnitureTile:GetCell()
    if self.gridView and self.x and self.y then
        return self.gridView.furnitureManager:GetPlaced(self.x, self.y)
    end
    return nil
end

function CityFurnitureTile:IsConfigMovable()
    return self:GetCell():IsConfigMovable()
end

function CityFurnitureTile:IsConfigUnclickable()
    return self:GetCell():IsConfigUnclickable()
end

function CityFurnitureTile:Moveable()
    return self:GetCell():Movable()
end

function CityFurnitureTile:GetNotMovableReason()
    local reason = self:GetCell():GetNotMovableReason()
    if string.IsNullOrEmpty(reason) then
        reason = CityTileBase.GetNotMovableReason(self)
    end
    return reason
end

function CityFurnitureTile:IsOutside()
    return not CityGridLayerMask.HasBuilding(self:GetCity().gridLayer:Get(self.x, self.y))
end

function CityFurnitureTile:GetFurnitureType()
    local cell = self:GetCell()
    if cell == nil then
        return nil
    end
    return cell.furnitureCell:Type()
end

function CityFurnitureTile:GetFurnitureTypesCell()
    local typ = self:GetFurnitureType()
    if typ == nil then
        return nil
    end
    return ConfigRefer.CityFurnitureTypes:Find(typ)
end

---@return wds.CastleFurniture
function CityFurnitureTile:GetCastleFurniture()
    local cell = self:GetCell()
    if cell == nil then
        return nil
    end

    local castle = self:GetCity():GetCastle()
    return castle.CastleFurniture[cell.singleId]
end

function CityFurnitureTile:GetName()
    return I18N.Get(self:GetFurnitureTypesCell():Name())
end

function CityFurnitureTile:GetDescription()
    return I18N.Get(self:GetFurnitureTypesCell():Description())
end

function CityFurnitureTile:GetSelectorPrefabName()
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_map_building_selector)
end

function CityFurnitureTile:GetSelectorBehaviourName()
    return "CityFurnitureSelector"
end

function CityFurnitureTile:IsInner()
    local buildingId = self:GetCastleFurniture().BuildingId
    return buildingId ~= 0 and not self:GetCity().legoManager:DontHasRoof(buildingId)
end

function CityFurnitureTile:SetPositionCenterAndRotation(position, centerPos, rotation)
    self.pos = position
    if self.tileView then
        self.tileView:SetPositionCenterAndRotation(position, centerPos, rotation)
    end
end

function CityFurnitureTile:BlockTriggerExecute()
    return self:IsInner() and not self:GetCity().roofHide
end

function CityFurnitureTile:ShouldShowEntryBubble()
    local typ = self:GetCell().furnitureCell:Type()
    if CityCitizenDefine.IsSpecialFunctionFurniture(typ) or CityCitizenDefine.IsDecorationFurniture(typ) or CityCitizenDefine.IsMilitaryFurniture(typ) then
        return true
    end
    return CityCitizenDefine.IsFurnitureWallOrDoor(typ)
end

function CityFurnitureTile:HasGeneratedRes()
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture == nil then return false end
    return false
end

function CityFurnitureTile:IsFree()
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture == nil then return false end

    return castleFurniture.WorkType2Id:Count() == 0
end

function CityFurnitureTile:HasProcessFinished()
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture == nil then return false end
    
    return castleFurniture.ProcessInfo.FinishNum > 0
end

function CityFurnitureTile:CanStorage()
    return self:CanStorageImp() == 0
end

---@private
function CityFurnitureTile:CanStorageImp()
    if not self:IsFree() then
        return 1
    end

    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture.LevelUpInfo.Working then
        return 2
    end

    return 0
end

function CityFurnitureTile:CantStorageReason()
    local failedCode = self:CanStorageImp()
    if failedCode == 1 then
        local castleFurniture = self:GetCastleFurniture()
        local workType, _ = next(castleFurniture.WorkType2Id)
        if workType == CityWorkType.FurnitureLevelUp then
            return CityStateI18N.FAILED_STORAGE_FOR_DOING_UPGRADE
        elseif workType == CityWorkType.FurnitureResCollect then
            return CityStateI18N.FAILED_STORAGE_FOR_DOING_COLLECT
        elseif workType == CityWorkType.Process then
            return CityStateI18N.FAILED_STORAGE_FOR_DOING_PROCESS
        elseif workType == CityWorkType.ResourceGenerate then
            return CityStateI18N.FAILED_STORAGE_FOR_DOING_PRODUCE
        elseif workType == CityWorkType.MilitiaTrain then
            return CityStateI18N.FAILED_STORAGE_FOR_DOING_MILITIA_TRAIN
        end
    elseif failedCode == 2 then
        return CityStateI18N.FAILED_STORAGE_FOR_NOT_CONFIRM_UPGRADE
    elseif failedCode == 3 then
        return CityStateI18N.FAILED_STORAGE_FOR_NOT_TAKE_PROCESSED
    elseif failedCode == 4 then
        return CityStateI18N.FAILED_STORAGE_FOR_NOT_TAKE_PRODUCED
    elseif failedCode == 5 then
        return CityStateI18N.FAILED_STORAGE_FOR_NOT_TAKE_COLLECTED
    end
    return nil
end

function CityFurnitureTile:GetDirSet()
    local furTypeCfg = self:GetFurnitureTypesCell()
    if furTypeCfg:RotationControl() == 90 then
        return {0, 90}
    elseif furTypeCfg:RotationControl() == -90 then
        return {0, 270}
    else
        return {0, 90, 180, 270}
    end
end

return CityFurnitureTile