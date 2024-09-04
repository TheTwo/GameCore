local NodeBase = require("NodeBase")
---@class LeafNode:NodeBase
---@field new fun():LeafNode
local LeafNode = class("LeafNode", NodeBase)

return LeafNode