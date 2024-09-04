local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceTechFuncType = require("AllianceTechFuncType")
local AllianceTechCondOperatorType = require("AllianceTechCondOperatorType")
local UIHelper = require("UIHelper")

---@class AllianceTechConditionHelper
---@field new fun():AllianceTechConditionHelper
local AllianceTechConditionHelper = class('AllianceTechConditionHelper')

---@param condition AllianceTechCondition
function AllianceTechConditionHelper.Parse(condition)
    local isRequireOk = false
    local requireName = string.Empty
    local requireIcon = string.Empty
    local requireCurrentValueStr = string.Empty
    local requireCurrentNeedValueStr = string.Empty
    local requireGroupId
    if condition:FunctionType() == AllianceTechFuncType.TechLevel then
        local parameterCount = condition:ParamsLength()
        local requireOperator = condition:CompareOperator()
        if parameterCount == 1 then
            requireGroupId = tonumber(condition:Params(1))
            local groupData = ModuleRefer.AllianceTechModule:GetTechGroupStatus(requireGroupId)
            local lv = groupData and groupData.Level or 0
            local configs = ModuleRefer.AllianceTechModule:GetTechGroupByGroupId(requireGroupId)
            local lvIndex = math.clamp(lv, 1,#configs)
            local config = configs[lvIndex]
            local requireValue = math.floor(condition:CompareValue() + 0.5)
            requireName = I18N.Get(config:Name())
            requireIcon = config:Icon()
            if requireOperator == AllianceTechCondOperatorType.EQ then
                isRequireOk = (lv == requireValue)
            elseif requireOperator == AllianceTechCondOperatorType.GT then
                isRequireOk = (lv > requireValue)
                requireValue = requireValue + 1
            elseif requireOperator == AllianceTechCondOperatorType.GE then
                isRequireOk = (lv >= requireValue)
            elseif requireOperator == AllianceTechCondOperatorType.LT then
                isRequireOk = (lv < requireValue)
                requireValue = requireValue - 1
            elseif requireOperator == AllianceTechCondOperatorType.LE then
                isRequireOk = (lv <= requireValue)
            end
            requireCurrentValueStr = lv
            requireCurrentNeedValueStr = tostring(requireValue)
        end
    end
    return isRequireOk, requireName, UIHelper.IconOrMissing(requireIcon),requireCurrentValueStr, requireCurrentNeedValueStr, requireGroupId
end

return AllianceTechConditionHelper