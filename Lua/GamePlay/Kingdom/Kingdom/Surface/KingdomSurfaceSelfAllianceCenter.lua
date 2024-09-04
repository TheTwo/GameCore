local KingdomEntityDataWrapperFactory = require("KingdomEntityDataWrapperFactory")
local KingdomRefreshData = require("KingdomRefreshData")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local ObjectType = require("ObjectType")
local EventConst = require("EventConst")

local KingdomSurface = require("KingdomSurface")

---@class KingdomSurfaceSelfAllianceCenter:KingdomSurface
---@field super KingdomSurface
---@field allianceCenter wds.MapEntityBrief
local KingdomSurfaceSelfAllianceCenter = class("KingdomSurfaceSelfAllianceCenter", KingdomSurface)

function KingdomSurfaceSelfAllianceCenter:ctor()
    self.factory = KingdomEntityDataWrapperFactory.new()
    self.refreshData = KingdomRefreshData.new()
    ---@type wds.MapEntityBrief
    self.allianceCenter = nil
end

function KingdomSurfaceSelfAllianceCenter:Initialize(mapSystem, hudManager)
    KingdomSurfaceSelfAllianceCenter.super.Initialize(self, mapSystem, hudManager)
    self.refreshData:Initialize(hudManager, self.staticMapData)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBuildingChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function KingdomSurfaceSelfAllianceCenter:Dispose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBuildingChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    self.refreshData:Dispose()
    self.allianceCenter = nil
end

function KingdomSurfaceSelfAllianceCenter:ClearUnits()
    self:Leave()
end

function KingdomSurfaceSelfAllianceCenter:OnEnterHighLod()
    self.refreshData:InitMaterials()
    self:OnAllianceBuildingChanged(ModuleRefer.AllianceModule:GetMyAllianceData())
end

function KingdomSurfaceSelfAllianceCenter:OnLeaveHighLod()
    self:Leave()
end

function KingdomSurfaceSelfAllianceCenter:OnLeaveMap()
    self:Leave()
end

function KingdomSurfaceSelfAllianceCenter:Leave()
    self.refreshData:ClearRemoves()
    self.refreshData:ClearRefreshes()
    self.refreshData:ClearMaterial()
    self.allianceCenter = nil
end

function KingdomSurfaceSelfAllianceCenter:OnLodChanged(oldLod, newLod)
    if not KingdomMapUtils.InMapKingdomLod(oldLod) or not KingdomMapUtils.InMapKingdomLod(newLod) then
        return
    end
    if not self.allianceCenter then return end
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(self.allianceCenter.ObjectType)
    if wrapper then
        wrapper:OnLodChanged(self.refreshData, nil, oldLod, newLod, self.allianceCenter)
        self.refreshData:UpdateData()
        self.refreshData:ClearRefreshes()
        self.refreshData:UpdateMaterials()
        self.refreshData:ClearMaterial()
    end
end

function KingdomSurfaceSelfAllianceCenter:OnJoinAlliance()
    if self.allianceCenter then return end
    self:OnAllianceBuildingChanged(ModuleRefer.AllianceModule:GetMyAllianceData())
end

function KingdomSurfaceSelfAllianceCenter:OnLeaveAlliance()
    if not self.allianceCenter then return end
    self:DoRemoveAllianceCenter()
end

---@param entity wds.Alliance
function KingdomSurfaceSelfAllianceCenter:OnAllianceBuildingChanged(entity, _)
    if not entity then return end
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end
    if ModuleRefer.AllianceModule:GetMyAllianceData() ~= entity then
        return
    end
    local currentAllianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillage()
    self:DoUpdateAllianceCenter(currentAllianceCenter)
end

---@param currentAllianceCenter wds.MapBuildingBrief
function KingdomSurfaceSelfAllianceCenter:DoAddAllianceCenter(currentAllianceCenter)
    self.refreshData:ClearRefreshes()
    local objectId = currentAllianceCenter.EntityID
    local vid = currentAllianceCenter.VID
    local configId = currentAllianceCenter.ConfigId
    local allainceId = ModuleRefer.AllianceModule:GetAllianceId()
    local pos = currentAllianceCenter.Pos
    local color = ModuleRefer.AllianceModule:GetMyAllianceTerritoryColor()
    local mask = wds.MapEntityExtStateMask.MapEntityExtStateMask_None
    self.allianceCenter = wds.MapEntityBrief.New(objectId, ObjectType.SlgVillage, configId, 0, allainceId, pos, color, false, true, mask, vid)
    self.allianceCenter.__special = true
    local lod = KingdomMapUtils.GetLOD()
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(ObjectType.SlgVillage)
    local prefabName = KingdomEntityDataWrapperFactory.GetPrefabName(ObjectType.SlgVillage)
    if not string.IsNullOrEmpty(prefabName) then
        local coord = wrapper:GetCenterCoordinate(self.allianceCenter)
        if ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y) then
            local position = wrapper:GetCenterPosition(self.allianceCenter)
            local id = self.allianceCenter.ObjectId
            if self.refreshData:CreateHUD(id, prefabName, position, lod) then
                wrapper:FeedData(self.refreshData, self.allianceCenter)
                wrapper:OnShow(self.refreshData, nil, lod, self.allianceCenter)
            end
        end
    end
    self.refreshData:UpdateData()
    self.refreshData:ClearRefreshes()
    self.refreshData:UpdateMaterials()
    self.refreshData:ClearMaterial()
end

function KingdomSurfaceSelfAllianceCenter:DoRemoveAllianceCenter()
    self.refreshData:ClearRemoves()
    self.refreshData:RemoveHUD(self.allianceCenter.ObjectId)
    local lod = KingdomMapUtils.GetLOD()
    self.refreshData:Remove(lod)
    self.allianceCenter = nil
end

---@param currentAllianceCenter wds.MapBuildingBrief
function KingdomSurfaceSelfAllianceCenter:DoUpdateAllianceCenter(currentAllianceCenter)
    if not self.allianceCenter and not currentAllianceCenter then return end
    if not self.allianceCenter then
        self:DoAddAllianceCenter(currentAllianceCenter)
    elseif not currentAllianceCenter then
        self:DoRemoveAllianceCenter()
    else
        if self.allianceCenter.ObjectId ~= currentAllianceCenter.EntityID then
            self:DoRemoveAllianceCenter()
            self:DoAddAllianceCenter(currentAllianceCenter)
        end
    end
end

function KingdomSurfaceSelfAllianceCenter:OnIconClick(id)
    if self.allianceCenter and self.allianceCenter.ObjectId == id then
        local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(ObjectType.SlgVillage)
        wrapper:OnIconClick(self.allianceCenter)
        return true
    end
end

return KingdomSurfaceSelfAllianceCenter