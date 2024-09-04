local CityManagerBase = require("CityManagerBase")
---@class CityStaticTilesManager:CityManagerBase
---@field new fun():CityStaticTilesManager
local CityStaticTilesManager = class("CityStaticTilesManager", CityManagerBase)
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityStaticTilesManager:DoDataLoad()
    ---@type table<CityStaticObjectTile, CityStaticObjectTile>
    self.staticTiles = {}
    g_Game.EventManager:AddListener(EventConst.CITY_STATIC_TILE_ADD, Delegate.GetOrCreate(self, self.OnStaticTileAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_STATIC_TILE_REMOVE, Delegate.GetOrCreate(self, self.OnStaticTileRemove))
    return self:DataLoadFinish()
end

function CityStaticTilesManager:OnDataLoadFinish()
    
end

function CityStaticTilesManager:DoDataUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATIC_TILE_ADD, Delegate.GetOrCreate(self, self.OnStaticTileAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATIC_TILE_REMOVE, Delegate.GetOrCreate(self, self.OnStaticTileRemove))
    self.staticTiles = nil
end

function CityStaticTilesManager:OnDataUnloadStart()
    
end

function CityStaticTilesManager:OnStaticTileAdd(city, tile)
    if self.city ~= city then return end
    self.staticTiles[tile] = tile
end

function CityStaticTilesManager:OnStaticTileRemove(city, tile)
    if self.city ~= city then return end
    self.staticTiles[tile] = nil
end

function CityStaticTilesManager:NeedLoadData()
    return true
end

---@return table<CityStaticObjectTile, CityStaticObjectTile>|nil
function CityStaticTilesManager:GetTiles()
    return self.staticTiles
end

return CityStaticTilesManager