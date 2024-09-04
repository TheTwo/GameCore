---
--- Created by wupei. DateTime: 2022/3/1
---

local TableLinkedList = require("TableLinkedList")
local FSMState = require("FSMState")
local FSMEnum = require("FSMEnum")
local BuffClientGen = require("BuffClientGen")

---@class BuffClientState:FSMState
local BuffClientState = class("BuffClientState", FSMState)

---@param self BuffClientState
---@param dataList table
---@param buffTarget BuffClientTarget
function BuffClientState:ctor(dataList, buffTarget)
    FSMState:ctor()

    self._dataList = dataList
    ---@type BuffClientTarget
    self._buffTarget = buffTarget
    ---@type TableLinkedList
    self._handleList = nil
    self._time = 0
end

---@param self BuffClientState
function BuffClientState:OnStart()
    self._handleList = TableLinkedList.New()
    for _, data in ipairs(self._dataList) do
        ---@type BuffClientRunnerHandle
        local handle = {}
        handle.data = data
        self._handleList:Add(handle)
    end

    self._time = 0
end

---@class BuffClientRunnerHandle : TableLinedListNode
---@field data buffclient.data.Effect
---@field skillTarget BuffClientTarget
---@field behavior BuffBehavior

---@param self BuffClientState
function BuffClientState:OnUpdate()
    local time = self._time
    local list = self._handleList

    ---@type BuffClientRunnerHandle
    local handle = list.first
    while handle ~= nil do
        local behavior = handle.behavior
        local data = handle.data
        if behavior then
            if time < data.TimeBegin + data.Time then
                try_catch_traceback_with_vararg(behavior.DoOnUpdate, nil, behavior)
            else
                try_catch_traceback_with_vararg(behavior.DoOnEnd, nil, behavior)
                list:Remove(handle)
            end
        else
            if time >= data.TimeBegin then
                behavior = self:CreateBehavior(data.Type, data, self._buffTarget)
                if behavior then
                    handle.behavior = behavior
                    try_catch_traceback_with_vararg(behavior.DoOnStart, nil, behavior)
                    try_catch_traceback_with_vararg(behavior.DoOnUpdate, nil, behavior)
                else
                    list:Remove(handle)
                end
            end
        end

        local next = handle.next
        handle = next
    end

    self._time = self._time + g_Game.Time.deltaTime

    if list.count > 0 then
        return FSMEnum.State.Running
    end
    
    return FSMEnum.State.Finished
end

---@param self BuffClientState
function BuffClientState:OnEnd()
    local list = self._handleList

    ---@type BuffClientRunnerHandle
    local handle = list.first
    while handle ~= nil do
        local next = handle.next
        local behavior = handle.behavior
        if behavior then
            try_catch_traceback_with_vararg(behavior.DoOnEnd, nil, behavior)
        end
        list:Remove(handle)

        handle = next
    end
    self._handleList = nil
end

---@param self BuffClientState
---@param typeNum number
---@param data buffclient.data.Effect
---@param buffTarget BuffClientTarget
---@return void
function BuffClientState:CreateBehavior(typeNum, data, buffTarget)
    local typeName = BuffClientGen.Type2name[typeNum]
    local type = require(typeName)
    if not type then
        g_Logger.Error("behavior type implement not found. typeNum = %s", typeNum)
        return nil
    end
    return type.new(data, buffTarget)
end

return BuffClientState
