local CityTileBase = require("CityTileBase")
---@class CityCellTile:CityTileBase
---@field new fun(gridView:CityGridView, x:number, y:number):CityCellTile
local CityCellTile = class("CityCellTile", CityTileBase)
local CityUtils = require("CityUtils")
local ConfigRefer = require("ConfigRefer")
local CityTilePriority = require("CityTilePriority")
local CityConst = require("CityConst")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ModuleRefer = require("ModuleRefer")
local CityConstructState = require("CityConstructState")

function CityCellTile:GetPriority()
    local cell = self:GetCell()
    if cell:IsBuilding() then
        return CityTilePriority.BUILDING
    elseif cell:IsNpc() then
        return CityTilePriority.NPC
    elseif cell:IsResource() then
        return CityTilePriority.RESOURCE
    elseif cell:IsCreepNode() then
        return CityTilePriority.CREEP_NODE
    end
    return 0
end

function CityCellTile:GetCameraSize()
    local gridCell = self:GetCell()
    if gridCell:IsBuilding() then
        return CityConst.BUILDING_MAX_VIEW_SIZE
    elseif gridCell:IsResource() then
        return CityConst.RESOURCE_MAX_VIEW_SIZE
    elseif gridCell:IsNpc() then
        return CityConst.NPC_MAX_VIEW_SIZE
    elseif gridCell:IsCreepNode() then
        return CityConst.NPC_MAX_VIEW_SIZE
    else
        g_Logger.Error("未配置镜头参数")
        return CityConst.BUILDING_MAX_VIEW_SIZE
    end
end

---@return CityGridCell
function CityCellTile:GetCell()
    return self.gridView.grid:GetCell(self.x, self.y)
end

function CityCellTile:Moveable()
    if self:GetCell():IsBuilding() then
        local lvCell = ConfigRefer.BuildingLevel:Find(self:GetCell().configId)
        local config = ConfigRefer.BuildingTypes:Find(lvCell:Type())
        local building = self:GetCity().buildingManager:GetBuilding(self:GetCell().tileId)
        return config and config:Moveable() and not building:IsPolluted()
    end
    return false
end

function CityCellTile:GetNotMovableReason()
    if self:GetCell():IsBuilding() then
        local lvCell = ConfigRefer.BuildingLevel:Find(self:GetCell().configId)
        local config = ConfigRefer.BuildingTypes:Find(lvCell:Type())
        local building = self:GetCity().buildingManager:GetBuilding(self:GetCell().tileId)
        if building:IsPolluted() then
            return I18N.GetWithParams("tips_polluted_cant_move", I18N.Get(config:Name()))
        else
            return I18N.Get("errCode_46006")
        end
    end
    return CityTileBase.GetNotMovableReason(self)
end

function CityCellTile:GetBuildingLevelConfigCell()
    local cell = self:GetCell()
    if cell == nil then
        return nil
    end
    return ConfigRefer.BuildingLevel:Find(cell.configId)
end

function CityCellTile:GetBuildingType()
    local cell = self:GetCell()
    if cell == nil then
        return nil
    end

    if not cell:IsBuilding() then
        return nil
    end

    local lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    if lvCell == nil then
        return nil
    end

    return lvCell:Type()
end

---@return BuildingTypesConfigCell|nil
function CityCellTile:GetBuildingTypesConfigCell()
    local typ = self:GetBuildingType()
    if typ == nil then
        return nil
    end
    return ConfigRefer.BuildingTypes:Find(typ)
end

---@return wds.CastleBuildingInfo|nil
function CityCellTile:GetCastleBuildingInfo()
    local cell = self:GetCell()
    if cell == nil then
        return nil
    end

    if not cell:IsBuilding() then
        return nil
    end

    local city = self:GetCity()
    if not city then
        return nil
    end

    local castle = city:GetCastle()
    return castle.BuildingInfos[cell.tileId]
end

function CityCellTile:GetBuildingName()
    local cell = self:GetCell()
    if not cell:IsBuilding() then
        return string.Empty
    end

    local city = self:GetCity()
    local name = I18N.Get(self:GetBuildingTypesConfigCell():Name())
    if not city:IsMyCity() then
        return name
    end

    return name
end

function CityCellTile:GetBuilding()
    local cell = self:GetCell()
    if not cell:IsBuilding() then
        return nil
    end
    local city = self:GetCity()
    return city.buildingManager:GetBuilding(cell.tileId)
end

function CityCellTile:CanUpgrade()
    local cell = self:GetCell()
    if not cell:IsBuilding() then
        return false
    end

    local lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    if not lvCell then
        return false
    end

    local nextLvCell = ConfigRefer.BuildingLevel:Find(lvCell:NextLevel())
    if not nextLvCell then
        return false
    end

    return ModuleRefer.CityConstructionModule:GetBuildingLevelState(nextLvCell, true) == CityConstructState.CanBuild
end

function CityCellTile:IsConstruction()
    local castleBuilding = self:GetCastleBuildingInfo()
    if castleBuilding == nil then return false end

    return CityUtils.IsConstruction(castleBuilding.Status)    
end

function CityCellTile:IsRoofHide()
    return self:GetCity().roofHide and not self:IsConstruction()
end

function CityCellTile:GetSelectorPrefabName()
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_map_building_selector)
end

function CityCellTile:GetSelectorBehaviourName()
    return "CityBuildingSelector"
end

function CityCellTile:BlockTriggerExecute()
    local city = self:GetCity()
    return city.gridLayer:IsInnerBuildingMask(self.x, self.y) and not city.roofHide
end

function CityCellTile:IsInner()
    local city = self:GetCity()
    return city.gridLayer:IsInnerBuildingMask(self.x, self.y)
end

function CityCellTile:IsFogMask()
    local city = self:GetCity()
    return city:IsFogMaskRect(self.x, self.y, self:SizeX(), self:SizeY())
end

return CityCellTile