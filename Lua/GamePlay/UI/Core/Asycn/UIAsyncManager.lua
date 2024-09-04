local BaseManager = require("BaseManager")
local LinkedList = require("LinkedList")
local LinkedListNode = require("LinkedListNode")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local ModuleRefer = require("ModuleRefer")
local UIAsyncCustomTimings = require("UIAsyncCustomTimings")
local QueuedTask = require("QueuedTask")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
---@class UIAsyncManager : BaseManager
---@field new fun():UIAsyncManager
local UIAsyncManager = class('UIAsyncManager', BaseManager)

---@class QUEUE_PUSH_TYPE_DEFINE
local QUEUE_PUSH_TYPE_DEFINE = {
    PUSH_BACK = 1,
    PUSH_FRONT = 2,
}

UIAsyncManager.QUEUE_PUSH_TYPE_DEFINE = QUEUE_PUSH_TYPE_DEFINE

UIAsyncManager.AsyncId = 0

function UIAsyncManager:ctor()
    ---@type table<number, UIAsyncDataProvider>
    self.AllAsyncMediators = {}
    ---@type UIAsyncDataProvider[]
    self.enterCityQueue = {}
    ---@type UIAsyncDataProvider[]
    self.enterMapQueue = {}
    ---@type UIAsyncDataProvider[]
    self.delayedQueue = {}
    ---@type table<UIAsyncDataProvider.PopupTimings, UIAsyncDataProvider[]>
    self.queues = {
        [UIAsyncDataProvider.PopupTimings.AnyTime] = self.delayedQueue,
        [UIAsyncDataProvider.PopupTimings.EnterCity] = self.enterCityQueue,
        [UIAsyncDataProvider.PopupTimings.EnterMap] = self.enterMapQueue,
    }
    self.queuesBuffer = {
        [UIAsyncDataProvider.PopupTimings.AnyTime] = {},
        [UIAsyncDataProvider.PopupTimings.EnterCity] = {},
        [UIAsyncDataProvider.PopupTimings.EnterMap] = {},
    }
    for _, v in pairs(UIAsyncCustomTimings) do
        self.queues[v] = {}
        self.queuesBuffer[v] = {}
    end
    ---@type UIAsyncDataProvider
    self.directlyOpenBlocker = nil
    self.blockTasks = {}
    self.curExecutingQueue = nil

    self.waitingQueues = {}

    ---@type table<number, string>
    self.curOpeningMediatorName = {}
end

function UIAsyncManager:Reset()
    for _, e in pairs(self.AllAsyncMediators) do
        e:Release()
    end
    self.AllAsyncMediators = {}
    for _, v in pairs(self.queues) do
        table.clear(v)
    end

    for _, v in pairs(self.blockTasks) do
        v:Release()
    end

    self.curExecutingQueue = nil
end

---@private
function UIAsyncManager:InsertByPriority(queue, provider)
    local index = 1
    for i = 1, #queue do
        if provider.priority < queue[1].priority then
            index = i + 1
        else
            break
        end
    end
    table.insert(queue, index, provider)
end

---@private
---@param timing number @UIAsyncDataProvider.PopupTimings
---@return UIAsyncDataProvider
function UIAsyncManager:GetQueueFront(timing)
    return self.queues[timing][1]
end

---@private
function UIAsyncManager:GetQueueFrontMediatorName(timing)
    return self.curOpeningMediatorName[timing] or string.Empty
end

---@private
---@param timing number @UIAsyncDataProvider.PopupTimings
function UIAsyncManager:TryOpen(timing)
    if self.blockTasks[timing] then return end
    local length = #self.queues[timing]
    for _ = 1, length do
        local provider = table.remove(self.queues[timing], 1)
        if not provider then break end
        if self.AllAsyncMediators[provider:GetAsyncId()].removed then
            self.AllAsyncMediators[provider:GetAsyncId()] = nil
            provider:Release()
            goto continue
        end
        local failedMask = provider:Check()
        if failedMask == 0 then
            self.curOpeningMediatorName[timing] = provider.mediatorName
            provider:Open()
            provider.customOnOpened(provider, timing)
            if not provider.shouldKeep then
                self:RemoveAsyncMediator(provider:GetAsyncId())
            elseif provider.lastTiming ~= timing and timing == UIAsyncDataProvider.PopupTimings.AnyTime then
                -- 处理shouldKeep时延迟到AnyTime的情况，弹出后移回原队列
                table.insert(self.queues[provider.lastTiming], provider)
                provider.lastTiming = nil
            elseif timing ~= UIAsyncDataProvider.PopupTimings.AnyTime then
                table.insert(self.queuesBuffer[timing], provider)
            end
            return
        else
            if provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.Cancel then
                self:OnCheckFailedCancel(provider:GetAsyncId())
            elseif provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable then
                self:OnCheckFailedDelayToAnyTimeAvailable(provider:GetAsyncId(), timing)
            elseif provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.Custom then
                provider.customOnCheckFailed(provider:GetAsyncId(), failedMask, timing)
            elseif provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.DelayToNextCurrentTiming then
                self:OnCheckFailedDelayToNextCurrentTiming(provider:GetAsyncId(), timing)
            elseif provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.Block then
                local task = QueuedTask.new()
                task:WaitTrue(function ()
                    return provider:Check() == 0
                end):DoAction(function ()
                    self.blockTasks[timing]:Release()
                    self.blockTasks[timing] = nil
                    table.insert(self.queues[timing], 1, provider)
                    self:TryOpen(timing)
                end):Start()
                self.blockTasks[timing] = task
                return
            end
        end
        ::continue::
    end
    self.curExecutingQueue = nil
    g_Game.EventManager:TriggerEvent(EventConst.UI_ASYNC_QUEUE_END)
    local temp = self.queuesBuffer[timing]
    self.queuesBuffer[timing] = self.queues[timing]
    self.queues[timing] = temp
end

--- 将ui加入异步队列
---@param provider UIAsyncDataProvider
---@param openWithoutPushIntoQueue boolean 是否自动尝试打开anytime队列, 默认true
---@return number | boolean @排队后返回一个异步id，如果满足条件直接打开返回true；
function UIAsyncManager:AddAsyncMediator(provider, openWithoutPushIntoQueue)
    if openWithoutPushIntoQueue == nil then
        openWithoutPushIntoQueue = true
    end
    if provider.popupTiming == UIAsyncDataProvider.PopupTimings.AnyTime and openWithoutPushIntoQueue then
        local failedMask = provider:Check()
        if failedMask ~= 0 then
            if provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.Cancel then
                return false
            elseif provider.checkFailedStrategy == UIAsyncDataProvider.StrategyOnCheckFailed.Custom then
                local asyncId = UIAsyncManager.AsyncId + 1
                UIAsyncManager.AsyncId = asyncId
                self.AllAsyncMediators[asyncId] = provider
                provider:SetAsyncId(asyncId)
                self:InsertByPriority(self.queues[provider.popupTiming], provider)
                return asyncId
            end
        elseif not self.directlyOpenBlocker then
            provider:Open()
            self.directlyOpenBlocker = provider
            return true
        end
    end

    local asyncId = UIAsyncManager.AsyncId + 1
    UIAsyncManager.AsyncId = asyncId
    self.AllAsyncMediators[asyncId] = provider
    provider:SetAsyncId(asyncId)
    self:InsertByPriority(self.queues[provider.popupTiming], provider)
    return asyncId
end

--- 将一组ui加入异步队列
---@param providers table<number, UIAsyncDataProvider>
---@param shouldOpenImmediately boolean 仅在打开时机全部设置为anytime时传入，表示是否尝试直接打开
function UIAsyncManager:AddAsyncMediatorsList(providers, shouldOpenImmediately)
    for _, provider in ipairs(providers) do
        self:AddAsyncMediator(provider, false)
    end
    if shouldOpenImmediately then
        ModuleRefer.UIAsyncModule:ExecuteDelayedQueue()
    end
end

--- 从队列中移除一个ui，懒删除
---@param asyncId number
function UIAsyncManager:RemoveAsyncMediator(asyncId)
    if not self.AllAsyncMediators[asyncId] then return end
    self.AllAsyncMediators[asyncId].removed = true
end

--- 设置一个ui的openParam
---@param asyncId number
---@param openParam any
function UIAsyncManager:SetOpenParamByAsyncId(asyncId, openParam)
    if not self.AllAsyncMediators[asyncId] then return end
    self.AllAsyncMediators[asyncId].openParam = openParam
end

--- 检查失败后取消
---@param asyncId number
function UIAsyncManager:OnCheckFailedCancel(asyncId)
    local provider = self.AllAsyncMediators[asyncId]
    provider:Release()
    self.AllAsyncMediators[asyncId] = nil
end

--- 检查失败后延迟到AnyTime
---@param asyncId number
---@param timing number @UIAsyncDataProvider.PopupTimings
function UIAsyncManager:OnCheckFailedDelayToAnyTimeAvailable(asyncId, timing)
    local asyncProvider = self.AllAsyncMediators[asyncId]
    self.AllAsyncMediators[asyncId].popupTiming = UIAsyncDataProvider.PopupTimings.AnyTime
    asyncProvider.lastTiming = timing
    if timing ~= UIAsyncDataProvider.PopupTimings.AnyTime then
        -- 不同队列间移动元素，直接移入
        table.insert(self.delayedQueue, asyncProvider)
    else
        -- 同队列内移动元素，移入buffer
        table.insert(self.queuesBuffer[UIAsyncDataProvider.PopupTimings.AnyTime], asyncProvider)
    end
end

function UIAsyncManager:OnCheckFailedDelayToNextCurrentTiming(asyncId, timing)
    local asyncProvider = self.AllAsyncMediators[asyncId]
    table.insert(self.queuesBuffer[timing], asyncProvider)
end

--- 启动一条队列
---@param timing number
function UIAsyncManager:ExecuteQueue(timing)
    if self.curExecutingQueue == timing then return end
    if self.curExecutingQueue then
        if not table.ContainsValue(self.waitingQueues, timing) then
            table.insert(self.waitingQueues, timing)
        end
        return
    end
    self:ExecuteQueueImpl(timing)
end

---@private
---@param timing number
function UIAsyncManager:ExecuteQueueImpl(timing)
    self.curExecutingQueue = timing
    self:TryOpen(timing)
end

--- 执行等待队列
function UIAsyncManager:ExecuteWaitingQueue()
    local timing = table.remove(self.waitingQueues, 1)
    if timing then
        g_Logger.LogChannel("UIAsyncManager", "ExecuteWaitingQueue: %d", timing)
        self:ExecuteQueue(timing)
    end
end

function UIAsyncManager:ClearDoNotShowInSEMediators()
    for _, v in pairs(self.AllAsyncMediators) do
        if v.shouldCheckSE and v.removed then
            g_Game.UIManager:CloseAllByName(v.mediatorName)
        end
    end
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonNotifyPopupMediator)
end

---@param mediatorName string
function UIAsyncManager:CancelMediatorsByName(mediatorName)
    for _, v in pairs(self.AllAsyncMediators) do
        if v.mediatorName == mediatorName then
            self:RemoveAsyncMediator(v.asyncId)
        end
    end
end

---@param timing number
---@return boolean
function UIAsyncManager:GetQueueSize(timing)
    return self.queues[timing].Count
end

---@param timing number
---@param name string
function UIAsyncManager:GetMediatorNumInQueueByName(timing, name)
    local count = 0
    for _, provider in pairs(self.AllAsyncMediators) do
        if provider.mediatorName == name and provider.popupTiming == timing and not provider.removed then
            count = count + 1
        end
    end
    return count
end

return UIAsyncManager
