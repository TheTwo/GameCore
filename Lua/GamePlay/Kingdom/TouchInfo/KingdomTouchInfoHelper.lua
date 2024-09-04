local MapUtils = CS.Grid.MapUtils
local KingdomMapUtils = require('KingdomMapUtils')
local ModuleRefer = require("ModuleRefer")
local KingdomTouchInfoCompHelper = require('KingdomTouchInfoCompHelper')
local KingdomTouchInfoOperation = require('KingdomTouchInfoOperation')
local AllianceAuthorityItem = require('AllianceAuthorityItem')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')


---@class KingdomTouchInfoHelper
local KingdomTouchInfoHelper = class("KingdomTouchInfoHelper")

---@param coord CS.DragonReborn.Vector2Short
function KingdomTouchInfoHelper.GetWorldPosition(tileX, tileZ)
    local mapSystem = KingdomMapUtils.GetMapSystem()
    local position = MapUtils.CalculateCoordToTerrainPosition(tileX, tileZ, mapSystem)
    return position
end

---@param entity wds.CastleBrief
function KingdomTouchInfoHelper.StrongholdLevel(entity)
    local BuildingType = require("BuildingType")
    for k, v in pairs(entity.Castle.BuildingInfos) do
        if v.BuildingType == BuildingType.Stronghold then
            return v.Level
        end
    end
    return 0
end

function KingdomTouchInfoHelper:CreateAttrData(attrGroupId)
    local attrGroupCfg = ConfigRefer.AttrGroup:Find(attrGroupId)
    local attrList = {}
    if attrGroupCfg then
        for i = 1 , attrGroupCfg:AttrListLength() do
            local attrCfg = attrGroupCfg:AttrList(i)
            local typeId = attrCfg:TypeId()
            local attrTypeCfg = ConfigRefer.AttrElement:Find(typeId)
            local name = I18N.Get(attrTypeCfg:Name())
            attrList[#attrList + 1] = {attrTypeCfg:Icon(), name, ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrTypeCfg, attrCfg:Value())}
        end
    end
    return attrList
end

---@param tile MapRetrieveResult
---@return CS.UnityEngine.Vector3
---@return number
---@return number
function KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    if not tile.entity then
        local position = KingdomTouchInfoHelper.GetWorldPosition(tile.X, tile.Z)
        return position, 0, 0
    end
    local margin = 0--KingdomMapUtils.GetLayoutMargin(tile.entity.MapBasics.LayoutCfgId)
    local position = KingdomTouchInfoHelper.GetWorldPosition(tile.X - margin, tile.Z - margin)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(tile.entity)
    local sizeX = (layout.SizeX + 2 * margin) * KingdomMapUtils.GetStaticMapData().UnitsPerTileX
    local sizeY = (layout.SizeY + 2 * margin) * KingdomMapUtils.GetStaticMapData().UnitsPerTileZ
    return position, sizeX, sizeY
end

---@param tile MapRetrieveResult
---@return CS.UnityEngine.Vector3
---@return number
---@return number
function KingdomTouchInfoHelper.CalculatePlayerSlgInteractorDisplayPositionAndMargin(tile)
    if not tile.playerUnit then
        local position = KingdomTouchInfoHelper.GetWorldPosition(tile.X, tile.Z)
        return position, 0, 0
    end
    local position = KingdomTouchInfoHelper.GetWorldPosition(tile.X, tile.Z)
    local conf = ConfigRefer.Mine:Find(tile.playerUnit.MineCfgId)
    if not conf then
        return position, 0, 0
    end
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(conf:MapLayout())
    local sizeX = layout.SizeX * KingdomMapUtils.GetStaticMapData().UnitsPerTileX
    local sizeY = layout.SizeY * KingdomMapUtils.GetStaticMapData().UnitsPerTileZ
    return position, sizeX, sizeY
end

return KingdomTouchInfoHelper