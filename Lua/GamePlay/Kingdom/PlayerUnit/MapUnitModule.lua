local BaseModule = require("BaseModule")
local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")
local ProtocolId = require("ProtocolId")
local EventConst = require("EventConst")
local Utils = require("Utils")

local ListLong = CS.System.Collections.Generic.List(typeof(CS.System.Int64))

---@class MapUnitModule : BaseModule
---@field isReady boolean
---@field firstRequestSent boolean
---@field dataProviders table<number, PlayerUnitDataProvider>
---@field overrideCoords table
---@field conflictTypeList CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field conflictIDList CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field mapSystem CS.Grid.MapSystem
---@field relocatedPlayerUnits table<number, any>
local MapUnitModule = class("MapUnitModule", BaseModule)

function MapUnitModule:OnRegister()
    self.dataProviders =
    {
        [wds.PlayerMapCreep.TypeHash] = require("PlayerUnitDataProviderCreepTumor"),
        [wds.SeEnter.TypeHash] = require("PlayerUnitDataProviderSlgInteractor"),
        [wds.PlayerRtBox.TypeHash] = require("PlayerUnitDataProviderWorldRewardInteractor"),
        [wds.PetWildInfo.TypeHash] = require("PlayerUnitDataProviderPet"),
    }
    self.conflictTypeList = ListLong()
    self.conflictIDList = ListLong()
    self.relocatedPlayerUnits = {}
end

function MapUnitModule:OnRemove()
    self.dataProviders = nil
    self.conflictTypeList = nil
    self.conflictIDList = nil
    self.relocatedPlayerUnits = nil
end

function MapUnitModule:Setup()
    self.mapSystem = KingdomMapUtils.GetMapSystem()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.UpdateAOI, Delegate.GetOrCreate(self, self.OnUpdateAOI))
    self.isReady = true
    self.firstRequestSent = false
end

function MapUnitModule:ShutDown()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.UpdateAOI, Delegate.GetOrCreate(self, self.OnUpdateAOI))

    self.mapSystem = nil
    self.isReady = false
end

function MapUnitModule:GetPlayerUnitData(uniqueID, typeID)
    if not self.isReady then return end
    local provider = self.dataProviders[typeID]
    if provider then
        return provider.GetPlayerUnitData(uniqueID, typeID)
    end
end

function MapUnitModule:GetPlayerUnitBaseCoordinate(data)
    --todo: cache the resolved coords
    if not self.isReady then return end
    local range = self.mapSystem:RetrieveUnitRange(data.TypeHash, data.ID, true)
    return range.xMin, range.yMin
end

function MapUnitModule:GetPlayerUnitCenterCoordinate(data)
    if not self.isReady then return end
    local range = self.mapSystem:RetrieveUnitRange(data.TypeHash, data.ID, true)
    local center = range.Center
    return center.X, center.Y
end

function MapUnitModule:IntersectUnit(x, y, sizeX, sizeY, isPlayerUnit)
    return self.mapSystem:IntersectUnit(x, y, sizeX, sizeY, isPlayerUnit)
end

function MapUnitModule:AddUnit(typeID, uniqueID, x, y, sizeX, sizeY, affectX, affectY, affectSizeX, affectSizeY, isPlayerUnit)
    if not self.isReady then return end

    if not self:CheckUnitIntersection(typeID, uniqueID, x, y, sizeX, sizeY, isPlayerUnit) then
        return
    end

    return self.mapSystem:AddOrUpdateUnit(
            x, y, sizeX, sizeY,
            affectX, affectY, affectSizeX, affectSizeY,
            typeID, uniqueID, isPlayerUnit)
end

function MapUnitModule:RemoveUnit(typeID, uniqueID, isPlayerUnit)
    if not self.isReady then return end
    self.mapSystem:RemoveUnit(typeID, uniqueID, isPlayerUnit)
end

function MapUnitModule:UpdateUnit(typeID, uniqueID, isPlayerUnit)
    if not self.isReady then return end
    self.mapSystem:UpdateUnit(typeID, uniqueID, isPlayerUnit)
end

function MapUnitModule:MoveUnit(typeID, uniqueID, x, y, sizeX, sizeY, affectX, affectY, affectSizeX, affectSizeY, isPlayerUnit)
    if not self.isReady then return end

    if not self:CheckUnitIntersection(typeID, uniqueID, x, y, sizeX, sizeY, isPlayerUnit) then
        return
    end

    return self.mapSystem:MoveUnit(
            x, y, sizeX, sizeY,
            affectX, affectY, affectSizeX, affectSizeY,
            typeID, uniqueID, isPlayerUnit)
end

function MapUnitModule:OnUpdateAOI(result, data)
    if not self.firstRequestSent then
        g_Game.EventManager:TriggerEvent(EventConst.FIRST_UPDATE_AOI_RECEIVED)
        self.firstRequestSent = true
    end
    g_Game.EventManager:TriggerEvent(EventConst.UPDATE_AOI_RECEIVED)
end

function MapUnitModule:CheckUnitIntersection(typeID, uniqueID, x, y, sizeX, sizeY, isPlayerUnit)
    if isPlayerUnit then
        local needCheckIntersection = not self:IsUnitRelocated(typeID, uniqueID)
        if needCheckIntersection and self.mapSystem:IntersectUnit(x, y, sizeX, sizeY, isPlayerUnit) then
            return false
        end
    else
        self.conflictTypeList:Clear()
        self.conflictIDList:Clear()
        self.mapSystem:IntersectWithUnits(x, y, sizeX, sizeY, isPlayerUnit, self.conflictTypeList, self.conflictIDList)
        local count =  self.conflictIDList.Count
        for i = 0, count - 1 do
            local tid = self.conflictTypeList[i]
            local uid = self.conflictIDList[i]
            if not self:IsUnitRelocated(tid, uid) then
                self.mapSystem:RemoveUnit(tid, uid, true)
            end
        end
    end
    return true
end

function MapUnitModule:CheckPlayerSlgInteractor(typeID, uniqueID)
    local entity = g_Game.DatabaseManager:GetEntity(uniqueID, typeID)
    if not entity then
        return false
    end
    --个人交互物只有自己能看到
    local isMine = entity.Owner.ExclusivePlayerId == require("ModuleRefer").PlayerModule:GetPlayer().ID
    local isMulti = entity.Owner.ExclusivePlayerId == 0
    return isMulti or isMine
end

function MapUnitModule:IsUnitRelocated(typeID, uniqueID)
    local hashCode = Utils.GetLongHashCode(typeID, uniqueID)
    return self.relocatedPlayerUnits[hashCode]
end

function MapUnitModule:AddRelocatedPlayerUnit(typeID, uniqueID)
    local hashCode = Utils.GetLongHashCode(typeID, uniqueID)
    self.relocatedPlayerUnits[hashCode] = true
end

return MapUnitModule