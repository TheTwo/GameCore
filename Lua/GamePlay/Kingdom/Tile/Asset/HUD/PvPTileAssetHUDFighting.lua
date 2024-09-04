local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

local ColorUtility = CS.UnityEngine.ColorUtility

---@class PvPTileAssetHUDFighting : PvPTileAssetHUDIcon
local PvPTileAssetHUDFighting = class("PvPTileAssetHUDFighting", PvPTileAssetHUDIcon)

function PvPTileAssetHUDFighting:CanShow()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return false
    end

    return self:InBattle(entity)
end

function PvPTileAssetHUDFighting:GetLodPrefabName(lod)
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    if KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapIconLod(lod) then
        if self:InBattle(entity) then
            return ManualResourceConst.ui3d_world_battle
        end
    end
    return string.Empty
end

function PvPTileAssetHUDFighting:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetHUDFighting:OnConstructionSetup()

    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return
    end

    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end

    ---@type PvPTileAssetHUDFightingBehavior
    local luaBehavior = asset:GetLuaBehaviour("PvPTileAssetHUDFightingBehavior")
    local behavior = luaBehavior.Instance
    local isDeclaredByMyAlliance
    if entity.Village then
        isDeclaredByMyAlliance = ModuleRefer.VillageModule:IsVillageInBattle(entity.ID)
    elseif entity.PassInfo then
        isDeclaredByMyAlliance = ModuleRefer.GateModule:IsInBattle(entity.ID)
    end

    behavior:SetColor(isDeclaredByMyAlliance)
    behavior:VXTrigger()

end

---@param entity wds.Village
function PvPTileAssetHUDFighting:InBattle(entity)
    if entity.Village then
        return entity.Village.InBattle or ModuleRefer.VillageModule:IsVillageInBattle(entity.ID)
    elseif entity.PassInfo then
        return entity.PassInfo.InBattle or ModuleRefer.GateModule:IsInBattle(entity.ID)
    end
end
return PvPTileAssetHUDFighting
