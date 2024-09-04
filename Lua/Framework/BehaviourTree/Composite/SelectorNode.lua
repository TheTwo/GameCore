local CompositeNodeBase = require("CompositeNodeBase")
---@class SelectorNode:CompositeNodeBase
---@field new fun():SelectorNode
local SelectorNode = class("SelectorNode", CompositeNodeBase)

function SelectorNode:ctor()
    SelectorNode.super.ctor(self);
    self.curNodeIdx = 1;
end

function SelectorNode:OnEnter()
    self.curNodeIdx = 1;
end

function SelectorNode:Execute()
    while true do
        if self.curNodeIdx <= #self.children then
            local child = self.children[self.curNodeIdx];
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

return SelectorNode