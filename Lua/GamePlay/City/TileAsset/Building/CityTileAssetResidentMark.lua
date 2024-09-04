local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetResidentMark:CityTileAsset
---@field new fun():CityTileAssetResidentMark
local CityTileAssetResidentMark = class("CityTileAssetResidentMark", CityTileAsset)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")

function CityTileAssetResidentMark:ctor()
    CityTileAsset:ctor(self)
    self.isUI = true
end

function CityTileAssetResidentMark:OnTileViewInit()
    self.state = false
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._cityCamera = city:GetCamera()
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, Delegate.GetOrCreate(self, self.OnStateChange))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_HOUSE_NEED_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
end

function CityTileAssetResidentMark:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_HOUSE_NEED_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, Delegate.GetOrCreate(self, self.OnStateChange))
end

function CityTileAssetResidentMark:OnStateChange(value)
    self.state = value
    if self.state then
        self:Show()
    else
        self:Hide()
    end
end

function CityTileAssetResidentMark:GetPrefabName()
    if self.state then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_risident_quantity)
    else
        return string.Empty
    end
end

function CityTileAssetResidentMark:Refresh()
    if self.behaviour then
        self.behaviour:UpdateUI()
    end
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetResidentMark:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then
        return
    end

    ---@type CityResidentMark
    local behaviour = go:AddMissingLuaBehaviour("CityResidentMark", "CityResidentMarkSchema").Instance
    local cellTile = self.tileView.tile
    behaviour:FeedData(cellTile)
    self.behaviour = behaviour
end

function CityTileAssetResidentMark:OnAssetUnload(go, fade)
    
end

---@param city City
---@param houseNeedRefresh table<number, boolean>
function CityTileAssetResidentMark:OnCitizenDataChanged(city, houseNeedRefresh)
    if not self.state then
        return
    end
    if self:GetCity().uid ~= city.uid then
        return
    end
    if houseNeedRefresh[self.tileView.tile:GetCell().tileId] then
        self:Refresh()
    end
end

return CityTileAssetResidentMark