local LinkedListNode = require("LinkedListNode")

---@class LinkedList
---@field new fun():LinkedList
local LinkedList = sealedClass("LinkedList")

function LinkedList:ctor()
    self.Count = 0;
    self.m_Null = LinkedListNode.new()
    self.m_Null.m_Next = self.m_Null
    self.m_Null.m_Prev = self.m_Null
end

---@return LinkedListNode
function LinkedList:GetFirst()
    return self.m_Null.m_Next
end

---@return LinkedListNode
function LinkedList:GetLast()
    return self.m_Null.m_Prev
end

---@return LinkedListNode
function LinkedList:GetEnd()
    return self.m_Null
end

---@param node LinkedListNode
function LinkedList:PushBack(node)
    local prev = self.m_Null.m_Prev

    prev.m_Next = node
    node.m_Prev = prev

    node.m_Next = self.m_Null
    self.m_Null.m_Prev = node

    self.Count = self.Count + 1;
end

---@return LinkedListNode
function LinkedList:PopBack()
    if not self:IsEmpty() then
        local node = self.m_Null.m_Prev
        local prev = node.m_Prev
    
        prev.m_Next = self.m_Null
        self.m_Null.m_Prev = prev
    
        node.m_Prev = nil
        node.m_Next = nil
    
        self.Count = self.Count - 1;
        return node
    end
    
    return nil
end

---@param node LinkedListNode
function LinkedList:PushFront(node)
    local next = self.m_Null.m_Next
    
    next.m_Prev = node
    node.m_Next = next
    
    node.m_Prev = self.m_Null
    self.m_Null.m_Next = node
    self.Count = self.Count + 1;
end

---@return LinkedListNode
function LinkedList:PopFront()
    if not self:IsEmpty() then
        local node = self.m_Null.m_Next
        local next = node.m_Next

        next.m_Prev = self.m_Null
        self.m_Null.m_Next = next

        node.m_Prev = nil
        node.m_Next = nil

        self.Count = self.Count - 1;
        return node
    end
    
    return nil
end

---@param node LinkedListNode
function LinkedList: Remove(node)
    local prev = node.m_Prev
    local next = node.m_Next
    
    prev.m_Next = next
    next.m_Prev = prev
    
    node.m_Prev = nil
    node.m_Next = nil
    self.Count = self.Count - 1;
end

---@return boolean 
function LinkedList:IsEmpty()
    return (self.m_Null.m_Prev == self.m_Null and self.m_Null.m_Next == self.m_Null)
end

function LinkedList:Clear()
    self.m_Null.m_Next = self.m_Null
    self.m_Null.m_Prev = self.m_Null
end

return LinkedList