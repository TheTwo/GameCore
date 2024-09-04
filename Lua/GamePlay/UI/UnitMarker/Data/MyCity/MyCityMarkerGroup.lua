---@class MyCityMarkerGroup:IMarkerGroup
---@field new fun(camera:BasicCamera):MyCityMarkerGroup
local MyCityMarkerGroup = class("MyCityMarkerGroup")
local MyCityMarker = require("MyCityMarker")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")

---@param camera BasicCamera
---@param worldPosition CS.UnityEngine.Vector3
function MyCityMarkerGroup:ctor(camera)
    self.camera = camera
    self:CalculateWorldPosition()
    self.marker = MyCityMarker.new(self.worldPosition, self.camera)
end

function MyCityMarkerGroup:CalculateWorldPosition()
    local x, z = self:GetServerPosition()
    local staticMapData = KingdomMapUtils.GetStaticMapData()

    x = x * staticMapData.UnitsPerTileX
    z = z * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)

    self.worldPosition = CS.UnityEngine.Vector3(x, y, z)
end

function MyCityMarkerGroup:GetServerPosition()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    return castle.MapBasics.Position.X, castle.MapBasics.Position.Y
end

---@param uiMediator UnitMarkerHudUIMediator
function MyCityMarkerGroup:SetupUIMediator(uiMediator)
    self.mediator = uiMediator
end

function MyCityMarkerGroup:AddEventListener()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.MapBasics.Position.MsgPath, Delegate.GetOrCreate(self, self.OnCastlePositionChanged))
end

function MyCityMarkerGroup:RemoveEventListener()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.MapBasics.Position.MsgPath, Delegate.GetOrCreate(self, self.OnCastlePositionChanged))
end

function MyCityMarkerGroup:OnCastlePositionChanged(entity, changeTable)
    if entity == ModuleRefer.PlayerModule:GetCastle() then
        self:CalculateWorldPosition()
        self.marker.worldPosition = self.worldPosition
    end
end

function MyCityMarkerGroup:GetMarkers()
    return {self.marker}
end

return MyCityMarkerGroup