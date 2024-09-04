local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionWriteFindPerformanceTargetParam:CitizenBTActionNode
---@field new fun():CitizenBTActionWriteFindPerformanceTargetParam
---@field super CitizenBTActionNode
local CitizenBTActionWriteFindPerformanceTargetParam = class('CitizenBTActionWriteFindPerformanceTargetParam', CitizenBTActionNode)

function CitizenBTActionWriteFindPerformanceTargetParam:InitFromConfig(config)
    ---@type CitizenBTActionFindPerformanceTargetContextParam
    self._param = {}
    self._param.pointType = config:PointType()
    self._param.tagsMask = 0
    self._param.dumpStr = CitizenBTDefine.DumpPointSearchParam
    for i = 1, config:TagsParamLength() do
        self._param.tagsMask = self._param.tagsMask | (1 << config:TagsParam(i))
    end
end

function CitizenBTActionWriteFindPerformanceTargetParam:Run(context, gContext)
    context:Write(CitizenBTDefine.ContextKey.InteractPointSearchParam, self._param)
    return CitizenBTActionWriteFindPerformanceTargetParam.super.Run(self, context, gContext)
end

return CitizenBTActionWriteFindPerformanceTargetParam