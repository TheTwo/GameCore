local LinkedList = require('LinkedList')
local QueuedTaskNodeAction = require('QueuedTaskNodeAction')
local QueuedTaskNodeWaitEvent = require('QueuedTaskNodeWaitEvent')
local QueuedTaskNodeWaitResponse = require('QueuedTaskNodeWaitResponse')
local QueuedTaskNodeWaitForSeconds = require('QueuedTaskNodeWaitForSeconds')
local QueuedTaskNodeWaitTrue = require('QueuedTaskNodeWaitTrue')
local Delegate = require('Delegate')
local QueuedTaskResult = require("QueuedTaskResult")

---@class QueuedTask
---@field new fun():QueuedTask
local QueuedTask = class("QueuedTask")

function QueuedTask:ctor()
	self._queue = LinkedList.new()
	self._currentTask = nil
	self._executing = false
end

function QueuedTask:WaitForSeconds(secs)
	local node = QueuedTaskNodeWaitForSeconds.new(secs)
	self._queue:PushBack(node)
	return self
end

function QueuedTask:DoAction(action, data)
	local node = QueuedTaskNodeAction.new(action, data)
	self._queue:PushBack(node)
	return self
end

---@param eventName string
---@param callback fun()
---@param onEventReceived fun(param:table):boolean
function QueuedTask:WaitEvent(eventName, callback,onEventReceived)
	local node = QueuedTaskNodeWaitEvent.new(eventName, callback,onEventReceived)
	self._queue:PushBack(node)
	return self
end

function QueuedTask:WaitTrue(callback, timeout)
	local node = QueuedTaskNodeWaitTrue.new(callback, timeout)
	self._queue:PushBack(node)
	return self
end

---@param msgId number
---@param timeout number @default is 5 second
---@param action fun()
function QueuedTask:WaitResponse(msgId, timeout, action)
	local node = QueuedTaskNodeWaitResponse.new(msgId, timeout,action)
	self._queue:PushBack(node)
	return self
end

function QueuedTask:Start()
	self:Stop()
	self._executing = true	
	g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.ExecuteTask))
end

function QueuedTask:Release()
	self:Stop()
	self._queue:Clear()
end

function QueuedTask:Stop()
	g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.ExecuteTask))
	self._executing = false
	if self._currentTask ~= nil then
		self._currentTask:End()
		self._currentTask = nil
	end
end

function QueuedTask:IsExecuting()
	return self._executing
end

function QueuedTask:ExecuteTask()
	if self._queue:IsEmpty() then
		self:Stop()
		return
	end

	if self._currentTask == nil then
		self._currentTask = self._queue:PopFront()
		self._currentTask:Begin()
	end

	local result = self._currentTask:Execute()
	if result == QueuedTaskResult.MoveNext then
		self._currentTask:End()
		self._currentTask = nil
	elseif result == QueuedTaskResult.Break then
		self:Stop()
	end
end

return QueuedTask