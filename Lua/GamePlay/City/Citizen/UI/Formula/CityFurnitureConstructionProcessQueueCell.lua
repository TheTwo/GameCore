local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local RectTransformUtility = CS.UnityEngine.RectTransformUtility
local ConfigTimeUtility = require("ConfigTimeUtility")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityFurnitureConstructionProcessQueueCellData
---@field queueIndex number
---@field status number @0-Free,1-InQueue,2-Working,3-Collect,4-Locked
---@field process CityProcessConfigCell
---@field work wds.CastleProcess
---@field endTimestamp number
---@field host CityFurnitureConstructionProcessUIMediator
---@field castle wds.Castle
---@field tempSelected CityProcessConfigCell|nil

---@class CityFurnitureConstructionProcessQueueCell:BaseTableViewProCell
---@field new fun():CityFurnitureConstructionProcessQueueCell
---@field super BaseTableViewProCell
---@field _data CityFurnitureConstructionProcessQueueCellData
local CityFurnitureConstructionProcessQueueCell = class('CityFurnitureConstructionProcessQueueCell', BaseTableViewProCell)

function CityFurnitureConstructionProcessQueueCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._tick = false
    self._eventsSetup = false
    self._infoToastUI = nil
    self._toastUseProcessConfigId = nil
end

function CityFurnitureConstructionProcessQueueCell:OnCreate(param)
    self._p_status = self:StatusRecordParent("")
    self._p_area_drag = self:BindComponent("p_area_drag", typeof(CS.Empty4Raycast))
    self._area_drag_rect = self:RectTransform("p_area_drag")
    self._p_btn_collect = self:Button("p_btn_collect", Delegate.GetOrCreate(self, self.OnClickBtnCollect))
    self._p_icon_item = self:Image("p_icon_item")
    self._p_progress_item = self:Slider("p_progress_item")
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    self._p_btn_queue = self:Button("p_btn_queue", Delegate.GetOrCreate(self, self.OnClickBtnQueue))
    self._p_btn_working_menu = self:Button("p_btn_working_menu", Delegate.GetOrCreate(self, self.OnClickBtnWorkingMenu))
    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancelWork))
    self._p_text_reduce = self:Text("p_text_reduce", "crafting_btn_cancel")
end

---@param data CityFurnitureConstructionProcessQueueCellData
function CityFurnitureConstructionProcessQueueCell:OnFeedData(data)
    self._data = data
    self:RestoreBeforeTempSelected()
    self:SetupEvents(true)
    if self._data.status ~= 1 then
        self._p_btn_reduce:SetVisible(false)
    end
    if self._data.status ~= 2 then
        if self._infoToastUI then
            ModuleRefer.ToastModule:CancelTextToast(self._infoToastUI)
            self._infoToastUI = nil
        end
        self._toastUseProcessConfigId = nil
        if self._data.status == 0 and self._data.tempSelected then
            self:DoTempSelected()
        end
        return
    elseif self._toastUseProcessConfigId ~= self._data.process:Id() then
        if self._infoToastUI then
            ModuleRefer.ToastModule:CancelTextToast(self._infoToastUI)
            self._infoToastUI = nil
        end
    end
    self:Tick(0)
end

function CityFurnitureConstructionProcessQueueCell:OnRecycle(data)
    self:SetupEvents(false)
    self._p_btn_reduce:SetVisible(false)
    if self._infoToastUI then
        ModuleRefer.ToastModule:CancelTextToast(self._infoToastUI)
        self._infoToastUI = nil
    end
    self._toastUseProcessConfigId = nil
    self._tick = false
end

function CityFurnitureConstructionProcessQueueCell:OnClose(param)
    self:SetupEvents(false)
end

function CityFurnitureConstructionProcessQueueCell:SetupEvents(add)
    if self._eventsSetup and not add then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    elseif not self._eventsSetup and add then
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    end
    self._eventsSetup = add
end

function CityFurnitureConstructionProcessQueueCell:OnClickBtnCollect()
    if self._data.status ~= 3 then
        return
    end
    local host = self._data.host
    host._citizenMgr:GetProcessOutput(self._p_btn_collect.transform, host._furniture:UniqueId(),nil, {self._data.queueIndex-1})
end

function CityFurnitureConstructionProcessQueueCell:OnClickBtnWorkingMenu()
    if self._data.status ~= 2 then
        return
    end
    local outPut = self._data.process:Output(1)
    local itemConfig = ConfigRefer.Item:Find(outPut:ItemId())
    self._toastUseProcessConfigId = self._data.process:Id()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform =  self._p_btn_working_menu.transform
    toastParameter.content = I18N.Get(string.format("<b>%s</b> x%s", I18N.Get(itemConfig:NameKey()), outPut:Count()))
    self._infoToastUI = ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

function CityFurnitureConstructionProcessQueueCell:OnClickBtnQueue()
    if self._data.status ~= 1 then
        return
    end
    self._p_btn_reduce:SetVisible(true)
    self._data.host:SetBlockAllowRect(self._p_btn_reduce:GetComponent(typeof(CS.UnityEngine.RectTransform)), function()
        self._p_btn_reduce:SetVisible(false)
    end)
end

function CityFurnitureConstructionProcessQueueCell:OnClickCancelWork()
    if self._data.status ~= 1 then
        return
    end
    self._p_btn_reduce:SetVisible(false)
    self._data.host:SetBlockAllowRect(nil, nil)
    local host = self._data.host
    host._citizenMgr:ModifyProcessPlan(self._p_btn_reduce.transform, host._furniture:UniqueId(), {self._data.queueIndex-1}, 0, 0, nil, function(msgId, errorCode, jsonTable)
        if errorCode == 46045 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_resource_full"))
            return true
        end
        return false
    end)
end

function CityFurnitureConstructionProcessQueueCell:Tick(dt)
    if not self._tick or not self._data then
        return
    end
    local processConfig = self._data.process
    local work = self._data.work
    local endTime = self._data.endTimestamp
    if not work or not endTime or not processConfig then
        return
    end
    if work.LeftNum <= 0 then
        self._p_progress_item.value = 1.0
        return
    end
    local oneLoopTime = ConfigTimeUtility.NsToSeconds(processConfig:Time())
    local lastUpdateTime = self._data.castle.LastWorkUpdateTime.ServerSecond
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local beginTime = lastUpdateTime - (oneLoopTime * work.FinishNum + work.CurProgress)
    local g = math.inverseLerp(beginTime, endTime, nowTime)
    self._p_progress_item.value = g
end

---@param process CityProcessConfigCell
function CityFurnitureConstructionProcessQueueCell:TempSelected(process)
    if self._data.status ~= 0 then
        return
    end
    self._data.tempSelected = process
    self:DoTempSelected()
end

function CityFurnitureConstructionProcessQueueCell:DoTempSelected()
    self._p_status:SetState(1)
    local process = self._data.tempSelected.process
    if process then
        local outputItemInfo = process:Output(1)
        local itemConfig = ConfigRefer.Item:Find(outputItemInfo:ItemId())
        g_Game.SpriteManager:LoadSprite(itemConfig:Icon(), self._p_icon_item)
    end
end

function CityFurnitureConstructionProcessQueueCell:RestoreBeforeTempSelected()
    local data = self._data
    self._p_status:SetState(data.status)
    self._tick = data.status == 2 and data.work and data.endTimestamp
    if data.process then
        local outputItemInfo = data.process:Output(1)
        local itemConfig = ConfigRefer.Item:Find(outputItemInfo:ItemId())
        g_Game.SpriteManager:LoadSprite(itemConfig:Icon(), self._p_icon_item)
    end
    if self._tick then
        ---@type CommonTimerData
        local timerData = {}
        timerData.endTime = data.endTimestamp
        timerData.needTimer = true
        self._child_time:FeedData(timerData)
    end
end

---@param screenPos CS.UnityEngine.Vector2
function CityFurnitureConstructionProcessQueueCell:IsInInCellRange(screenPos)
    return RectTransformUtility.RectangleContainsScreenPoint(self._area_drag_rect, screenPos, g_Game.UIManager:GetUICamera())
end

return CityFurnitureConstructionProcessQueueCell