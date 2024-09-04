local BaseModule = require ('BaseModule')
local ConfigRefer = require('ConfigRefer')
local AttrRuleDisplay = require('AttrRuleDisplay')
local AttrValueType = require('AttrValueType')
local NumberFormatter = require("NumberFormatter")

---@class AttrModule:BaseModule
local AttrModule = class('AttrModule', BaseModule)

function AttrModule:OnRegister()

end

function AttrModule:OnRemove()
	self.attrGroups = nil
end

function AttrModule:CalcAttrGroupByTemplateId(tId, level)
    local lv = level or 1
    local tempCfg = ConfigRefer.AttrTemplate:Find(tId)
	if (not tempCfg) then return end
    local attrGroupId = tempCfg:AttrGroupIdList(lv)
	return self:CalcAttrGroupByGroupId(attrGroupId)
end

---@return {type:number, value:number, originValue:number, icon:string}[]
function AttrModule:CalcAttrGroupByGroupId(groupId)
	self.attrGroups = self.attrGroups or {}
	local attrList = self.attrGroups[groupId]
	if attrList ~= nil then
		return attrList
	end

    local groupCfg = ConfigRefer.AttrGroup:Find(groupId)
	if groupCfg == nil then
		return {}
	end

    local attrList = {}

    for i = 1, groupCfg:AttrListLength() do
        local attrKV = groupCfg:AttrList(i)
        local typeId = attrKV:TypeId()
        local originValue = attrKV:Value()
        local attrCfg = ConfigRefer.AttrElement:Find(typeId)
		local value = self:GetAttrValueByType(attrCfg, originValue)
        attrList[#attrList + 1] = {type = typeId, value = value, originValue = originValue, icon=attrCfg:Icon()}
    end

	self.attrGroups[groupId] = attrList

    return attrList
end

--- 获取属性显示值
---@param self AttrModule
---@param dispId number AttrDisplay配置ID
---@param tId number AttrTemplate配置ID
---@param level number
---@return number, string, string, boolean 数值, 显示名称, 格式化后的数值, 是否显示
function AttrModule:GetDisplayValue(dispId, tId, level)
	local dispConf = ConfigRefer.AttrDisplay:Find(dispId)
	if (not dispConf) then return end
	local attrList = self:CalcAttrGroupByTemplateId(tId, level)
	if (not attrList) then return end
	return self:GetDisplayValueWithData(dispConf, attrList, level)
end

--- 使用已有数据获取属性显示值
---@param self AttrModule
---@param dispConf AttrDisplayConfigCell
---@param attrList {type:number, value:number, icon:string}[]
---@return number, string, string, boolean, string 数值, 显示名称, 格式化后的数值, 是否显示, 图标(取第一个base 的icon 配置)
function AttrModule:GetDisplayValueWithData(dispConf, attrList)
	local dispStr = dispConf:DisplayAttr()
	local baseType = dispConf:BaseAttrTypeId()
	local multiType = dispConf:MultiAttrTypeId()
	local pointType = dispConf:PointAttrTypeId()
	local baseValue = 0
	local multiValue = 1
	local pointValue = 0
	local icon = string.Empty
	if (attrList) then
		for _, attr in ipairs(attrList) do
			if (attr.type == baseType) then
				if string.IsNullOrEmpty(icon) then
					icon = attr.icon
				end
				baseValue = attr.value
			elseif (attr.type == multiType) then
				multiValue = 1 + attr.value
			elseif (attr.type == pointType) then
				pointValue = attr.value
			end
		end
	end
	local value = baseValue * multiValue + pointValue
	return value, dispStr, self:GetFormattedAttrValue(dispConf, value), self:IsAttrValueShow(dispConf, value), icon
end

--- 是否显示指定属性值
---@param self AttrModule
---@param dispConf AttrDisplayConfigCell
---@param value number
---@return boolean
function AttrModule:IsAttrValueShow(dispConf, value)
	if (not dispConf or not value) then return false end
	local rule = dispConf:DisplayRule()

	-- 自然数
	if (rule == AttrRuleDisplay.NaturalNum) then
		return (value > 0)
	end

	return true
end

---@param dispConf AttrDisplayConfigCell
---@param value number
---@return string
function AttrModule:GetFormattedAttrValue(dispConf, value)
	local type = dispConf:AttrValueType()
	if (type == AttrValueType.Percentages) then
		return value .. "%"
	elseif (type == AttrValueType.OneTenThousand) then
		return value * 100 .. "%"
	else
		if value and value >= 1 then
			local noPointPart = (value - math.floor(value + 0.5)) < 0.000001
			if noPointPart then
				return tostring(math.floor(value + 0.5))
			end
		end
		return tostring(value)
	end
end

---@param attrElementId number
---@param value number
---@return number
function AttrModule:GetAttrValueById(attrElementId, value)
	if not attrElementId then return 0 end
	local attrElementCfg = ConfigRefer.AttrElement:Find(attrElementId)
	if not attrElementCfg then return 0 end
	return self:GetAttrValueByType(attrElementCfg, value)
end

---@param attrElementCfg AttrElementConfigCell
---@param value number
---@return number
function AttrModule:GetAttrValueByType(attrElementCfg, value)
	local valueType = attrElementCfg:ValueType()
	if valueType == AttrValueType.Percentages then
		return value / 100
	elseif valueType == AttrValueType.OneTenThousand then
		return value / 10000
	elseif valueType == AttrValueType.Fix then
		return value
	end
	return value
end

---@param attrElementCfg AttrElementConfigCell
---@param value number
---@return string
function AttrModule:GetAttrValueShowTextByType(attrElementCfg, value)
	local valueType = attrElementCfg:ValueType()
	if valueType == AttrValueType.Percentages then
		return value .. "%"
	elseif valueType == AttrValueType.OneTenThousand then
		return string.format("%0.2f", (value / 100)) .. "%"
	elseif valueType == AttrValueType.Fix then
		return tostring(value)
	end
	return tostring(value)
end

---@param attrElementCfg AttrElementConfigCell
---@param value number
---@return number
function AttrModule:GetAttrPercentValueByType(attrElementCfg, value)
	local valueType = attrElementCfg:ValueType()
	if valueType == AttrValueType.Percentages then
		return value
	elseif valueType == AttrValueType.OneTenThousand then
		return value / 100
	elseif valueType == AttrValueType.Fix then
		return value
	end
	return value
end

---@param elementCfgId number @ref-AttrElementConfigCell
---@param value number
---@return string
function AttrModule:GetAttrValueShowTextByTypeWithSign(elementCfgId, value, deicimal)
	local elementCfg = ConfigRefer.AttrElement:Find(elementCfgId)
	local valueType = elementCfg:ValueType()
	if valueType == AttrValueType.Percentages then
		return NumberFormatter.PercentWithSignSymbol(value / 100, deicimal, true)
	elseif valueType == AttrValueType.OneTenThousand then
		return NumberFormatter.PercentWithSignSymbol(value / 10000, deicimal, true)
	elseif valueType == AttrValueType.Fix then
		return NumberFormatter.NumberAbbr(value, true, true)
	end
	return tostring(value)
end

return AttrModule
