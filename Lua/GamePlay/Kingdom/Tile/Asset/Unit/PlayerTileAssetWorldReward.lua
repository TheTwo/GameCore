local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local MapUtils = CS.Grid.MapUtils
local Vector3 = CS.UnityEngine.Vector3
local Vector2Short = CS.DragonReborn.Vector2Short
local PlayerTileAssetWorldReward = class("PlayerTileAssetWorldReward", PvPTileAssetUnit)
local ArtResourceUtils = require('ArtResourceUtils')
local ConfigRefer = require('ConfigRefer')
local Utils = require("Utils")

local LAYER_KINGDOM = 13
local INT_DATA = 111

function PlayerTileAssetWorldReward:CanShow()
    local data = self:GetData()
    return data ~= nil
end

function PlayerTileAssetWorldReward:GetScale()
    return Vector3.one
end

function PlayerTileAssetWorldReward:GetWorldPos(tilePosX, tilePosY)
    local x = math.floor(tilePosX)
    local y = math.floor(tilePosY)
    return MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem()), Vector2Short(x, y)
end

function PlayerTileAssetWorldReward:GetPosition()
    local data = self:GetData()
    return self:GetWorldPos(data.Pos.X, data.Pos.Y)
end

---@return string
function PlayerTileAssetWorldReward:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        local data = self:GetData()
        local config = ConfigRefer.MistEvent:Find(data.ConfigId)
        return ArtResourceUtils.GetItem(config:Model())
    end
    return string.Empty
end

function PlayerTileAssetWorldReward:OnShow()
    PvPTileAssetUnit.OnShow(self)
end

function PlayerTileAssetWorldReward:OnConstructionSetup()
    local data = self:GetData()
    PvPTileAssetUnit.OnConstructionSetup(self)
    self.createHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("WorldRewardInteractor")
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return 
    end
    
    asset.transform.name = "PlayerTileAssetWorldReward"
    asset.transform.localScale = Vector3.one
    asset:SetLayerRecursive(LAYER_KINGDOM)

    local cdata = asset:GetComponent(typeof(CS.CustomData))
    if cdata == nil then
        cdata = asset:AddComponent(typeof(CS.CustomData))
    end

    cdata.objectData = data
    cdata.intData = INT_DATA

    self:OnConstructionUpdate()
end

function PlayerTileAssetWorldReward:OnConstructionShutdown()
    if self.createHelper then
        self.createHelper:DeleteAll()
        self.createHelper = nil
    end
end

function PlayerTileAssetWorldReward:OnHide()
    PvPTileAssetUnit.OnHide(self)
end

function PlayerTileAssetWorldReward:OnConstructionUpdate()
    PvPTileAssetUnit.OnConstructionUpdate(self)
end

return PlayerTileAssetWorldReward
