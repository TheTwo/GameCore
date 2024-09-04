---@class QueuedTaskNode
local QueuedTaskNode = class("QueuedTaskNode")

function QueuedTaskNode:Begin()
    
end

---@return boolean @comment 是否跳出循环
function QueuedTaskNode:Execute()
    return false
end

function QueuedTaskNode:End()
    
end

return QueuedTaskNode