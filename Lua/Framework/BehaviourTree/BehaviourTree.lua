---@class BehaviourTree
---@field new fun():BehaviourTree
---@field root NodeBase
local BehaviourTree = class("BehaviourTree")

function BehaviourTree:ctor(root)
    self.root = root;
    self.root:SetDepth(0);
end

function BehaviourTree:Update()
    if self.root and not self.root:IsTerminated() then
        self.root:Update();
    end
end

return BehaviourTree