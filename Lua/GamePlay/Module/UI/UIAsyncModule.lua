local BaseModule = require("BaseModule")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local UIMediatorNames = require("UIMediatorNames")
local TimerUtility = require("TimerUtility")
local HomeSeInExploreParameter = require("HomeSeInExploreParameter")
---@class UIAsyncModule : BaseModule
local UIAsyncModule = class("UIAsyncModule", BaseModule)

function UIAsyncModule:ctor()
    self.globalBlock = false
end

function UIAsyncModule:OnRegister()
    g_Game.EventManager:AddListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnUIMediatorClose))
    g_Game.EventManager:AddListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnEnterCity))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimelineOrStoryEnd))
    g_Game.EventManager:AddListener(EventConst.SE_EXIT, Delegate.GetOrCreate(self, self.OnSEEnd))
    g_Game.EventManager:AddListener(EventConst.ON_GUIDE_END, Delegate.GetOrCreate(self, self.OnGuideEnd))
    g_Game.EventManager:AddListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateMachineChanged))
    g_Game.EventManager:AddListener(EventConst.UI_ASYNC_QUEUE_END, Delegate.GetOrCreate(self, self.OnQueueEnd))

    g_Game.ServiceManager:AddResponseCallback(HomeSeInExploreParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnHomeSeInExploreEnd))
end

function UIAsyncModule:OnRemove()
    g_Game.EventManager:RemoveListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnUIMediatorClose))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnEnterCity))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimelineOrStoryEnd))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXIT, Delegate.GetOrCreate(self, self.OnSEEnd))
    g_Game.EventManager:RemoveListener(EventConst.ON_GUIDE_END, Delegate.GetOrCreate(self, self.OnGuideEnd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateMachineChanged))
    g_Game.EventManager:RemoveListener(EventConst.UI_ASYNC_QUEUE_END, Delegate.GetOrCreate(self, self.OnQueueEnd))

    g_Game.ServiceManager:RemoveResponseCallback(HomeSeInExploreParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnHomeSeInExploreEnd))
end

function UIAsyncModule:OnUIMediatorClose(meditaor)
    TimerUtility.DelayExecuteInFrame(function()
        if not self:ExecuteAsyncQueue(meditaor) then
            self:ExecuteDelayedQueue()
        end
    end, 10) -- 正常页面跳转过程中，阻塞队列中的页面可能会插队弹出，这里先延迟10帧执行
end

function UIAsyncModule:OnEnterCity(flag)
    if not flag then
        return
    end
    TimerUtility.DelayExecute(function()
        self:ExecuteEnterCityQueue()
    end, 1)
end

function UIAsyncModule:OnEnterMap()
    TimerUtility.DelayExecute(function()
        self:ExecuteEnterMapQueue()
    end, 1)
end

function UIAsyncModule:OnTimelineOrStoryEnd()
    TimerUtility.DelayExecuteInFrame(function()
        self:ExecuteDelayedQueue()
    end, 10)
end

function UIAsyncModule:OnSEEnd()
    TimerUtility.DelayExecuteInFrame(function()
        self:ExecuteDelayedQueue()
    end, 10)
end

function UIAsyncModule:OnGuideEnd(isSuccess)
    TimerUtility.DelayExecuteInFrame(function()
        self:ExecuteDelayedQueue()
    end, 10)
end

---@param city City
function UIAsyncModule:OnCityStateMachineChanged(city, oldState, newState)
    if not city:IsMyCity() then return end
    TimerUtility.DelayExecuteInFrame(function()
        self:ExecuteDelayedQueue()
    end, 10)
end

function UIAsyncModule:OnHomeSeInExploreEnd()
    TimerUtility.DelayExecuteInFrame(function()
        self:ExecuteDelayedQueue()
    end, 10)
end

function UIAsyncModule:OnQueueEnd()
    g_Game.UIAsyncManager:ExecuteWaitingQueue()
end

function UIAsyncModule:ExecuteAsyncQueue(meditaor)
    local directlyOpenBlocker = g_Game.UIAsyncManager.directlyOpenBlocker
    if directlyOpenBlocker and directlyOpenBlocker.mediatorName == meditaor then
        g_Game.UIAsyncManager.directlyOpenBlocker = nil
    end
    ---@type UIAsyncDataProvider.PopupTimings, LinkedList
    for timing, _ in pairs(g_Game.UIAsyncManager.queues) do
        if g_Game.UIAsyncManager:GetQueueFrontMediatorName(timing) == meditaor and meditaor ~= nil then
            g_Game.UIAsyncManager.curExecutingQueue = timing
            g_Game.UIAsyncManager:TryOpen(timing)
            return true
        end
    end
    return false
end

function UIAsyncModule:ExecuteDelayedQueue()
    g_Game.UIAsyncManager:ExecuteQueue(UIAsyncDataProvider.PopupTimings.AnyTime)
end

function UIAsyncModule:ExecuteEnterCityQueue()
    g_Game.UIAsyncManager:ExecuteQueue(UIAsyncDataProvider.PopupTimings.EnterCity)
end

function UIAsyncModule:ExecuteEnterMapQueue()
    g_Game.UIAsyncManager:ExecuteQueue(UIAsyncDataProvider.PopupTimings.EnterMap)
end

function UIAsyncModule:AddGlobalBlock()
    self.globalBlock = true
end

function UIAsyncModule:RemoveGlobalBlock()
    self.globalBlock = false
    TimerUtility.DelayExecuteInFrame(function()
        self:ExecuteDelayedQueue()
    end, 10)
end

return UIAsyncModule