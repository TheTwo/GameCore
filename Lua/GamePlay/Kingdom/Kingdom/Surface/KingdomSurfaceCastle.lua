local KingdomSurface = require("KingdomSurface")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ObjectType = require("ObjectType")
local Delegate = require("Delegate")
local KingdomEntityDataWrapperFactory = require("KingdomEntityDataWrapperFactory")
local KingdomRefreshData = require("KingdomRefreshData")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")

---@class KingdomSurfaceCastle : KingdomSurface
local KingdomSurfaceCastle = class("KingdomSurfaceCastle", KingdomSurface)

function KingdomSurfaceCastle:ctor()
    self.factory = KingdomEntityDataWrapperFactory.new()
    self.refreshData = KingdomRefreshData.new()
end

function KingdomSurfaceCastle:Initialize(mapSystem, hudManager)
    KingdomSurface.Initialize(self, mapSystem, hudManager)
    self.refreshData:Initialize(hudManager, self.staticMapData)

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnEntityChanged))
end

function KingdomSurfaceCastle:Dispose()
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnEntityChanged))
    
    self.refreshData:Dispose()
end

function KingdomSurfaceCastle:ClearUnits()
    self:Leave()
end

function KingdomSurfaceCastle:OnEnterHighLod()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function KingdomSurfaceCastle:OnLeaveHighLod()
    self:Leave()
end

function KingdomSurfaceCastle:OnLeaveMap()
    self:Leave()
end

function KingdomSurfaceCastle:Leave()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    
    self.refreshData:ClearRemoves()
    self.refreshData:ClearRefreshes()
    self.refreshData:UpdateData()
    self.refreshData:ClearMaterial()
end

function KingdomSurfaceCastle:Tick()
    --if self.refreshData:IsDataRefreshed() then
    --    self.refreshData:UpdateData()
    --    self.refreshData:ClearRefreshes()
    --end
    --
    --if self.refreshData:IsMaterialChanged() then
    --    self.refreshData:UpdateMaterials()
    --    self.refreshData:ClearMaterial()
    --end
    --
    --if self.refreshData:IsDataRemoved() then
    --    self.refreshData:Remove()
    --    self.refreshData:ClearRemoves()
    --end
    --
    --self.refreshData:Refresh()
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceCastle:OnEntityAdded(typeId, entity)
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    self.refreshData:ClearRefreshes()

    local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
    local playerID = ModuleRefer.PlayerModule.playerId
    local lod = KingdomMapUtils.GetLOD()
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(ObjectType.SlgCastle)
    local prefabName = KingdomEntityDataWrapperFactory.GetPrefabName(ObjectType.SlgCastle)
    for _, brief in pairs(entity.Infos.Briefs) do
        if not KingdomSurfaceCastle.FilterBrief(brief, allianceID, playerID) then
            goto continue
        end
        local coord = wrapper:GetCenterCoordinate(brief)
        if ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y) then
            local position = wrapper:GetCenterPosition(brief)
            if self.refreshData:CreateHUD(brief.ObjectId, prefabName, position, lod) then
                wrapper:FeedData(self.refreshData, brief)
                wrapper:OnShow(self.refreshData, nil, lod, brief)
            end
        end
        ::continue::
    end

    self.refreshData:UpdateData()
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceCastle:OnEntityRemoved(typeId, entity)
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
    local playerID = ModuleRefer.PlayerModule.playerId
    self.refreshData:ClearRemoves()
    for _, brief in pairs(entity.Infos.Briefs) do
        if not KingdomSurfaceCastle.FilterBrief(brief, allianceID, playerID) then
            goto continue
        end
        self.refreshData:RemoveHUD(brief.ObjectId)
        ::continue::
    end
    local lod = KingdomMapUtils.GetLOD()
    self.refreshData:Remove(lod)
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceCastle:OnEntityChanged(entity)
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    self:OnEntityRemoved(entity.TypeHash, entity)
    self:OnEntityAdded(entity.TypeHash, entity)
end

---@param brief wds.MapEntityBrief
function KingdomSurfaceCastle.FilterBrief(brief, allianceID, playerID)
    return brief.ObjectType == ObjectType.SlgCastle and (brief.AllianceId == 0 or brief.AllianceId ~= allianceID) and brief.PlayerId ~= playerID
end

return KingdomSurfaceCastle