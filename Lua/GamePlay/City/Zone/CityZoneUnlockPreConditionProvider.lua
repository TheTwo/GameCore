local UIRaisePowerPopupMediatorContentProvider = require("UIRaisePowerPopupMediatorContentProvider")

---@class CityZoneUnlockPreConditionProvider:UIRaisePowerPopupMediatorContentProvider
---@field super UIRaisePowerPopupMediatorContentProvider
---@field new fun():CityZoneUnlockPreConditionProvider
local CityZoneUnlockPreConditionProvider = class("CityZoneUnlockPreConditionProvider", UIRaisePowerPopupMediatorContentProvider)
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

---@param zoneManager CityZoneManager
---@param zone CityZone
function CityZoneUnlockPreConditionProvider:ctor(zoneManager, zone)
    self.zoneManager = zoneManager
    self.zone = zone
    ---@type UIRaisePowerPopupItemCellData
    self.cellData = {}
    local gotoCount = self.zone.config:ExplorePreFurnitureGotoLength()
    for index = 1, self.zone.config:ExplorePreFurnitureLength() do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(self.zone.config:ExplorePreFurniture(index))
        local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        local isFinished = self.zoneManager:IsPreFurnitureIdMeetUnlockRequirement(self.zone, self.zone.config:ExplorePreFurniture(index))
        table.insert(self.cellData, {
            text = I18N.GetWithParams("city_area_task26", I18N.Get(typCfg:Name()), tostring(lvCfg:Level())),--("#%s等级达到%d级"):format(I18N.Get(typCfg:Name()), lvCfg:Level()),
            showAsFinished = isFinished,
            gotoId = (not isFinished and index <= gotoCount) and self.zone.config:ExplorePreFurnitureGoto(index) or 0,
            gotoCallback = Delegate.GetOrCreate(self, self.GotoCallback),
        })
    end
    if self.zone.config:ExplorePreZone() > 0 then
        table.insert(self.cellData, {
            text = I18N.GetWithParams("city_area_task8", I18N.Get(self.zone.config:Name())),--("#%s区域的安全值已达到100%%"):format(I18N.Get(self.zone.config:Name())),
            showAsFinished = self.zoneManager:IsPreZoneMeetUnlockRequirement(self.zone),
        })
    end
    local pairGuideCount = self.zone.config:RecoverGuideLength()
    for i = 1, self.zone.config:ExplorePreTaskLength() do
        local taskCfg = ConfigRefer.Task:Find(self.zone.config:ExplorePreTask(i))
        local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskCfg:Id())
        local isFinished = state == wds.TaskState.TaskStateCanFinish or state == wds.TaskState.TaskStateFinished
        table.insert(self.cellData, {
            text = I18N.GetWithParams("city_area_task16", I18N.Get(taskCfg:Property():Name())),--("#事件[%s]已完成"):format(I18N.Get(taskCfg:Property():Name())),
            showAsFinished = isFinished,
            gotoId = (not isFinished) and (i <= pairGuideCount and self.zone.config:RecoverGuide(i)) or 0,
            gotoCallback = Delegate.GetOrCreate(self, self.GotoCallback),
        })
    end
end

function CityZoneUnlockPreConditionProvider:ShowBottomBtnRoot()
    return false
end

function CityZoneUnlockPreConditionProvider:GetTitle()
    return I18N.Get("city_area_task12")
end

function CityZoneUnlockPreConditionProvider:GetHintText()
    return I18N.Get("city_area_task13")
end

---@param param RaisePowerPopupParam
---@param mediator UIRaisePowerPopupMediator
function CityZoneUnlockPreConditionProvider:SetDefault(param, mediator)
    self.param = param
    self.mediator = mediator
end

---@return UIRaisePowerPopupItemCellData[]
function CityZoneUnlockPreConditionProvider:GenerateTableCellData()
    return self.cellData
end

function CityZoneUnlockPreConditionProvider:GotoCallback()
    if not self.mediator then return end
    self.mediator:CloseSelf()
end

return CityZoneUnlockPreConditionProvider
