---@class CityNode
---@field new fun(x, y, sizeX, sizeY, tileId, configId, configType):CityNode
local CityNode = class("CityNode")
local ConfigRefer = require("ConfigRefer")
local CityGridCellDef = require("CityGridCellDef")
local ModuleRefer = require("ModuleRefer")
local CityUtils = require("CityUtils")
local ConfigType = CityGridCellDef.ConfigType
local PublicNode = nil
local TypStr = {[ConfigType.BUILDING] = "建筑", [ConfigType.FURNITURE] = "家具", [ConfigType.NPC] = "NPC", [ConfigType.RESOURCE] = "资源点", [ConfigType.CREEP_NODE] = "菌毯节点&核心", [ConfigType.INVALID] = "未知"}

function CityNode.Temp(x, y, sizeX, sizeY, tileId, configId, configType)
    if not PublicNode then
        PublicNode = CityNode.new(x, y, sizeX, sizeY, tileId, configId, configType)
        return PublicNode
    end
    PublicNode.x = x
    PublicNode.y = y
    PublicNode.sizeX = sizeX
    PublicNode.sizeY = sizeY
    PublicNode.tileId = tileId
    PublicNode.configId = configId
    PublicNode.configType = configType
    return PublicNode
end

function CityNode:ctor(x, y, sizeX, sizeY, tileId, configId, configType)
    self.x = x
    self.y = y
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.tileId = tileId
    self.configId = configId
    self.configType = configType
end

function CityNode:MinX()
    return self.x
end

function CityNode:MaxX()
    return self.x + self.sizeX - 1
end

function CityNode:MinY()
    return self.y
end

function CityNode:MaxY()
    return self.y + self.sizeY - 1
end

---@param buildingInfo wds.CastleBuildingInfo
function CityNode.FromCastleBuildingInfo(tileId, buildingInfo, temp)
    local typeCell = ConfigRefer.BuildingTypes:Find(buildingInfo.BuildingType)
    if typeCell == nil then
        g_Logger.Error(("旧数据残留, 找不到类型为%d的建筑配置"):format(buildingInfo.BuildingType))
        return nil
    end
    local levelCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCell(typeCell, buildingInfo.Level)
    if levelCell == nil then
        g_Logger.Error(("旧数据残留, 找不到类型为%d, Lv.%d的建筑配置"):format(buildingInfo.BuildingType, buildingInfo.Level))
        return nil
    end

    local sizeX, sizeY = levelCell:SizeX(), levelCell:SizeY()
    local isUpgrade = CityUtils.IsStatusUpgrade(buildingInfo.Status)
    if isUpgrade then
        local nextLevel = ConfigRefer.BuildingLevel:Find(levelCell:NextLevel())
        sizeX, sizeY = nextLevel:SizeX(), nextLevel:SizeY()
    end

    if temp then
        return CityNode.Temp(buildingInfo.Pos.X, buildingInfo.Pos.Y, sizeX, sizeY, tileId, levelCell:Id(), ConfigType.BUILDING)
    else
        return CityNode.new(buildingInfo.Pos.X, buildingInfo.Pos.Y, sizeX, sizeY, tileId, levelCell:Id(), ConfigType.BUILDING)
    end
end

function CityNode:ToString()
    return string.format("[%s:Id:%d]-(X:%d,Y:%d) (SizeX:%d,SizeY:%d)", TypStr[self.configType], self.configId, self.x, self.y, self.sizeX, self.sizeX)
end

return CityNode