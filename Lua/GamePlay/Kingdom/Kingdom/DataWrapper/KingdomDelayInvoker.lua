local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")

---@class KingdomDelayInvoker
---@field refreshData KingdomRefreshData
---@field callbackList table<fun(KingdomEntityDataWrapper, KingdomRefreshData, number)>
---@field idList table<number>
---@field indexList table<number>
---@field stateList table<boolean>
---@field timer Timer
local KingdomDelayInvoker = class("KingdomDelayInvoker")

---@param refreshData KingdomRefreshData
function KingdomDelayInvoker:ctor(refreshData)
    self.refreshData = refreshData
    self.callbackList = {}
    self.idList = {}
    self.indexList = {}
    self.stateList = {}
    self.immediately = false
end

---@return boolean
function KingdomDelayInvoker:IsEmpty()
    return table.nums(self.callbackList) == 0
end

function KingdomDelayInvoker:AddCallback(callback, id, index, state)
    if callback and id and index then
        table.insert(self.callbackList, callback)
        table.insert(self.idList, id)
        table.insert(self.indexList, index)
        table.insert(self.stateList, state == nil and true or state)
    end
end

---@param delay number
function KingdomDelayInvoker:Start(delay)
    self.timer = TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.InvokeAll), delay)
end

function KingdomDelayInvoker:InvokeAll()
    local count = table.nums(self.callbackList)
    for i = 1, count do
        local callback = self.callbackList[i]
        local id = self.idList[i]
        local index = self.indexList[i]
        local state = self.stateList[i]
        callback(self.refreshData, id, index, state)
    end
    
    self:Clear()
end

function KingdomDelayInvoker:Clear()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
    table.clear(self.callbackList)
    table.clear(self.idList)
    table.clear(self.indexList)
    table.clear(self.stateList)
end

return KingdomDelayInvoker