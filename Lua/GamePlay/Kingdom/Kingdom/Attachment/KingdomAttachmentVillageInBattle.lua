local KingdomAttachmentBase = require("KingdomAttachmentBase")
local KingdomEntityDataWrapperFactory = require("KingdomEntityDataWrapperFactory")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")

---@class KingdomAttachmentVillageInBattle : KingdomAttachmentBase
---@field handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
local KingdomAttachmentVillageInBattle = class("KingdomAttachmentVillageInBattle", KingdomAttachmentBase)

---@param go CS.UnityEngine.GameObject
---@param brief wds.MapEntityBrief
local function OnInBattleLoaded(go, brief)
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(brief.ObjectType)
    local position = wrapper:GetCenterPosition(brief)
    go.transform.position = position

    ---@type PvPTileAssetHUDFightingBehavior
    local behavior = go:GetLuaBehaviour("PvPTileAssetHUDFightingBehavior").Instance
    local isDeclaredByMyAlliance = ModuleRefer.VillageModule:IsVillageInBattle(brief.ObjectId)
    behavior:SetColor(isDeclaredByMyAlliance)
    behavior:VXTrigger()
end

---@param brief wds.MapEntityBrief
---@param lod number
function KingdomAttachmentVillageInBattle:Show(brief, lod)
    if not KingdomMapUtils.CheckIconLodByFixedConfig(brief.CfgId, lod) then
        return
    end
    
    if not self:CheckInBattle(brief) then
        return
    end

    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(brief.ObjectType)
    if wrapper then
        local coord = wrapper:GetCenterCoordinate(brief)
        if ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y) then
            if not self.handle then
                self.handle = self.createHelper:Create(ManualResourceConst.ui3d_world_battle, self.mapSystem.Parent, OnInBattleLoaded, brief)
            end
        end
    end
end

function KingdomAttachmentVillageInBattle:Hide()
    if self.handle then
        self.handle:Delete()
    end
end

function KingdomAttachmentVillageInBattle:OnLodChange(oldLod, newLod)

end

---@param brief wds.MapEntityBrief
function KingdomAttachmentVillageInBattle:CheckInBattle(brief)
    return brief.InBattle or ModuleRefer.VillageModule:IsVillageInBattle(brief.ObjectId)
end

return KingdomAttachmentVillageInBattle