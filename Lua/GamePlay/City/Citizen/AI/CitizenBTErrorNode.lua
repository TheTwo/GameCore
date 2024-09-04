
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTErrorNode:CitizenBTNode
---@field new fun():CitizenBTErrorNode
---@field super CitizenBTNode
local CitizenBTErrorNode = class('CitizenBTErrorNode', CitizenBTNode)

function CitizenBTErrorNode:InitFromConfig(config)
    self._config = config
end

function CitizenBTErrorNode:Run(context, gContext)
    if UNITY_DEBUG then
        if not self._config then
            error(("CitizenBTErrorNode nil config, id:%s"):format(self._config:Id()))
        else
            error(("CitizenBTErrorNode configId:%s"):format(self._config:Id()))
        end
    end
    return false
end

return CitizenBTErrorNode