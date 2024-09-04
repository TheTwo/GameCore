---@class LRUList
---@field new fun(capcity:number):LRUList
---@field m_Map table<any, LRUListNode>
local LRUList = sealedClass("LRUList")
local LRUListNode = require("LRUListNode")
local LinkedList = require("LinkedList")

function LRUList:ctor(capacity)
    self.capacity = capacity or 16;
    self.m_Map = {};
    self.m_LinkedList = LinkedList.new();
end

function LRUList:Get(key)
    local node = self.m_Map[key];
    if node then
        self.m_LinkedList:Remove(node);
        self.m_LinkedList:PushBack(node);
        return node.value;
    end

    return nil;
end

function LRUList:Add(key, value)
    local node = self.m_Map[key];
    if node then
        self.m_LinkedList:Remove(node);
    elseif self.m_LinkedList.Count >= self.capacity then
        self:RemoveFront();
    end

    node = LRUListNode.new(key, value);
    self.m_LinkedList:PushBack(node);
    self.m_Map[key] = node;
end

---@return boolean
function LRUList:Remove(key)
    local node = self.m_Map[key];
    if not node then
        return false
    end
    self.m_LinkedList:Remove(node);
    self.m_Map[key] = nil
    return true
end

function LRUList:RemoveFront()

    local node = self.m_LinkedList:PopFront();
    if node then
        self.m_Map[node.key] = nil;
    end
end

function LRUList:Clear()
    self.m_Map = {};
    self.m_LinkedList = LinkedList.new();
end

return LRUList