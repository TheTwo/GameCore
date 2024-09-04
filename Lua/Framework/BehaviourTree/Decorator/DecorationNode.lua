local NodeBase = require("NodeBase")
---@class DecorationNode:NodeBase
---@field new fun():DecorationNode
---@field child NodeBase
local DecorationNode = class("DecorationNode", NodeBase)

function DecorationNode:ctor(node)
    DecorationNode.super.ctor(self);
    self.child = node;
end

function DecorationNode:Reset()
    if not self:IsInvalid() then
        DecorationNode.super.Reset(self);
        self.child:Reset();
    end
end

function DecorationNode:OnExecute()
    return self.child:Update();
end

function DecorationNode:OnExit()
    DecorationNode.super.OnExit(self);
    self:Reset();
end

function DecorationNode:SetDepth(depth)
    self.depth = depth;
    self.child:SetDepth(depth + 1);
end

return DecorationNode