local BaseUIComponent = require("BaseUIComponent")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")

---@class MapBuildingTroopListUICell :BaseUIComponent
---@field super BaseUIComponent
---@field param MapBuildingParameter
---@field owner wds.Owner
---@field mapBasics wds.MapEntityBasicInfo
---@field army wds.Army
---@field strengthArmy wds.Strengthen
---@field construction wds.BuildingConstruction
---@field isStrengthen boolean
local MapBuildingTroopListUICell = class("MapBuildingTroopListUICell", BaseUIComponent)

function MapBuildingTroopListUICell:ctor()
    MapBuildingTroopListUICell.super.ctor(self)
    ---@type MapBuildingParameter
    self.param = nil
end

function MapBuildingTroopListUICell:OnCreate(param)
    self.p_table_troop = self:TableViewPro("p_table_troop")
    
    ModuleRefer.MapBuildingTroopModule:RegisterAllBuildingChange(Delegate.GetOrCreate(self, self.OnArmyDataChanged))
end

function MapBuildingTroopListUICell:OnHide(param)
    ModuleRefer.MapBuildingTroopModule:UnregisterAllBuildingChange(Delegate.GetOrCreate(self, self.OnArmyDataChanged))
end

---@param param MapBuildingParameter
function MapBuildingTroopListUICell:OnFeedData(param)
    self.param = param

    self:RefreshList()
end

---@param entity wds.TransferTower
function MapBuildingTroopListUICell:OnArmyDataChanged(entity, _)
    self:RefreshList()
end

function MapBuildingTroopListUICell:RefreshList()
    if not self.param then
        return
    end
    
    self.p_table_troop:Clear()
    if self.param.Army and self.param.Army.DummyTroopInitFinish then
        for _, armyMemberInfo in pairs(self.param.Army.DummyTroopIDs) do
            self:CreatePlayerTroop(armyMemberInfo, false)
        end
    else
        if self.param.EntityTypeHash and (self.param.EntityTypeHash == DBEntityType.CommonMapBuilding 
                or self.param.EntityTypeHash == DBEntityType.DefenceTower
                or self.param.EntityTypeHash == DBEntityType.EnergyTower
                or self.param.EntityTypeHash == DBEntityType.TransferTower
        ) then
            -- no InitTroops
        else
            local buildingConfig = ConfigRefer.FixedMapBuilding:Find(self.param.MapBasics.ConfID)
            if buildingConfig then
                for i = 1, buildingConfig:InitTroopsLength() do
                    local troopConfigId = buildingConfig:InitTroops(i)
                    self:CreateNPCTroop(troopConfigId)
                end
            end
        end
    end
    if self.param.Army then
        if self.param.Army.PlayerTroopIDs then
            for _, armyMemberInfo in pairs(self.param.Army.PlayerTroopIDs) do
                self:CreatePlayerTroop(armyMemberInfo, false)
            end
        end
        if self.param.Army.PlayerOnRoadTroopIDs then
            for _, armyMemberInfo in pairs(self.param.Army.PlayerOnRoadTroopIDs) do
                self:CreatePlayerTroop(armyMemberInfo, true)
            end
        end
    end
    if self.param.StrengthenArmy then
        if self.param.StrengthenArmy.PlayerTroopIDs then
            for _, armyMemberInfo in pairs(self.param.StrengthenArmy.PlayerTroopIDs) do
                self:CreatePlayerTroop(armyMemberInfo, false)
            end
        end
        if self.param.StrengthenArmy.PlayerOnRoadTroopIDs then
            for _, armyMemberInfo in pairs(self.param.StrengthenArmy.PlayerOnRoadTroopIDs) do
                self:CreatePlayerTroop(armyMemberInfo, true)
            end
        end
    end

    if ModuleRefer.AllianceModule:GetAllianceId() == self.param.Owner.AllianceID then
        if not ModuleRefer.MapBuildingTroopModule:IsBuildingTroopFull(self.param.Army, self.param.MapBasics, self.param.StrengthenArmy) then
            if self.param.IsStrengthen then
                local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(self.param.MapBasics.BuildingPos)
                local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
                self.p_table_troop:AppendDataEx(tile, 0, 0, 1)
            else
                local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(self.param.MapBasics.BuildingPos)
                local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
                ---@type MapBuildingTroopEmptyUICellParameter
                local data = {}
                data.tile = tile
                data.isReinforce = true
                self.p_table_troop:AppendDataEx(data, 0, 0, 1)
            end
        end
    end
    self.p_table_troop:RefreshAllShownItem()
end

function MapBuildingTroopListUICell:CreateNPCTroop(troopConfigId)
    ---@type MapBuildingTroopUICellParameter
    local troopParam = {}
    troopParam.EntityID = self.param.EntityID
    troopParam.TroopConfigId = troopConfigId
    troopParam.IsMarching = false
    troopParam.IsStrengthen = self.param.IsStrengthen
    self.p_table_troop:AppendDataEx(troopParam, 0, 0, 0)
end

---@param armyMemberInfo wds.ArmyMemberInfo
function MapBuildingTroopListUICell:CreatePlayerTroop(armyMemberInfo, isMarching)
    if armyMemberInfo then
        ---@type MapBuildingTroopUICellParameter
        local troopParam = {}
        troopParam.EntityID = self.param.EntityID
        troopParam.ArmyMemberInfo = armyMemberInfo
        troopParam.TroopConfigId = 0
        troopParam.IsMarching = isMarching
        troopParam.IsStrengthen = self.param.IsStrengthen
        self.p_table_troop:AppendDataEx(troopParam, 0, 0, 0)
    end
end

---@param armyMemberInfoOrPlayerId wds.ArmyMemberInfo
function MapBuildingTroopListUICell:CreatePlayerTroopByTroopId(playerId, isMarching, troopId)
    ---@type MapBuildingTroopUICellParameter
    local troopParam = {}
    troopParam.EntityID = self.param.EntityID
    troopParam.TroopConfigId = 0
    troopParam.IsMarching = isMarching
    troopParam.IsStrengthen = self.param.IsStrengthen
    troopParam.troopId = troopId
    troopParam.playerId = playerId
    self.p_table_troop:AppendDataEx(troopParam, 0, 0, 0)
end

return MapBuildingTroopListUICell