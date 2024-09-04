local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require('ConfigRefer')
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local OnChangeHelper = require("OnChangeHelper")
local EventConst = require("EventConst")
local CircleMaskType = require("CircleMaskType")
local MapBuildingSubType = require("MapBuildingSubType")


---@class CircleMask
---@field id number
---@field type number
---@field x number
---@field y number
---@field radius number

---@class MapFogCircles
---@field fogModule MapFogModule
local MapFogCircles = class("MapFogCircles")

function MapFogCircles:Initialize(fogModule)
    self.fogModule = fogModule

    --player
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.MapBasics.BuildingPos.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerPosChanged))
    
    --troop
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Troop, Delegate.GetOrCreate(self, self.OnTroopAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Troop, Delegate.GetOrCreate(self, self.OnTroopRemoved))

    --worldEvent
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnWorldEventAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnWorldEventRemoved))

    --alliance
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnVillageWarRefreshed))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBuildingRefreshed))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMembers.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMemberRefreshed))

    self:OnPlayerPosChanged(ModuleRefer.PlayerModule:GetCastle())
    self:RefreshTroopCircleUnlocks()
    self:OnAllianceChanged()

    self:AddVillageInitialCircleUnlock()
    self:RefreshWorldEventUnlocks()
end

function MapFogCircles:Dispose()
    --player
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.MapBasics.BuildingPos.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerPosChanged))

    --troop
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Troop, Delegate.GetOrCreate(self, self.OnTroopAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Troop, Delegate.GetOrCreate(self, self.OnTroopRemoved))

    --worldEvent
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnWorldEventAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnWorldEventRemoved))

    --alliance
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnVillageWarRefreshed))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBuildingRefreshed))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMembers.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMemberRefreshed))
end

function MapFogCircles:OnVillageWarRefreshed()
    if self.fogModule.allUnlocked then return end
    self.fogModule:ClearCircleMask(CircleMaskType.VillageOnWar)

    if ModuleRefer.AllianceModule:IsInAlliance() then
        local villageWars = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
        local radius = ConfigRefer.ConstMain:CityUnlockMistRadius()
        for _, war in pairs(villageWars) do
            local territoryConfig = ConfigRefer.Territory:Find(war.TerritoryId)
            local pos = territoryConfig:VillagePosition()
            local x, z = KingdomMapUtils.ParseCoordinate(pos:X(), pos:Y())
            self.fogModule:AddCircleMask(war.VillageId, CircleMaskType.VillageOnWar, x, z, radius)
        end
    end
end

function MapFogCircles:RefreshTroopCircleUnlocks()
    local radius = ConfigRefer.ConstBigWorld:TroopFogUnlockRadius()
    local myTroops, _ = ModuleRefer.SlgModule.troopManager:GetMyTroops()
    if myTroops then
        ---@param troopInfo TroopInfo
        for _, troopInfo in pairs(myTroops) do
            if troopInfo.troopId and troopInfo.troopId > 0 then
                if not self.fogModule:ExistCircleMask(CircleMaskType.Troop, troopInfo.troopId) then
                    ---@type wds.Troop
                    local troop = g_Game.DatabaseManager:GetEntity(troopInfo.troopId, DBEntityType.Troop)
                    if troop then
                        local x, z = KingdomMapUtils.ParseBuildingPos(troop.MapBasics.Position)
                        self.fogModule:AddCircleMask(troop.ID, CircleMaskType.Troop, x, z, radius)
                    end
                end
            end
        end
    end
end

---@param entity wds.Troop
function MapFogCircles:OnTroopAdded(id, entity)
    if self.fogModule.allUnlocked then return end
    if entity.Owner.PlayerID == ModuleRefer.PlayerModule.playerId then
        local x, z = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.Position)
        local radius = ConfigRefer.ConstBigWorld:TroopFogUnlockRadius()
        self.fogModule:AddCircleMask(entity.ID, CircleMaskType.Troop, x, z, radius)
    end
end

---@param entity wds.Troop
function MapFogCircles:OnTroopRemoved(id, entity)
    if self.fogModule.allUnlocked then return end
    if entity.Owner.PlayerID == ModuleRefer.PlayerModule.playerId then
        self.fogModule:RemoveCircleMask(entity.ID, CircleMaskType.Troop)
    end
end

---@param entity wds.Expedition
function MapFogCircles:OnWorldEventAdded(id, entity)
    if self.fogModule.allUnlocked then return end
    if entity.Owner.ExclusivePlayerId == 0 or entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule.playerId then
        local x, z = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.Position)
        local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
        local radius = eventCfg:RadiusA()
        self.fogModule:AddCircleMask(entity.ExpeditionInfo.Tid, CircleMaskType.WorldEventCircle, x, z, radius)
    end
end

---@param entity wds.Expedition
function MapFogCircles:OnWorldEventRemoved(id, entity)
    if self.fogModule.allUnlocked then return end
    if entity.Owner.ExclusivePlayerId == 0 or entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule.playerId then
        self.fogModule:RemoveCircleMask(entity.ExpeditionInfo.Tid, CircleMaskType.WorldEventCircle)
    end
end

function MapFogCircles:RefreshWorldEventUnlocks()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceData and allianceData.AllianceWrapper.AllianceExpedition and allianceData.AllianceWrapper.AllianceExpedition.Expeditions then
        for _, entity in pairs(allianceData.AllianceWrapper.AllianceExpedition.Expeditions) do
            if entity.CreatePlayerId == 0 or entity.CreatePlayerId ==  ModuleRefer.PlayerModule.playerId then
                local x, z = KingdomMapUtils.ParseBuildingPos(entity.BornPos)
                local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionConfigId)
                local radius = eventCfg:RadiusA()
                self.fogModule:AddCircleMask(entity.ExpeditionEntityId, CircleMaskType.WorldEventCircle, x, z, radius)
            end
        end
    end
end

function MapFogCircles:OnAllianceChanged()
    self:OnAllianceBuildingRefreshed()
    self:OnAllianceMemberRefreshed()
    self:OnVillageWarRefreshed()
end

function MapFogCircles:OnAllianceBuildingRefreshed()
    if self.fogModule.allUnlocked then return end
    
    self.fogModule:ClearCircleMask(CircleMaskType.AllianceBuilding)

    if ModuleRefer.AllianceModule:IsInAlliance() then
        local radius = ConfigRefer.ConstMain:CityUnlockMistRadius()
        local mapBuildingBriefs = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
        for id, brief in pairs(mapBuildingBriefs) do
            local x, z = KingdomMapUtils.ParseBuildingPos(brief.Pos)
            self.fogModule:AddCircleMask(brief.EntityID, CircleMaskType.AllianceBuilding, x, z, radius)
        end
    end
end

function MapFogCircles:OnAllianceMemberRefreshed()
    if self.fogModule.allUnlocked then return end

    self.fogModule:ClearCircleMask(CircleMaskType.AllianceMember)

    if ModuleRefer.AllianceModule:IsInAlliance() then
        local radius = ConfigRefer.ConstMain:CityUnlockMistRadius()
        local members = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
        for id, member in pairs(members) do
            local x, z = KingdomMapUtils.ParseBuildingPos(member.BigWorldPosition)
            self.fogModule:AddCircleMask(member.PlayerID, CircleMaskType.AllianceMember, x, z, radius)
        end
    end
end

---@param entity wds.Player
function MapFogCircles:OnPlayerPosChanged(entity)
    if self.fogModule.allUnlocked then return end
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if entity.ID == castle.ID then
        self.fogModule:RemoveCircleMask(entity.ID, CircleMaskType.Castle)
        local radius = ConfigRefer.ConstMain:CityUnlockMistRadius()
        local x, z = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
        self.fogModule:AddCircleMask(entity.ID, CircleMaskType.Castle, x, z, radius)
        KingdomMapUtils.GetMapSystem():RefreshUnits(0)
    end
end

function MapFogCircles:AddVillageInitialCircleUnlock()
    if self.fogModule.allUnlocked then return end
    local length = ConfigRefer.ConstBigWorld:InitialMistUnlockedVillagesLength()
    local defaultRadius = ConfigRefer.ConstMain:CityUnlockMistRadius()
    local cityRadius = ConfigRefer.ConstBigWorld:CityFogUnlockRadius()
    local buildingConfigIDSet = {}
    for i = 1, length do
        local buildingConfigID = ConfigRefer.ConstBigWorld:InitialMistUnlockedVillages(i)
        buildingConfigIDSet[buildingConfigID] = 1
    end

    local centerVillageConfigID = ConfigRefer.ConstBigWorld:KingdomCenterVillage()
    local allTerritories = ModuleRefer.TerritoryModule:GetAllTerritories()
    for _, territoryID in ipairs(allTerritories) do
        local territoryConfig = ConfigRefer.Territory:Find(territoryID)
        local buildingConfigID = territoryConfig:VillageId()
        if buildingConfigIDSet[buildingConfigID] then
            local buildingConfig = ConfigRefer.FixedMapBuilding:Find(buildingConfigID)
            local pos = territoryConfig:VillagePosition()
            local x = pos:X()
            local y = pos:Y()
            if buildingConfig:Id() ~= centerVillageConfigID then
                local districtID = ModuleRefer.TerritoryModule:GetDistrictAt(x, y)
                if not ModuleRefer.TerritoryModule:IsDistrictOpened(districtID) then
                    goto continue
                end
            end
            
            local radius = 30
            if buildingConfig:SubType() == MapBuildingSubType.City then
                radius = cityRadius
            else
                radius = defaultRadius
            end
            self.fogModule:AddCircleMask(territoryID, CircleMaskType.VillageInitialVisible, x, y, radius)
            
            ::continue::
        end
    end
end

return MapFogCircles