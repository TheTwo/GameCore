local RequestServiceBase = require('RequestServiceBase')
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local UpdateAOIParameter = require("UpdateAOIParameter")

---@class NewbieRequestService : RequestServiceBase
local NewbieRequestService = class("NewbieRequestService", RequestServiceBase)

local MapEntityTypes =
{
    "FakeCastle",
    "Expedition",
    "SlgInteractor",
}

function NewbieRequestService:ctor(offsetX, offsetY)
    self.offsetX = offsetX
    self.offsetY = offsetY
end

---@param mapSystem CS.Grid.MapSystem
function NewbieRequestService:Initialize(mapSystem)
    ---@type CS.Grid.MapSystem
    self.mapSystem = mapSystem

    for _, type in ipairs(MapEntityTypes) do
        self:RegisterCallbacks(type)
    end
end

---@param mapRequest CS.Grid.MapRequest
function NewbieRequestService:Send(mapRequest)
    local param = UpdateAOIParameter.new()
    param.args.Lod = 5
    param:Send()
end

function NewbieRequestService:Release()
    for _, type in ipairs(MapEntityTypes) do
        self:UnregisterCallbacks(type)
    end
end

---@param entity wds.CastleBrief
function NewbieRequestService:OnMapBuildingAdd(entity, viewTypeHash, refCount)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(entity)
    local affectedX, affectedY, affectedSizeX, affectedSizeY = ModuleRefer.KingdomConstructionModule:GetBuildingAffectedRange(entity)

    local mapBasics = entity.MapBasics
    local x = mapBasics.BuildingPos.X + self.offsetX
    local y = mapBasics.BuildingPos.Y + self.offsetY
    affectedX = affectedX + self.offsetX
    affectedY = affectedY + self.offsetY

    self.mapSystem:AddOrUpdateUnit(x, y, layout.SizeX, layout.SizeY,
            affectedX, affectedY, affectedSizeX, affectedSizeY,
            entity.TypeHash, entity.ID)
end

---@param entity wds.CastleBrief
function NewbieRequestService:OnMapBuildingDelete(entity, viewTypeHash, refCount)
    if entity.viewTypeCount and entity.viewTypeCount > 0 then return end
    self.mapSystem:RemoveUnit(entity.TypeHash, entity.ID)
end

---@param entity wds.CastleBrief
---@param value any
function NewbieRequestService:OnMapBuildingChange(entity, value)
    if value then
        self.mapSystem:UpdateUnit(entity.TypeHash, entity.ID)
    end
end

function NewbieRequestService:RegisterCallbacks(typeName)
    local typeHash = DBEntityType[typeName]
    local dataPath = DBEntityPath[typeName]["MsgPath"]
    g_Game.DatabaseManager:AddViewNew(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingAdd))
    g_Game.DatabaseManager:AddViewDestroy(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingDelete))
    g_Game.DatabaseManager:AddChanged(dataPath, Delegate.GetOrCreate(self, self.OnMapBuildingChange))
end

function NewbieRequestService:UnregisterCallbacks(typeName)
    local typeHash = DBEntityType[typeName]
    local dataPath = DBEntityPath[typeName]["MsgPath"]
    g_Game.DatabaseManager:RemoveViewNew(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingAdd))
    g_Game.DatabaseManager:RemoveViewDestroy(typeHash, Delegate.GetOrCreate(self, self.OnMapBuildingDelete))
    g_Game.DatabaseManager:RemoveChanged(dataPath, Delegate.GetOrCreate(self, self.OnMapBuildingChange))
end

return NewbieRequestService