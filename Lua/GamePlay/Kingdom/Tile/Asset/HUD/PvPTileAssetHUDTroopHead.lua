local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local UIHelper = require("UIHelper")
local ManualResourceConst = require("ManualResourceConst")
local DBEntityType = require("DBEntityType")

---@class PvPTileAssetHUDTroopHead : PvPTileAssetUnit
---@field behavior PvPTileAssetHUDTroopHeadBehavior
local PvPTileAssetHUDTroopHead = class("PvPTileAssetHUDTroopHead", PvPTileAssetUnit)

PvPTileAssetHUDTroopHead.TypeHashToEntityArmyDataPath = {
    [DBEntityType.Village] = DBEntityPath.Village.Army.MsgPath,
    [DBEntityType.Pass] = DBEntityPath.Pass.Army.MsgPath,
    [DBEntityType.EnergyTower] = DBEntityPath.EnergyTower.Army.MsgPath,
    [DBEntityType.DefenceTower] = DBEntityPath.DefenceTower.Army.MsgPath,
    [DBEntityType.CommonMapBuilding] = DBEntityPath.CommonMapBuilding.Army.MsgPath,
}

function PvPTileAssetHUDTroopHead:ctor()
    PvPTileAssetHUDTroopHead.super.ctor(self)
    self._dataArmyPath = nil
end

function PvPTileAssetHUDTroopHead:CanShow()
    ---@type wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
    local entity = self:GetData()
    if not entity then
        return false
    end

    local x, y = self:GetServerPosition()
    if not ModuleRefer.MapFogModule:IsFogUnlocked(x, y) then
        return false
    end

    if self:GetMyTroop(entity) or self:NPCBattle(entity) then
        return true
    end
end

function PvPTileAssetHUDTroopHead:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetHUDTroopHead:GetLodPrefabName(lod)
    ---@type wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end

    if KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod) then
        if self:GetMyTroop(entity) or self:NPCBattle(entity) then
            return ManualResourceConst.ui3d_world_defence_troop
        end
    end
    return string.Empty
end

function PvPTileAssetHUDTroopHead:OnShow()
    if self._dataArmyPath then
        g_Game.DatabaseManager:RemoveChanged(self._dataArmyPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    end
    self._dataArmyPath = nil
    local data = self:GetData()
    if data then
        self._dataArmyPath = PvPTileAssetHUDTroopHead.TypeHashToEntityArmyDataPath[data.TypeHash]
    end
    if self._dataArmyPath then
        g_Game.DatabaseManager:AddChanged(self._dataArmyPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    end
end

function PvPTileAssetHUDTroopHead:OnHide()
    if self._dataArmyPath then
        g_Game.DatabaseManager:RemoveChanged(self._dataArmyPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    end
    self._dataArmyPath = nil
end

---@param army wds.Army
function PvPTileAssetHUDTroopHead:OnArmyChanged(army)
    if not self.behavior then
        return
    end

    ---@type wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
    local entity = self:GetData()
    if army.ID ~= entity.Army.ID then
        return
    end
    if self:GetMyTroop(entity) then
        local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetMyTroopHP(entity.Army)
        self.behavior:SetProgress((hpMax > 0) and (hp / hpMax) or 0)
    elseif self:GetNPCTroop(entity) then
        local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetNpcTroopHP(entity.Army)
        self.behavior:SetProgress((hpMax > 0) and (hp / hpMax) or 0)
    else
        self.behavior:SetProgress(1)
    end
    local count = self:GetTroopCount(entity)
    self.behavior:SetMonsterTroopCount(count)
    self.behavior:SetInfected(KingdomMapUtils.IsMapEntityCreepInfected(entity))
end

function PvPTileAssetHUDTroopHead:OnConstructionSetup()
    local entity = self:GetData()
    if not entity then
        self:Hide()
        return
    end

    local asset = self:GetAsset()
    self.behavior = asset:GetLuaBehaviour("PvPTileAssetHUDTroopHeadBehavior").Instance
    if not self.behavior then
        self:Hide()
        return
    end
    self:OnRefresh(entity)
    self.behavior:SetTrigger(Delegate.GetOrCreate(self, self.OnIconClick))
end

function PvPTileAssetHUDTroopHead:OnConstructionShutdown()
    self.behavior = nil
    PvPTileAssetHUDTroopHead.super.OnConstructionShutdown(self)
end

function PvPTileAssetHUDTroopHead:OnConstructionUpdate()
    local entity = self:GetData()
    if not entity then
        self:Hide()
        return
    end

    if not self.behavior then
        return
    end

    self:OnRefresh(entity)
end

---@param entity wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
function PvPTileAssetHUDTroopHead:OnRefresh(entity)
    self:OnArmyChanged(entity.Army)

    local isInfected = KingdomMapUtils.IsMapEntityCreepInfected(entity)
    local validTroop = self:GetMyTroop(entity) or self:GetNPCTroop(entity)
    if validTroop then
        local headName = ModuleRefer.MapBuildingTroopModule:GetTroopHeroSpriteName(validTroop)
        local frameName = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_frame_c)
        self.behavior:SetHead(headName)
        self.behavior:SetFrame(frameName)
        local count = self:GetTroopCount(entity)
        self.behavior:SetMonsterTroopCount(count)
        self.behavior:SetInfected(isInfected)
        return
    end
    if entity.TypeHash ~= wds.Village.TypeHash and entity.TypeHash ~= wds.Pass.TypeHash then
        return
    end
    if not entity.Army.DummyTroopInitFinish then
        local heroConfig,troopCount = self:GetNPCTroopHeroConfig(entity)
        local headName = ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
        local frameName = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_frame_c)
        self.behavior:SetHead(headName)
        self.behavior:SetFrame(frameName)
        local count = self:GetTroopCount(entity)
        self.behavior:SetMonsterTroopCount(count)
        self.behavior:SetInfected(isInfected)
        return
    end
end

function PvPTileAssetHUDTroopHead:OnIconClick()
    local x, z = self:GetServerPosition()
    local tile = KingdomMapUtils.RetrieveMap(x, z)
    ModuleRefer.MapBuildingTroopModule:ShowTroopInfo(tile)
end

---@param entity wds.Village
---@return wds.ArmyMemberInfo
function PvPTileAssetHUDTroopHead:GetNPCTroopHeroConfig(entity)
    local buildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    if buildingConfig:InitTroopsLength() == 0 then
        return nil
    end

    local monsterConfigID = buildingConfig:InitTroops(1)
    local monsterConfig = ConfigRefer.KmonsterData:Find(monsterConfigID)
    if monsterConfig:HeroLength() > 0 then
        local heroConfigID = monsterConfig:Hero(1):HeroConf()
        local heroNpcConfig = ConfigRefer.HeroNpc:Find(heroConfigID)
        return ConfigRefer.Heroes:Find(heroNpcConfig:HeroConfigId())
    end
    return nil
end

---@param entity wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
---@return wds.ArmyMemberInfo
function PvPTileAssetHUDTroopHead:GetMyTroop(entity)
    return ModuleRefer.MapBuildingTroopModule:GetMyTroop(entity.Army)
end

---@param entity wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
---@return wds.ArmyMemberInfo
function PvPTileAssetHUDTroopHead:GetTroopCount(entity)
    local army = entity.Army
    if not army then return nil end
    local count = nil
    ---@param armyMemberInfo wds.ArmyMemberInfo
    for _,armyMemberInfo in pairs(army.PlayerTroopIDs) do
        ---@type wds.Troop
        if armyMemberInfo then
            if ModuleRefer.PlayerModule:IsMineById(armyMemberInfo.PlayerId) then
                count = (count or 0) + 1
            end
        end
    end
    if count then return count end
    if army.DummyTroopIDs then
        for _, armyMemberInfo in pairs(army.DummyTroopIDs) do
            if armyMemberInfo.Hp > 0 then
                count = (count or 0) + 1
            end
        end
    end
    return count
end

---@param entity wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
function PvPTileAssetHUDTroopHead:NPCBattle(entity)
    local warStatus
    if entity.Village then
        warStatus = ModuleRefer.VillageModule:GetVillageWarStatus(entity.ID, ModuleRefer.AllianceModule:GetAllianceId())
        return warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder and entity.Village.InBattle
    elseif entity.PassInfo then
        warStatus = ModuleRefer.GateModule:GetWarStatus(entity.ID, ModuleRefer.AllianceModule:GetAllianceId())
        return warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder and entity.PassInfo.InBattle
    end
end

---@param entity wds.Village|wds.DefenceTower|wds.EnergyTower|wds.CommonMapBuilding
---@return wds.ArmyMemberInfo|nil
function PvPTileAssetHUDTroopHead:GetNPCTroop(entity)
    if entity.TypeHash ~= wds.Village.TypeHash and entity.TypeHash ~= wds.Pass.TypeHash then
        return nil
    end
    local army = entity.Army
    if army.DummyTroopIDs then
        for _, armyMemberInfo in pairs(army.DummyTroopIDs) do
            return armyMemberInfo
        end
    end
end

---@param troop wds.ArmyMemberInfo
function PvPTileAssetHUDTroopHead:GetTroopHeroSpriteName(troop)
    if troop and troop.HeroTId:Count() > 0 then
        local heroConfigID = troop.HeroTId[1]
        local heroConfig = ConfigRefer.Heroes:Find(heroConfigID)
        return ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
    end
    return string.Empty
end

return PvPTileAssetHUDTroopHead
