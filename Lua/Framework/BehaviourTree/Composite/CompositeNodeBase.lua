local NodeBase = require("NodeBase")
---@class CompositeNodeBase:NodeBase
---@field new fun():CompositeNodeBase
---@field children NodeBase[]
local CompositeNodeBase = class("CompositeNodeBase", NodeBase)

function CompositeNodeBase:ctor()
    CompositeNodeBase.super.ctor(self);
    self.children = {}
end

function CompositeNodeBase:AppendNode(node)
    table.insert(self.children, node);
end

function CompositeNodeBase:InsertNode(node, index)
    table.insert(self.children, index, node);
end

function CompositeNodeBase:RemoveNode(node)
    table.removebyvalue(self.children, node);
end

function CompositeNodeBase:RemoveNodeAt(index)
    table.remove(self.children, index);
end

function CompositeNodeBase:Reset()
    if not self:IsInvalid() then
        CompositeNodeBase.super.Reset(self);
        for i, v in ipairs(self.children) do
            v:Reset();
        end
    end        
end

function CompositeNodeBase:OnExit()
    CompositeNodeBase.super.OnExit(self);
    self:Reset()
end

function CompositeNodeBase:SetDepth(depth)
    self.depth = depth;
    for i, v in ipairs(self.children) do
        v:SetDepth(depth + 1);
    end
end

return CompositeNodeBase