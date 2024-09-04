local CompositeNodeBase = require("CompositeNodeBase")
---@class SequenceNode:CompositeNodeBase
---@field new fun():SequenceNode
local SequenceNode = class("SequenceNode", CompositeNodeBase)

function SequenceNode:ctor()
    SequenceNode.super.ctor(self);
    self.curNodeIdx = 1;
end

function SequenceNode:OnEnter()
    SequenceNode.super.OnEnter(self)
    self.curNodeIdx = 1;
end

function SequenceNode:Execute()
    while true do
        if self.curNodeIdx <= #self.children then
            local child = self.children[self.curNodeIdx];
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

return SequenceNode