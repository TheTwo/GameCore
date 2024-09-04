local DecorationNode = require("DecorationNode")
---@class InvertNode:DecorationNode
---@field new fun():InvertNode
local InvertNode = class("InvertNode", DecorationNode)

function InvertNode:Execute()
    local ret = self.child:Update();
    if ret == 0 then
        return 2;
    elseif ret == 2 then
        return 0;
    end
    return ret;
end

return InvertNode