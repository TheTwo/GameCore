local LinkedListNode = require("LinkedListNode")
---@class LRUListNode:LinkedListNode
---@generic TK
---@generic TV
---@field new fun(key:TK, value:TV):LRUListNode
---@field key TK
---@field value TV
local LRUListNode = class("LRUListNode", LinkedListNode)

function LRUListNode:ctor(key, value)
    LRUListNode.super.ctor(self)
    self.key = key;
    self.value = value;
end

return LRUListNode