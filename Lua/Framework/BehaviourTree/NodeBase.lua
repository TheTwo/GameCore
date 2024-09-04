---@class NodeBase
---@field new fun():NodeBase
local NodeBase = class("NodeBase")

--- -1  Invalid
--- 0   Failure
--- 1   Running
--- 2   Succeed

function NodeBase:ctor()
    self.state = -1;
    self.depth = -1;
end

function NodeBase:Execute()
    return 2;
end

function NodeBase:Update()
    if self:IsInvalid() then
        self:OnEnter();
    end

    self.state = self:Execute();
    local ret = self.state;
    if self:IsTerminated() then
        self:OnExit();
    end

    return ret;
end

function NodeBase:OnEnter()
    self.state = 1;
end

function NodeBase:OnExit()
    
end

function NodeBase:Reset()
    self.state = -1;
end

function NodeBase:IsInvalid()
    return self.state == -1;
end

function NodeBase:IsTerminated()
    return self.state == 0 or self.state == 2;
end

function NodeBase:SetDepth(depth)
    self.depth = depth;
end

function NodeBase:Print(state)
    g_Logger.Log(("%s at depth %d is %s"):format(GetClassOf(self).__cname, self.depth, state));
end

function NodeBase:GetStateDesc()
    if self.state == -1 then
        return "Invalid";
    elseif self.state == 0 then
        return "Failure";
    elseif self.state == 1 then
        return "Running";
    else
        return "Succeed";
    end
end

return NodeBase