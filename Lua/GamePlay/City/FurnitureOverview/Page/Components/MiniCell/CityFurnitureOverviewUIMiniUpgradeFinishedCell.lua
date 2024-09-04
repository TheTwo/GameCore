local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")

---@class CityFurnitureOverviewUIMiniUpgradeFinishedCell:BaseTableViewProCell
local CityFurnitureOverviewUIMiniUpgradeFinishedCell = class('CityFurnitureOverviewUIMiniUpgradeFinishedCell', BaseTableViewProCell)

---@class CityFurnitureOverviewUIMiniUpgradeFinishedCellDatum
---@field city City
---@field furnitureId number

function CityFurnitureOverviewUIMiniUpgradeFinishedCell:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_icon_furniture_upgrade = self:Image("p_icon_furniture_upgrade")
    self._icon_finish = self:GameObject("icon_finish")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param data CityFurnitureOverviewUIMiniUpgradeFinishedCellDatum
function CityFurnitureOverviewUIMiniUpgradeFinishedCell:OnFeedData(data)
    self.data = data
    self.city = self.data.city
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.data.furnitureId)
    if castleFurniture == nil then
        return
    end

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), self._p_icon_furniture_upgrade)

    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetLevelUpNotifyName(self.data.furnitureId), NotificationType.CITY_FURNITURE_OVERVIEW_UNIT, self._child_reddot_default.go)
end

function CityFurnitureOverviewUIMiniUpgradeFinishedCell:OnClick()
    local furniture = self.city.furnitureManager:GetFurnitureById(self.data.furnitureId)
    if not furniture then return end

    local CityUtils = require("CityUtils")
    self:GetParentBaseUIMediator():CloseSelf()
    local city = self.city
    CityUtils.TryLookAtToCityCoord(city, furniture.x, furniture.y, nil, function()
        city:ForceSelectFurniture(furniture.singleId)
    end, true)
end

return CityFurnitureOverviewUIMiniUpgradeFinishedCell