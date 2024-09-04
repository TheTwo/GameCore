local KingdomSurface = require("KingdomSurface")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local PoolUsage = require("PoolUsage")
local ObjectType = require("ObjectType")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local ManualResourceConst = require("ManualResourceConst")
local KingdomAttachmentFactory = require("KingdomAttachmentFactory")


local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local MapUtils = CS.Grid.MapUtils


---@class KingdomSurfaceEntityAttachment :KingdomSurface
---@field attachmentMap table<number, KingdomAttachmentBase[]>
---@field factory KingdomAttachmentFactory
local KingdomSurfaceEntityAttachment = class("KingdomSurfaceEntityAttachment", KingdomSurface)

function KingdomSurfaceEntityAttachment:ctor()
    self.attachmentMap = {}
    self.createHelper = PooledGameObjectCreateHelper.Create(PoolUsage.Map)
    self.factory = KingdomAttachmentFactory.new()
end

function KingdomSurfaceEntityAttachment:Initialize(mapSystem, hudManager)
    KingdomSurface.Initialize(self, mapSystem, hudManager)
    
    self.factory:Initialize(self.createHelper, self.mapSystem)

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnEntityChanged))
end

function KingdomSurfaceEntityAttachment:Dispose()
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnEntityChanged))
    
    self.createHelper:DeleteAll()
    self.factory:Dispose()
end

function KingdomSurfaceEntityAttachment:OnEnterHighLod()
end

function KingdomSurfaceEntityAttachment:OnLeaveHighLod()
    self:Leave()
end

function KingdomSurfaceEntityAttachment:OnLeaveMap()
    self:Leave()
end

function KingdomSurfaceEntityAttachment:Leave()
    for id, attachments in pairs(self.attachmentMap) do
        for _, attachment in ipairs(attachments) do
            attachment:Hide()
        end
    end
    table.clear(self.attachmentMap)

    self.createHelper:DeleteAll()
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceEntityAttachment:OnEntityAdded(typeId, entity)
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    local lod = KingdomMapUtils.GetLOD()
    for _, brief in pairs(entity.Infos.Briefs) do
        local attachments = self.factory:Create(brief.ObjectType)
        for _, attachment in ipairs(attachments) do
            attachment:Show(brief, lod)
        end
        self.attachmentMap[brief.ObjectId] = attachments
    end
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceEntityAttachment:OnEntityRemoved(typeId, entity)
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    for _, brief in pairs(entity.Infos.Briefs) do
        local attachments = self.attachmentMap[brief.ObjectId]
        if attachments then
            for _, attachment in ipairs(attachments) do
                attachment:Hide()
            end
        end
        self.attachmentMap[brief.ObjectId] = nil
    end
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceEntityAttachment:OnEntityChanged(entity)
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    self:OnEntityRemoved(entity.TypeHash, entity)
    self:OnEntityAdded(entity.TypeHash, entity)
end



return KingdomSurfaceEntityAttachment