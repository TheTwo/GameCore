local MapTileAssetSolo = require("MapTileAssetSolo")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local MapTileAssetUnit = require("MapTileAssetUnit")
local ManualResourceConst = require("ManualResourceConst")

local Red = CS.UnityEngine.Color(1, 0, 0, 200/255)
local White = CS.UnityEngine.Color(1, 1, 1, 200/255)
local Green = CS.UnityEngine.Color(0, 1, 0, 200/255)
local Blue = CS.UnityEngine.Color(0, 0, 1, 200/255)
local Rotation = CS.UnityEngine.Quaternion.Euler(270, 0, 0)

---@class PvPTileAssetResourceFieldVfx:MapTileAssetUnit
---@field new fun():PvPTileAssetResourceFieldVfx
local PvPTileAssetResourceFieldVfx = class("PvPTileAssetResourceFieldVfx", MapTileAssetUnit)

function PvPTileAssetResourceFieldVfx:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        if KingdomMapUtils.IsMapEntitySelected(self.view:GetUniqueId()) then
            return ManualResourceConst.fx_city_dikuaixuanzhong2shansuo
        else
            return ManualResourceConst.fx_city_dikuaixuanzhong3changtai
        end
    end
    return string.Empty
end

function PvPTileAssetResourceFieldVfx:OnShow()
    g_Game.EventManager:AddListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelect))
    g_Game.EventManager:AddListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselect))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ResourceField.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
end

function PvPTileAssetResourceFieldVfx:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelect))
    g_Game.EventManager:RemoveListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselect))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ResourceField.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
end

function PvPTileAssetResourceFieldVfx:OnSelect(entity)
    if not entity then
        return
    end
    
    local entityId = self.view:GetUniqueId()
    local entityType = self.view:GetTypeId()
    if entityId == entity.ID and entityType == entity.TypeHash then
        self:Refresh()
    end
end

function PvPTileAssetResourceFieldVfx:OnUnselect(entity)
    if not entity then
        return
    end
    local entityId = self.view:GetUniqueId()
    local entityType = self.view:GetTypeId()
    if entityId == entity.ID or entityType == entity.TypeHash then
        self:Refresh()
    end
end

function PvPTileAssetResourceFieldVfx:OnConstructionSetup()
    self:UpdateColor()
end

---@param entity wds.ResourceField
function PvPTileAssetResourceFieldVfx:OnOwnerChanged(entity, _)
    local entityId = self.view:GetUniqueId()
    local entityType = self.view:GetTypeId()
    if entity.ID ~= entityId or entity.TypeHash ~= entityType then
        return
    end
    self:UpdateColor()
end

function PvPTileAssetResourceFieldVfx:GetPosition()
    return self:CalculateCenterPosition() + CS.UnityEngine.Vector3.up * 5
end

function PvPTileAssetResourceFieldVfx:GetScale()
    local entity = g_Game.DatabaseManager:GetEntity(self.view:GetUniqueId(), self.view:GetTypeId())
    if not entity then
        return CS.UnityEngine.Vector3.one
    end
    local cfg = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    local sizeX, sizeY, margin = KingdomMapUtils.GetLayoutSize(cfg:Layout())
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    return CS.UnityEngine.Vector3(staticMapData.UnitsPerTileX * (sizeX + 2), staticMapData.UnitsPerTileZ * (sizeY + 2), 1)
end

function PvPTileAssetResourceFieldVfx:GetRotation()
    return Rotation
end

function PvPTileAssetResourceFieldVfx:UpdateColor()
    local go = self.handle.Asset
    if Utils.IsNull(go) then return end

    local render = go:GetComponent(typeof(CS.UnityEngine.Renderer))
    render.material.color = self:GetColorByOwner()
end

function PvPTileAssetResourceFieldVfx:GetColorByOwner()
    ---@type wds.ResourceField
    local entity = g_Game.DatabaseManager:GetEntity(self.view:GetUniqueId(), self.view:GetTypeId())
    if entity == nil then
        return White
    end

    if ModuleRefer.PlayerModule:IsMine(entity.Owner) then
        return Green
    elseif ModuleRefer.PlayerModule:IsEmpty(entity.Owner) then
        return White
    elseif ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
        return Blue
    else
        return Red
    end
end

return PvPTileAssetResourceFieldVfx