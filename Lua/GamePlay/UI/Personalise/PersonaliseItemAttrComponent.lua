local BaseUIComponent = require ('BaseUIComponent')
local ConfigRefer = require ('ConfigRefer')
local AttrComputeType = require ('AttrComputeType')
local I18N = require ('I18N')
local AttrValueType = require ('AttrValueType')

---@class PersonaliseItemAttrComponent : BaseUIComponent
local PersonaliseItemAttrComponent = class('PersonaliseItemAttrComponent', BaseUIComponent)

---@class PersonaliseItemAttrParam
---@field type number
---@field value string

function PersonaliseItemAttrComponent:OnCreate()
    self.textName = self:Text('p_text_property_name')
    self.textValue = self:Text('p_text_property_value')
end

---@param param PersonaliseItemAttrParam
function PersonaliseItemAttrComponent:OnFeedData(param)
    if not param then
        return
    end
    if param.type == -1 and param.value == -1 then
        self.textName.text = I18N.Get("skincollection_nonebonus")
        return
    end
    local attrElement = ConfigRefer.AttrElement:Find(param.type)
    if attrElement then
        self.textName.text = I18N.Get(attrElement:Name())
        self.textValue.text = self:GetAttrValueStr(attrElement, param.value)
    end
end

---@param attrElement AttrElementConfig
---@return string
function PersonaliseItemAttrComponent:GetAttrValueStr(attrElement, value)
    if not attrElement then
            return string.Empty
    end
    local baseValue = 0
    local multiValue = 0
    local pointValue = 0
    if (attrElement:ComputeType() == AttrComputeType.Base) then
        baseValue = value
    elseif (attrElement:ComputeType() == AttrComputeType.Multi) then
        if attrElement:ValueType() == AttrValueType.OneTenThousand then
            --万分比最后还是要显示成百分比
            multiValue = value / 100
        elseif attrElement:ValueType() == AttrValueType.Percentages then
            multiValue = value / 100
        elseif attrElement:ValueType() == AttrValueType.Fix then
            multiValue = value
        end
    elseif (attrElement:ComputeType() == AttrComputeType.Point) then
        pointValue = value
    end
    if baseValue > 0 then
        return string.format("+%d", baseValue)
    elseif multiValue > 0 then
        return string.format("+%0.1f%%", multiValue)
    elseif pointValue > 0 then
        return string.format("+%d", pointValue)
    end

end


return PersonaliseItemAttrComponent