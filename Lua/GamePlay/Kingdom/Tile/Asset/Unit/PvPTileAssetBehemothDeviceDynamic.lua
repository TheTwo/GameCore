local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local SlgUtils = require("SlgUtils")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetBehemothDeviceDynamic:PvPTileAssetUnit
---@field new fun():PvPTileAssetBehemothDeviceDynamic
---@field super PvPTileAssetUnit
local PvPTileAssetBehemothDeviceDynamic = class('PvPTileAssetBehemothDeviceDynamic', PvPTileAssetUnit)

function PvPTileAssetBehemothDeviceDynamic:ctor()
    PvPTileAssetBehemothDeviceDynamic.super.ctor(self)
    self._isCurrentMyType = false
    ---@type CS.DragonReborn.SLG.Troop.TroopData
    self._dummyTroopEcsEntityData = nil
end

function PvPTileAssetBehemothDeviceDynamic:CanShow()
    self._isCurrentMyType = false
    ---@type wds.CommonMapBuilding
    local data = self:GetData()
    if not data then return false end
    local buildConfig = ConfigRefer.FlexibleMapBuilding:Find(data.MapBasics.ConfID)
    if not buildConfig or buildConfig:Type() ~= FlexibleMapBuildingType.BehemothDevice then return false end
    self._isCurrentMyType = true
    return true
end

function PvPTileAssetBehemothDeviceDynamic:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CommonMapBuilding.BehemothDeviceInfo.BindingBehemothBuildingCfgId.MsgPath, Delegate.GetOrCreate(self, self.OnMpaBuildingBindChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, Delegate.GetOrCreate(self, self.OnAllianceBehemothMobileFortressChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, Delegate.GetOrCreate(self, self.OnAllianceBehemothMobileFortressChanged))
end

function PvPTileAssetBehemothDeviceDynamic:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CommonMapBuilding.BehemothDeviceInfo.BindingBehemothBuildingCfgId.MsgPath, Delegate.GetOrCreate(self, self.OnMpaBuildingBindChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, Delegate.GetOrCreate(self, self.OnAllianceBehemothMobileFortressChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, Delegate.GetOrCreate(self, self.OnAllianceBehemothMobileFortressChanged))
end

---@param entity wds.CommonMapBuilding
function PvPTileAssetBehemothDeviceDynamic:OnMpaBuildingBindChanged(entity)
    if not self._isCurrentMyType then return end
    local data = self:GetData()
    if not entity or not data or data.ID ~= entity.ID then return end
    if self._dummyTroopEcsEntityData then
        self:ReleaseBehemoth()
        self:RebuildBehemoth()
    else
        self:Refresh() 
    end
end

function PvPTileAssetBehemothDeviceDynamic:GetLodPrefabName(lod)
    if not self._isCurrentMyType then return string.Empty end
    ---@type wds.CommonMapBuilding
    local data = self:GetData()
    if not data then
        return string.Empty
    end
    if ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(data) then return string.Empty end
    if KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(data.MapBasics.ConfID, lod) then return string.Empty end
    if ModuleRefer.AllianceModule:IsInAlliance() and data.Owner.AllianceID == ModuleRefer.AllianceModule:GetAllianceId() then
        local summonInfo = ModuleRefer.AllianceModule.Behemoth:GetCurrentInSummonBehemothInfo()
        if summonInfo and summonInfo:GetVanishTime() > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then return string.Empty end
    end
    return ManualResourceConst.behemoth_device_container
end

function PvPTileAssetBehemothDeviceDynamic:OnConstructionSetup()
    self:RebuildBehemoth()
end

function PvPTileAssetBehemothDeviceDynamic:RebuildBehemoth()
    local go = self:GetAsset()
    if Utils.IsNull(go) then return end
    ---@type wds.CommonMapBuilding
    local data = self:GetData()
    if not data then return end
    ---@type KmonsterDataConfigCell
    local kMonsterConfig = nil
    if data.BehemothDeviceInfo.BindingBehemothBuildingCfgId ~= 0 then
        local cageBuildingConfig = ConfigRefer.FixedMapBuilding:Find(data.BehemothDeviceInfo.BindingBehemothBuildingCfgId)
        if cageBuildingConfig then
            local cageBehemoth = ConfigRefer.BehemothCage:Find(cageBuildingConfig:BehemothCageConfig())
            if cageBehemoth then
                local index = math.clamp(data.BehemothDeviceInfo.Level, 1, cageBehemoth:BehemothTroopMonsterLength())
                kMonsterConfig = ConfigRefer.KmonsterData:Find(cageBehemoth:BehemothTroopMonster(index))
            end
        end
    end
    if not kMonsterConfig then
        local buildConfig = ConfigRefer.FlexibleMapBuilding:Find(data.MapBasics.ConfID)
        local deviceConfig = ConfigRefer.BehemothDevice:Find(buildConfig:BehemothDeviceConfig())
        local index = math.clamp(data.BehemothDeviceInfo.Level, 1, deviceConfig:BehemothTroopMonsterLength())
        kMonsterConfig = ConfigRefer.KmonsterData:Find(deviceConfig:BehemothTroopMonster(index))
    end
    if not kMonsterConfig then return end
    local troopMgr = ModuleRefer.SlgModule.troopManager
    local troopData = g_Game.TroopViewManager:GetTroopEntityData()
    troopData.id = data.ID
    local troopRadius = troopMgr:CalcTroopRadius(data)
    troopData.radius = troopRadius
    ModuleRefer.SlgModule.troopManager:FillBehemothECSDataFromMonsterConfig(kMonsterConfig, troopData)
    troopMgr:SetupTroopMapData(data,troopData)
    local coordPos = self:CalculateCenterPosition()
    local offset = require("PvPTileAssetBehemothDeviceDynamicPosAndRotationFix")
    troopData.direction = offset.Direction
    coordPos = coordPos + offset.Position
    troopData.position = coordPos
    troopData.heroAIType = SlgUtils.AIType.Hero
    troopData.troopType = SlgUtils.TroopType.Boss
    troopData.serverType = SlgUtils.ServerType.Building
    self._dummyTroopEcsEntityData = troopData
    g_Game.TroopViewManager:CreateTroopViewEntity(troopData, go)
end

function PvPTileAssetBehemothDeviceDynamic:ReleaseBehemoth()
    if self._dummyTroopEcsEntityData then
        g_Game.TroopViewManager:DelTroopViewEntity(self._dummyTroopEcsEntityData.id)
    end
    self._dummyTroopEcsEntityData = nil
end

function PvPTileAssetBehemothDeviceDynamic:OnConstructionShutdown()
    self:ReleaseBehemoth()
end

function PvPTileAssetBehemothDeviceDynamic:OnAllianceBehemothMobileFortressChanged()
    if not self._isCurrentMyType then return end
    ---@type wds.CommonMapBuilding
    local data = self:GetData()
    if not data then return end
    if not ModuleRefer.AllianceModule:IsInAlliance() then return end
    if data.Owner.AllianceID ~= ModuleRefer.AllianceModule:GetAllianceId() then return end
    self:Refresh()
end

return PvPTileAssetBehemothDeviceDynamic