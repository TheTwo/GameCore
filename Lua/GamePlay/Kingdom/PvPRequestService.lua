local DBEntityType = require('DBEntityType')
local DBEntityName = require("DBEntityName")
local DBEntityPath = require('DBEntityPath')
local Delegate = require('Delegate')
local RequestServiceBase = require('RequestServiceBase')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local ProtocolId = require('ProtocolId')
local KingdomConstant = require('KingdomConstant')
local LodMapping = require("LodMapping")
local KingdomMapUtils = require("KingdomMapUtils")

---@class PvPRequestService:RequestServiceBase
local PvPRequestService = class("PvPRequestService", RequestServiceBase)

local MapEntityTypes =
{
    DBEntityName.CastleBrief,
    DBEntityName.ResourceField,
    DBEntityName.Village,
    DBEntityName.EnergyTower,
    DBEntityName.TransferTower,
    DBEntityName.DefenceTower,
    DBEntityName.Expedition,
    DBEntityName.SlgCreepTumor,
    DBEntityName.SlgCreepTumorRemoverBuilding,
    DBEntityName.Lighthouse,
    DBEntityName.SlgInteractor,
    DBEntityName.CommonMapBuilding,
    DBEntityName.Pass,
    DBEntityName.BehemothCage,
}

---@param mapSystem CS.Grid.MapSystem
function PvPRequestService:Initialize(mapSystem)
    ---@type CS.Grid.MapSystem
    self.mapSystem = mapSystem
    for _, type in ipairs(MapEntityTypes) do
        self:RegisterCallbacks(type)
    end
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushMoveCity, Delegate.GetOrCreate(self, self.OnMoveCity))
end

function PvPRequestService:Release()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushMoveCity, Delegate.GetOrCreate(self, self.OnMoveCity))
    for _, type in ipairs(MapEntityTypes) do
        self:UnregisterCallbacks(type)
    end
end

---@param entity wds.CastleBrief
function PvPRequestService:OnMapBuildingAdd(entity, viewTypeHash, refCount)
    if PvPRequestService.TempFilter(entity) then
        return
    end
    
    local mapBasics = entity.MapBasics
    local x = mapBasics.BuildingPos.X
    local y = mapBasics.BuildingPos.Y
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(entity)
    local affectedX, affectedY, affectedSizeX, affectedSizeY = ModuleRefer.KingdomConstructionModule:GetBuildingAffectedRange(entity)
    ModuleRefer.MapUnitModule:AddUnit(
            entity.TypeHash, entity.ID, 
            x, y, layout.SizeX, layout.SizeY,
            affectedX, affectedY, affectedSizeX, affectedSizeY, false
    )
end

---@param entity wds.CastleBrief
function PvPRequestService:OnMapBuildingDelete(entity, viewTypeHash, refCount)
    if PvPRequestService.TempFilter(entity) then
        return
    end
    
    if entity.viewTypeCount and entity.viewTypeCount > 0 then return end
    ModuleRefer.MapUnitModule:RemoveUnit(entity.TypeHash, entity.ID, false)
end

---@param entity wds.CastleBrief
---@param value any
function PvPRequestService:OnMapBuildingChange(entity, value)
    if value then
        if PvPRequestService.TempFilter(entity) then
            return
        end
        
        ModuleRefer.MapUnitModule:UpdateUnit(entity.TypeHash, entity.ID, false)
    end
end

function PvPRequestService:RegisterCallbacks(typeName)
    local typeHash = DBEntityType[typeName]
    if not typeHash then
        g_Logger.Error("DBEntityType:%s not exists", typeName)
    end
    local dataPath = DBEntityPath[typeName]["MsgPath"]
    g_Game.DatabaseManager:AddViewNew(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingAdd))
    g_Game.DatabaseManager:AddViewDestroy(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingDelete))
    g_Game.DatabaseManager:AddChanged(dataPath, Delegate.GetOrCreate(self, self.OnMapBuildingChange))
end

function PvPRequestService:UnregisterCallbacks(typeName)
    local typeHash = DBEntityType[typeName]
    local dataPath = DBEntityPath[typeName]["MsgPath"]
    g_Game.DatabaseManager:RemoveViewNew(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingAdd))
    g_Game.DatabaseManager:RemoveViewDestroy(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingDelete))
    g_Game.DatabaseManager:RemoveChanged(dataPath, Delegate.GetOrCreate(self, self.OnMapBuildingChange))
end

function PvPRequestService:GetLodMapping()
    return LodMapping.mapping
end

---@param mapRequest CS.Grid.MapRequest
function PvPRequestService:Send(mapRequest)
    RequestServiceBase.Send(self, mapRequest)
    g_Game.EventManager:TriggerEvent(EventConst.RADARP_REFRESH_FILTER)
end

---@param result boolean    
---@param data wrpc.PushMoveCityRequest
function PvPRequestService:OnMoveCity(result, data)
    local entity = g_Game.DatabaseManager:GetEntity(data.CastleBriefId, DBEntityType.CastleBrief)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(entity)
    local affectedX, affectedY, affectedSizeX, affectedSizeY = ModuleRefer.KingdomConstructionModule:GetBuildingAffectedRange(entity)
    ModuleRefer.MapUnitModule:MoveUnit(entity.TypeHash, entity.ID,
            data.DestX, data.DestY, layout.SizeX, layout.SizeY,
            affectedX, affectedY, affectedSizeX, affectedSizeY, false)
    
    g_Game.EventManager:TriggerEvent(EventConst.RELOCATE_CITY_DONE, entity.ID)
end

function PvPRequestService.InvalidateMapAOI()
    local request = require("UpdateAOIParameter").new()
    request.args.Lod = wds.enum.PlayerLod.PlayerLod7
    request:Send()
end

function PvPRequestService.TempFilter(entity)
    if (entity.TypeHash == DBEntityType.Village or entity.TypeHash == DBEntityType.Pass) and KingdomMapUtils.CheckHideByFixedConfig(entity.MapBasics.ConfID) then
        return true
    end
end

return PvPRequestService
