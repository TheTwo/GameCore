local CityTileAssetFurniture = require("CityTileAssetFurniture")
local Utils = require("Utils")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local CityAssetCitizenSpawnPlace= require("CityAssetCitizenSpawnPlace")

---@class CityTileAssetCitizenSpawnPlace:CityTileAssetFurniture
---@field new fun():CityTileAssetCitizenSpawnPlace
---@field super CityTileAssetFurniture
local CityTileAssetCitizenSpawnPlace = class('CityTileAssetCitizenSpawnPlace', CityTileAssetFurniture)

function CityTileAssetCitizenSpawnPlace:ctor()
    CityTileAssetFurniture.ctor(self)
    self._furnitureId = nil
    ---@type number
    self._castleBriefId = nil
    ---@type CityAssetCitizenSpawnPlace
    self._spawnPlace = nil
    self._isInMyCity = false
    ---@type number
    self._waitCitizenId = nil
end

function CityTileAssetCitizenSpawnPlace:OnAssetLoaded(go, userdata)
    CityTileAssetFurniture.OnAssetLoaded(self, go, userdata)
    self._waitCitizenId = nil
    self._isInMyCity = false
    self._furnitureId = nil
    self._castleBriefId = nil
    self._spawnPlace = nil
    if Utils.IsNull(go) then
        return
    end
    local cell = self.tileView.tile:GetCell()
    self._furnitureId = cell.singleId
    local city = self:GetCity()
    self._isInMyCity = city:IsMyCity()
    self._castleBriefId = city.uid
    
    ---@type CS.DragonReborn.LuaBehaviour
    local luaBehaviours = go:GetComponentsInChildren(typeof(CS.DragonReborn.LuaBehaviour))
    for i = 0, luaBehaviours.Length - 1 do
        local luaBehaviour = luaBehaviours[i]
        if Utils.IsNotNull(luaBehaviour) then
            local place = luaBehaviour.Instance
            if place:is(CityAssetCitizenSpawnPlace) then
                self._spawnPlace = place
                self._spawnPlace:Init()
                break
            end
        end
    end
    
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnWaitingCitizensDataChanged))
    self:OnWaitingCitizensDataChanged(g_Game.DatabaseManager:GetEntity(self._castleBriefId, DBEntityType.CastleBrief))
end

function CityTileAssetCitizenSpawnPlace:OnAssetUnload()
    CityTileAssetFurniture.OnAssetUnload(self)
    self._waitCitizenId = nil
    self._isInMyCity = false
    self._furnitureId = nil
    self._castleBriefId = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnWaitingCitizensDataChanged))
    if self._spawnPlace then
        self._spawnPlace:Release()
    end
end

---@param entity wds.CastleBrief
function CityTileAssetCitizenSpawnPlace:OnWaitingCitizensDataChanged(entity, _)
    if not self._furnitureId or not self._spawnPlace or not self._castleBriefId or self._castleBriefId ~= entity.ID then
        return
    end
    local furniture = entity.Castle.CastleFurniture[self._furnitureId]
    self._waitCitizenId = nil
    if furniture and furniture.WaitingCitizens and not table.isNilOrZeroNums(furniture.WaitingCitizens) then
        self._waitCitizenId = furniture.WaitingCitizens[1]
    end
    if self._spawnPlace then
        self._spawnPlace:SpawnCitizen(self._waitCitizenId)
    end
end

return CityTileAssetCitizenSpawnPlace