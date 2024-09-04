local KingdomSurface = require("KingdomSurface")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ObjectType = require("ObjectType")
local Delegate = require("Delegate")
local KingdomEntityDataWrapperFactory = require("KingdomEntityDataWrapperFactory")
local KingdomRefreshData = require("KingdomRefreshData")
local DBEntityPath = require("DBEntityPath")
local Utils = require("Utils")

---@class KingdomSurfaceSelfAllianceCastle : KingdomSurface
---@field hudManager CS.Kingdom.MapHUDManager
---@field refreshData KingdomRefreshData
---@field castles table<number, wds.AllianceMember>
local KingdomSurfaceSelfAllianceCastle = class("KingdomSurfaceSelfAllianceCastle", KingdomSurface)

function KingdomSurfaceSelfAllianceCastle:ctor()
    self.factory = KingdomEntityDataWrapperFactory.new()
    self.refreshData = KingdomRefreshData.new()
    self.castles = {}
end

function KingdomSurfaceSelfAllianceCastle:Initialize(mapSystem, hudManager)
    KingdomSurface.Initialize(self, mapSystem, hudManager)
    self.refreshData:Initialize(hudManager, self.staticMapData)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.RefreshMemberCastles))
end

function KingdomSurfaceSelfAllianceCastle:Dispose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.RefreshMemberCastles))
    self.refreshData:Dispose()
end

function KingdomSurfaceSelfAllianceCastle:ClearUnits()
    self:Leave()
end

function KingdomSurfaceSelfAllianceCastle:OnEnterHighLod()
    self.refreshData:InitMaterials()
    self:RefreshMemberCastles()
    self:RefreshMyCastle()
end

function KingdomSurfaceSelfAllianceCastle:OnLeaveHighLod()
    self:Leave()
end

function KingdomSurfaceSelfAllianceCastle:OnLeaveMap()
    self:Leave()
end

function KingdomSurfaceSelfAllianceCastle:Leave()
    table.clear(self.castles)
    self.refreshData:ClearRemoves()
    self.refreshData:ClearRefreshes()
    self.refreshData:UpdateData()
    self.refreshData:ClearMaterial()
end

function KingdomSurfaceSelfAllianceCastle:RefreshMemberCastles()
    if not KingdomMapUtils.InMapKingdomLod() then
        return
    end

    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end

    self:RemoveCastles()
    self.castles = {}
    local members = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    for _, member in pairs(members) do
        self.castles[member.PlayerID] = member
    end
    self:DoRefreshCastles()

end

function KingdomSurfaceSelfAllianceCastle:RefreshMyCastle()
    if ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local member = {}
    member.Name = castle.Owner.PlayerName.String
    member.Rank = ModuleRefer.PlayerModule:StrongholdLevel()
    member.BigWorldPosition = wds.Vector3F(castle.MapBasics.BuildingPos.X, castle.MapBasics.BuildingPos.Y, 0)
    member.PlayerID = player.ID

    self:RemoveCastles()
    self.castles = {}
    self.castles[member.PlayerID] = member
    self:DoRefreshCastles()
end

function KingdomSurfaceSelfAllianceCastle:DoRefreshCastles()
    self.refreshData:ClearRefreshes()

    local lod = KingdomMapUtils.GetLOD()
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(ObjectType.SlgCastle)
    local prefabName = KingdomEntityDataWrapperFactory.GetPrefabName(ObjectType.SlgCastle)
    ---@param member wds.AllianceMember
    for id, member in pairs(self.castles) do
        local coord = wrapper:GetCenterCoordinate(member)
        if ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y) then
            local position = wrapper:GetCenterPosition(member)
            if self.refreshData:CreateHUD(member.PlayerID, prefabName, position, lod) then
                wrapper:FeedData(self.refreshData, member)
                wrapper:OnShow(self.refreshData, nil, lod, member)
            end
        end
    end

    self.refreshData:UpdateData()
    self.refreshData:ClearRefreshes()
    self.refreshData:UpdateMaterials()
    self.refreshData:ClearMaterial()
end

function KingdomSurfaceSelfAllianceCastle:RemoveCastles()
    self.refreshData:ClearRemoves()
    for id, _ in pairs(self.castles) do
        self.refreshData:RemoveHUD(id)
    end
    local lod = KingdomMapUtils.GetLOD()
    self.refreshData:Remove(lod)
end

function KingdomSurfaceSelfAllianceCastle:OnIconClick(id)
    local castle = self.castles[id]
    if castle then
        local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(ObjectType.SlgCastle)
        wrapper:OnIconClick(castle)
        return true
    end
end

return KingdomSurfaceSelfAllianceCastle