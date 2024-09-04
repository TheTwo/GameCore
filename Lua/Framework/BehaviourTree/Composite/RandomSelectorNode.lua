local BTUtils = require("BTUtils")
local CompositeNodeBase = require("CompositeNodeBase")
---@class RandomSelectorNode:CompositeNodeBase
---@field new fun():RandomSelectorNode
local RandomSelectorNode = class("RandomSelectorNode", CompositeNodeBase)

function RandomSelectorNode:ctor()
    RandomSelectorNode.super.ctor(self);
    self.curNodeIdx = 1;
end

function RandomSelectorNode:OnEnter()
    self.curNodeIdx = 1;
    self.sequence = BTUtils.GetRandomList(#self.children);
end

function RandomSelectorNode:Execute()
    while true do
        if self.curNodeIdx <= #self.children then
            local child = self.children[self.sequence[self.curNodeIdx]];
            local state = child:Update();
            if state == 0 then
                self.curNodeIdx = self.curNodeIdx + 1;
            else
                return state;
            end
        else
            return 0;
        end
    end
end

return RandomSelectorNode