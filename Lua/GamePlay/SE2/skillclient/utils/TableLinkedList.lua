---
--- Created by wupei. DateTime: 2022/1/27
---

---@class TableLinkedList
local TableLinkedList = {}
---@protected
TableLinkedList.__index = TableLinkedList

---@return TableLinkedList
function TableLinkedList.New(...)
    local obj = setmetatable({}, TableLinkedList)
    obj:ctor(...)
    return obj
end

---@class TableLinedListNode
---@field pre TableLinedListNode
---@field next TableLinedListNode

---@protected
function TableLinkedList:ctor(...)
    ---@type TableLinedListNode
    self.first = nil
    ---@type TableLinedListNode
    self.last = nil
    self.count = 0
end

---@param item TableLinedListNode
function TableLinkedList:Add(item)
    if item.pre ~= nil or item.next ~= nil then
        g_Logger.Error("LinedList:Add(item) error. item.pre ~= nil or item.next ~= nil")
        return
    end
    if self.first ~= nil then
        self.last.next = item
        item.pre = self.last
        self.last = item
        self.count = self.count + 1
    else
        self.first = item
        self.last = item
        self.count = 1
    end
end

---@param item TableLinedListNode
function TableLinkedList:Remove(item)
    if self.first == self.last and self.first == item then
        self.first = nil
        self.last = nil
        self.count = 0
        return
    end
    if item.pre == nil and item.next == nil then
        g_Logger.Error("LinedList:Remove(item) error. item.pre == nil or item.next == nil")
        return
    end
    if item.pre ~= nil then
        local pre = item.pre
        local next = item.next
        if next ~= nil then
            pre.next = next
            next.pre = pre
            item.next = nil
        else
            pre.next = nil
            self.last = pre
        end
        item.pre = nil
    else
        local next = item.next
        if next ~= nil then
            next.pre = nil
            self.first = next
            item.next = nil
        else
            self.last = nil
        end
    end
    self.count = self.count - 1
end

return TableLinkedList
