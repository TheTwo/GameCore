---@class LinkedListNode
local LinkedListNode = class("LinkedListNode")

function LinkedListNode:ctor()
    self.m_Prev = nil
    self.m_Next = nil
end

return LinkedListNode