local ObjectType = require("ObjectType")

---@class KingdomEntityDataWrapperFactory
local KingdomEntityDataWrapperFactory = class("KingdomEntityDataWrapperFactory")

local ObjectTypeToWrapper =
{
    [ObjectType.SlgCastle] = require("KingdomCastleDataWrapper").new(),
    [ObjectType.SlgVillage] = require("KingdomLandmarkDataWrapper").new(),
    [ObjectType.Pass] = require("KingdomLandmarkDataWrapper").new(),
    --[ObjectType.SlgExpedition] = require("KingdomExpeditionDataWrapper").new(),
    [ObjectType.BehemothCage] = require("KingdomLandmarkDataWrapper").new(),
}

local TypeToPrefabName =
{
    [ObjectType.SlgCastle] = "ui3d_building_lod",
    [ObjectType.SlgVillage] = "ui3d_building_lod",
    [ObjectType.Pass] = "ui3d_building_lod",
    --[ObjectType.SlgExpedition] = "ui3d_world_events_lod",
    [ObjectType.BehemothCage] = "ui3d_building_lod",
}

---@return string
function KingdomEntityDataWrapperFactory.GetPrefabName(type)
    return TypeToPrefabName[type]
end

---@param type number
---@return KingdomEntityDataWrapper
function KingdomEntityDataWrapperFactory.GetDataWrapper(type)
    return ObjectTypeToWrapper[type]
end

return KingdomEntityDataWrapperFactory