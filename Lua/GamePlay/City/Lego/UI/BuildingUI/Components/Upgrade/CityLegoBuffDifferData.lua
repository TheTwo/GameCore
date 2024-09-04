---@class CityLegoBuffDifferData
---@field new fun(elementId, fromOriginValue, toOriginValue, prefix):CityLegoBuffDifferData
local CityLegoBuffDifferData = class("CityLegoBuffDifferData")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local AttrValueType = require("AttrValueType")
local NumberFormatter = require("NumberFormatter")
local TimeFormatter = require("TimeFormatter")
local TimeAttrMap = {
    [21221] = true,
    [21222] = true,
    [21223] = true,
    [21224] = true,
    [21225] = true,
    [21226] = true,
    [21227] = true,
    [21228] = true,
    [21229] = true,
    [21230] = true,
    [21231] = true,
    [21232] = true,
    [21233] = true,
    [21240] = true,
}

function CityLegoBuffDifferData:ctor(elementId, oldValue, newValue, prefix)
    self.elementId = elementId
    self.oldValue = oldValue
    self.newValue = newValue
    self.prefix = prefix
    self.elementCfg = ConfigRefer.AttrElement:Find(elementId)
end

function CityLegoBuffDifferData:GetUniqueName()
    return ("%s_%d"):format(self.prefix, self.elementId)
end

function CityLegoBuffDifferData:GetName()
    if self.prefix == nil then
        return I18N.Get(self.elementCfg:Name())
    else
        return I18N.GetWithParams(self.prefix, I18N.Get(self.elementCfg:Name()))
    end
end

function CityLegoBuffDifferData:ShowArrow()
    return self.oldValue ~= nil and self.newValue ~= nil
end

function CityLegoBuffDifferData:GetOldValueText()
    if not self.oldValue then return string.Empty end
    local valueType = self.elementCfg:ValueType()
    local flag = valueType ~= AttrValueType.Fix
    local realValue = self.oldValue
    if valueType == AttrValueType.Percentages then
        realValue = realValue / 100
    elseif valueType == AttrValueType.OneTenThousand then
        realValue = realValue / 10000
    end

    if flag then
        return NumberFormatter.PercentWithSignSymbol(realValue, 2, true)
    elseif self:IsTimeAttr(self.elementCfg:Id()) then
        return "+"..TimeFormatter.TimerStringFormat(realValue, true)
    else
        return NumberFormatter.NumberAbbr(realValue, true, true)
    end
end

function CityLegoBuffDifferData:GetNewValueText()
    if not self.newValue then return string.Empty end
    local valueType = self.elementCfg:ValueType()
    local flag = valueType ~= AttrValueType.Fix
    local realValue = self.newValue
    if valueType == AttrValueType.Percentages then
        realValue = realValue / 100
    elseif valueType == AttrValueType.OneTenThousand then
        realValue = realValue / 10000
    end

    if flag then
        return NumberFormatter.PercentWithSignSymbol(realValue, 2, true)
    elseif self:IsTimeAttr(self.elementCfg:Id()) then
        return "+"..TimeFormatter.TimerStringFormat(realValue, true)
    else
        return NumberFormatter.NumberAbbr(realValue, true, true)
    end
end

function CityLegoBuffDifferData:GetDiffValueText()
    local oldValue = self.oldValue or 0
    local newValue = self.newValue or 0
    local valueType = self.elementCfg:ValueType()

    local flag = valueType ~= AttrValueType.Fix
    local realValue = newValue - oldValue
    if valueType == AttrValueType.Percentages then
        realValue = realValue / 100
    elseif valueType == AttrValueType.OneTenThousand then
        realValue = realValue / 10000
    end

    if flag then
        return NumberFormatter.PercentWithSignSymbol(realValue, 2, true)
    elseif self:IsTimeAttr(self.elementCfg:Id()) then
        return "+"..TimeFormatter.TimerStringFormat(realValue, true)
    else
        return NumberFormatter.NumberAbbr(realValue, true, true)
    end
end

function CityLegoBuffDifferData:IsTimeAttr(id)
    return TimeAttrMap[id]
end

return CityLegoBuffDifferData