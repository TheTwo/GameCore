local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")

local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetVillageAllianceCenter:PvPTileAssetUnit
---@field new fun():PvPTileAssetVillageAllianceCenter
---@field super PvPTileAssetUnit
local PvPTileAssetVillageAllianceCenter = class('PvPTileAssetVillageAllianceCenter', PvPTileAssetUnit)

function PvPTileAssetVillageAllianceCenter:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnVillageStatusChanged))
end

function PvPTileAssetVillageAllianceCenter:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnVillageStatusChanged))
end

function PvPTileAssetVillageAllianceCenter:GetLodPrefabName(lod)
    ---@type wds.Village
    local data = self:GetData()
    if not data or not ModuleRefer.VillageModule:IsAllianceCenter(data) then
        return string.Empty
    end
    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(data.MapBasics.ConfID, lod) then
        local allianceCenterConfig = ConfigRefer.AllianceCenter:Find(ConfigRefer.FixedMapBuilding:Find(data.MapBasics.ConfID):BuildAllianceCenter())
        return allianceCenterConfig:AttachAsset()
    end
    return string.Empty
end

---@param entity wds.Village
function PvPTileAssetVillageAllianceCenter:OnVillageStatusChanged(entity, _)
    ---@type wds.Village
    local data = self:GetData()
    if not data or not entity or data.ID ~= entity.ID then return end
    self:Refresh()
end

return PvPTileAssetVillageAllianceCenter
