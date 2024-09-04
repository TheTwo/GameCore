local CompositeNodeBase = require("CompositeNodeBase")
local BTUtils = require("BTUtils")
---@class RandomSequenceNode:CompositeNodeBase
---@field new fun():SequenceNode
local RandomSequenceNode = class("RandomSequenceNode", CompositeNodeBase)

function RandomSequenceNode:ctor()
    RandomSequenceNode.super.ctor(self);
    self.curNodeIdx = 1;
end

function RandomSequenceNode:OnEnter()
    RandomSequenceNode.super.OnEnter(self)
    self.curNodeIdx = 1;
    self.sequence = BTUtils.GetRandomList(#self.children);
end

function RandomSequenceNode:Execute()
    while true do
        if self.curNodeIdx <= #self.children then
            local child = self.children[self.sequence[self.curNodeIdx]];
            local state = child:Update();
            if state == 0 then
                return 0;
            elseif state == 2 then
                self.curNodeIdx = self.curNodeIdx + 1;
            else
                return 1;
            end
        else
            return 2;
        end
    end
end

return RandomSequenceNode