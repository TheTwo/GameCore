local BaseTableViewProCell = require ('BaseTableViewProCell')
local ConfigRefer = require ('ConfigRefer')
local I18N = require ('I18N')
local AttrComputeType = require ('AttrComputeType')
local AttrValueType = require ('AttrValueType')

---@class UIPlayerPersonaliseGainCellData
---@field type number
---@field gainNum number
---@field index number

---@class UIPlayerPersonaliseGainCell : BaseTableViewProCell
local UIPlayerPersonaliseGainCell = class('UIPlayerPersonaliseGainCell', BaseTableViewProCell)


function UIPlayerPersonaliseGainCell:OnCreate()
    self.textGainName = self:Text('p_text_detail')
    self.textGainNum = self:Text('p_text_add_1')
    self.goBase = self:GameObject('p_base')
end

---@param param UIPlayerPersonaliseGainCellData
function UIPlayerPersonaliseGainCell:OnFeedData(param)
    if not param then
        return
    end
    self.goBase:SetActive(param.index % 2 == 0)
    local attrElement = ConfigRefer.AttrElement:Find(param.type)
    if attrElement then
        self.textGainName.text = I18N.Get(attrElement:Name())
        self.textGainNum.text = self:GetAttrValueStr(attrElement, param.gainNum)
    end
end

---@param attrElement AttrElementConfig
---@return string
function UIPlayerPersonaliseGainCell:GetAttrValueStr(attrElement, value)
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

return UIPlayerPersonaliseGainCell