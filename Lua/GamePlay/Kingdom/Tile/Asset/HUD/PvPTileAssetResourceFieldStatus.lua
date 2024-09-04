local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetResourceFieldStatus : PvPTileAssetUnit
local PvPTileAssetResourceFieldStatus = class("PvPTileAssetResourceFieldStatus", PvPTileAssetUnit)

function PvPTileAssetResourceFieldStatus:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetResourceFieldStatus:GetLodPrefabName(lod)
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if entity.Owner.PlayerID == 0 or entity.Owner.PlayerID == player.ID or entity.Army and entity.Army.InBattle then
        return string.Empty
    end
    
    if not KingdomMapUtils.InSymbolMapLod(lod) then
        return ManualResourceConst.ui3d_bubble_map_resource_field_status
    end
    return string.Empty
end

function PvPTileAssetResourceFieldStatus:OnConstructionSetup()
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return
    end
    
    local go = self.handle.Asset
    if Utils.IsNull(go) then
        return
    end
    
    local luaBehavior = go:GetLuaBehaviour("PvPTileAssetResourceFieldStatusBehavior")
    if Utils.IsNull(luaBehavior) then
        return
    end
    ---@type PvPTileAssetResourceFieldStatusBehavior
    local behavior = luaBehavior.Instance
    
    local owner = entity.Owner
    local sprite = string.Empty
    if ModuleRefer.PlayerModule:IsMine(owner) then
        sprite = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_img_state_base_1)
    elseif ModuleRefer.PlayerModule:IsFriendly(owner) then
        sprite = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_img_state_base_2)
    else
        sprite = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_img_state_base_4)
    end
    behavior:SetBaseSprite(sprite)
end

function PvPTileAssetResourceFieldStatus:OnConstructionShutdown()
end
    
return PvPTileAssetResourceFieldStatus