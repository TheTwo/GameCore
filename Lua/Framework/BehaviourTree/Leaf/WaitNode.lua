local LeafNode = require("LeafNode")
---@class WaitNode:LeafNode
---@field new fun():WaitNode
local WaitNode = class("WaitNode", LeafNode)

function WaitNode:ctor(time)
    WaitNode.super.ctor(self);
    self.duration = time;
end

function WaitNode:OnEnter()
    self.time = g_Game.Time.time + self.duration;
end

function WaitNode:Execute()
    if g_Game.Time.time < self.time then
        return 1;
    else
        return 2;
    end
end

return WaitNode