local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_Gamble:CityFurnitureOverviewUnitDataBase
---@field new fun(city):CityFurnitureOverviewUnitData_Gamble
local CityFurnitureOverviewUnitData_Gamble = class("CityFurnitureOverviewUnitData_Gamble", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local NotificationType = require("NotificationType")
local TimeFormatter = require("TimeFormatter")
local CityWorkHelper = require("CityWorkHelper")

function CityFurnitureOverviewUnitData_Gamble:ctor(city)
    CityFurnitureOverviewUnitDataBase.ctor(self, city)
end

function CityFurnitureOverviewUnitData_Gamble:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_card
end

---@param cell CityFurnitureOverviewUIUnitCard
function CityFurnitureOverviewUnitData_Gamble:FeedCell(cell)
    cell:StopTimer(self.timer)
    self.timer = nil
    self.freeTime = ModuleRefer.HeroCardModule:GetFreeTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.cell = cell
    local isFree = self.freeTime ~= 0 and curTime >= self.freeTime
    if isFree then
        cell._statusRecord:ApplyStatusRecord(0)
    else
        cell._statusRecord:ApplyStatusRecord(1)
        self.timer = cell:StartFrameTicker(Delegate.GetOrCreate(self, self.OnTick), 1, -1)
    end
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("FURNITURE_GACHA_RED", NotificationType.CITY_FURNITURE_GACHA, cell._child_reddot_default:GameObject(""))
    local rootNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetNotifyRootName(), NotificationType.CITY_FURNITURE_OVERVIEW)
    ModuleRefer.NotificationModule:AddToParent(node, rootNode)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, isFree and 1 or 0)
end

function CityFurnitureOverviewUnitData_Gamble:OnTick()
    local lastTime = self.freeTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    self.cell._p_progress_card.value = 1 - math.clamp(lastTime / TimeFormatter.OneDaySeconds, 0, 1)
    self.cell._p_text_time_card.text = TimeFormatter.SimpleFormatTime(lastTime)
    if lastTime <= 0 then
        self.cell._statusRecord:ApplyStatusRecord(0)
        self.cell:StopTimer(self.timer)
        self.timer = nil
    end
end

return CityFurnitureOverviewUnitData_Gamble