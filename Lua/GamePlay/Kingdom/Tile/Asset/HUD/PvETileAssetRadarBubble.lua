local MapTileAssetSolo = require("MapTileAssetSolo")
local ModuleRefer = require("ModuleRefer")
local Utils = require('Utils')
local DBEntityType = require('DBEntityType')
local ManualResourceConst = require("ManualResourceConst")
---@class PvETileAssetRadarBubble : PvPTileAssetUnit
local PvETileAssetRadarBubble = class("PvETileAssetRadarBubble", MapTileAssetSolo)

---@return string
function PvETileAssetRadarBubble:GetLodPrefab(lod)
    if lod >= 3 and lod <= 4 then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

---@return CS.UnityEngine.Vector3
function PvETileAssetRadarBubble:GetPosition()
    return self:CalculateCenterPosition()
end

---@return CS.UnityEngine.Vector3
function PvETileAssetRadarBubble:CalculateCenterPosition()
    local uniqueId = self:GetUniqueId()
    local typeId = self:GetTypeId()
    local staticMapData = self:GetStaticMapData()

    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if entity == nil then
        return string.Empty
    end

    local x = entity.MapBasics.Position.X * staticMapData.UnitsPerTileX
    local z = entity.MapBasics.Position.Y * staticMapData.UnitsPerTileZ

    return CS.UnityEngine.Vector3(x, 0, z)
end

function PvETileAssetRadarBubble:CanShow()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    local mapSystem = self:GetMapSystem()
    local lod = mapSystem.Lod
    local isInLod = lod >= 3 and lod <= 4
    local isInFilter = false
    if self.view.typeId == DBEntityType.ResourceField then
        isInFilter = ModuleRefer.WorldEventModule:GetFilterType() == wrpc.RadarEntityType.RadarEntityType_ResourceField
    end
    return isInLod and isInFilter
end

function PvETileAssetRadarBubble:OnConstructionSetup()
    PvETileAssetRadarBubble.super.OnConstructionSetup(self)
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    local go = self:GetAsset()
    local spriteTrans = go.transform:Find("p_rotation/p_position/p_icon_status")
    if Utils.IsNotNull(spriteTrans) then
        local renderer = spriteTrans:GetComponent(typeof(CS.U2DSpriteMesh))
        if Utils.IsNotNull(renderer) then
            if self.view.typeId == DBEntityType.ResourceField then
                g_Game.SpriteManager:LoadSprite("sp_hero_don_s", renderer)
            end
        end
    end
    self:OnConstructionUpdate()
end

function PvETileAssetRadarBubble:OnConstructionUpdate()
    if self:CanShow() then
        self:Show()
    else
        self:Hide()
    end
end

function PvETileAssetRadarBubble:OnConstructionShutdown()
end

return PvETileAssetRadarBubble