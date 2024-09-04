local KingdomPlacerBehavior = require("KingdomPlacerBehavior")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityType = require("DBEntityType")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local Utils = require("Utils")

local MapBuildingHighlight = CS.Kingdom.MapBuildingHighlight

---@class KingdomPlacerBehaviorEnergyTower : KingdomPlacerBehavior
---@field context  KingdomPlacerContextBuilding
---@field rangeEffect CS.UnityEngine.GameObject
local KingdomPlacerBehaviorEnergyTower = class("KingdomPlacerBehaviorEnergyTower", KingdomPlacerBehavior)

function KingdomPlacerBehaviorEnergyTower:OnShow()
    --local unitViews = KingdomMapUtils.GetMapSystem():GetUnitViewsInRange()
    --self:RefreshHighlight(unitViews, true)
end

function KingdomPlacerBehaviorEnergyTower:OnHide()
    --local unitViews = KingdomMapUtils.GetMapSystem():GetUnitViewsInRange()
    --self:RefreshHighlight(unitViews, false)
end

function KingdomPlacerBehaviorEnergyTower:OnDispose()
end

function KingdomPlacerBehaviorEnergyTower:OnPlacing()
    if self.context.buildingConfig:Type() == FlexibleMapBuildingType.EnergyTower then
        local message = require("BuildEnergyTowerParameter").new()
        message.args.TowerConfID = self.context.buildingConfig:Id()
        message.args.Pos = wds.Vector3F.New(self.context.coord.X, self.context.coord.Y, 0)
        message:SendWithFullScreenLock()
    end
end


function KingdomPlacerBehaviorEnergyTower:RefreshHighlight(unitViews, state)
    for i = 0, unitViews.Count - 1 do
        ---@type MapTileView
        local view = unitViews[i]:GetInstance()
        local typeId = view:GetTypeId()

        if typeId == DBEntityType.DefenceTower or
            typeId == DBEntityType.MobileFortress or
            typeId == DBEntityType.MobileFortress then
            ---@type wds.DefenceTower|wds.MobileFortress
            local entity = g_Game.DatabaseManager:GetEntity(view:GetUniqueId(), typeId)
            if entity.BasicInfo.InEnergyRange then
                self:HighlightBuilding(view, state)
            end
        end
    end
end

---@param tileView MapTileView
function KingdomPlacerBehaviorEnergyTower:HighlightBuilding(tileView, state)
    ---@type MapTileAssetSolo
    local mainAsset = tileView:GetMainAsset()
    ---@type CS.UnityEngine.GameObject
    local asset = mainAsset:GetAsset()
    if Utils.IsNull(asset) then
        return
    end
    local highlight = asset:GetComponent(typeof(MapBuildingHighlight))
    if Utils.IsNull(highlight) then
        highlight = asset:AddComponent(typeof(MapBuildingHighlight))
    end

    if state then
        highlight:StartHighlight()
    else
        highlight:StopHighlight()
    end
end

return KingdomPlacerBehaviorEnergyTower