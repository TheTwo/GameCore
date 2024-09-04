local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")

local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetCommonMapBuilding:PvPTileAssetUnit
---@field new fun():PvPTileAssetCommonMapBuilding
---@field super PvPTileAssetUnit
local PvPTileAssetCommonMapBuilding = class('PvPTileAssetCommonMapBuilding', PvPTileAssetUnit)


function PvPTileAssetCommonMapBuilding:ctor()
    PvPTileAssetCommonMapBuilding.super.ctor(self)
    ---@type MapUITrigger[]
    self._touchTrigger = {}
end

---@return string
function PvPTileAssetCommonMapBuilding:GetLodPrefabName(lod)
    ---@type wds.CommonMapBuilding
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFlexible(entity.MapBasics.ConfID, lod) then
        if entity.Construction.Status == wds.BuildingConstructionStatus.BuildingConstructionStatusProcessing then
            return ArtResourceUtils.GetItem(buildingConfig:InConstructionModel())
        else
            return ArtResourceUtils.GetItem(buildingConfig:Model())
        end
    end
    return string.Empty
end

function PvPTileAssetCommonMapBuilding:OnConstructionSetup()
    OnConstructionSetup.super.OnConstructionSetup(self)
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end
	---@type CS.DragonReborn.LuaBehaviour[]
	local behaviours = {}
    asset:GetLuaBehavioursInChildren("MapUITrigger", behaviours, true)
    if #behaviours <= 0 then
        return
    end
	for i, v in ipairs(behaviours) do
		---@type MapUITrigger
		local trigger = v.Instance
		if trigger then
			trigger:SetTrigger(Delegate.GetOrCreate(self, self.OnClickSelfTrigger))
			table.insert(self._touchTrigger, trigger)
		end
	end
end

function PvPTileAssetCommonMapBuilding:OnConstructionShutdown()
	for i, v in ipairs(self._touchTrigger) do
		v:SetTrigger(nil)
	end
	table.clear(self._touchTrigger)
end

function PvPTileAssetCommonMapBuilding:OnClickSelfTrigger()
    local x, y = self:GetServerPosition()
    if x <= 0 or y <= 0 then
        return
    end
    local scene = KingdomMapUtils.GetKingdomScene()
    local coord = CS.DragonReborn.Vector2Short(math.floor(x + 0.5), math.floor(y + 0.5))
    scene.mediator:ChooseCoordTile(coord)
end

return PvPTileAssetCommonMapBuilding
