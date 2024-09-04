local BaseTableViewProCell = require ('BaseTableViewProCell')
local AttrValueType = require('AttrValueType')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')

---@class UIHeroStrengthAttrCell : BaseTableViewProCell
local UIHeroStrengthAttrCell = class('UIHeroStrengthAttrCell', BaseTableViewProCell)

function UIHeroStrengthAttrCell:ctor()

end

function UIHeroStrengthAttrCell:OnCreate()
    self.textText = self:Text('p_text_strengthen')
    self.textNumber = self:Text('p_text_num')
    self.textNumberAdd = self:Text('p_text_add')
end


function UIHeroStrengthAttrCell:OnShow(param)
end

function UIHeroStrengthAttrCell:OnOpened(param)
end

function UIHeroStrengthAttrCell:OnClose(param)
end

function UIHeroStrengthAttrCell:OnFeedData(param)
    local info = param.info
    if info then
        self.textText.text = I18N.Get(info.typeInfo:Name())
        local isPct = info.typeInfo:ValueType() ~= AttrValueType.Fix
        if isPct then
            local value = ModuleRefer.AttrModule:GetAttrValueByType(info.typeInfo, info.value)
            self.textNumberAdd.text = I18N.GetWithParams("hero_attr_pro", value) .. "%"
        else
            self.textNumberAdd.text = tostring( info.value )
        end
    end
end

function UIHeroStrengthAttrCell:Select(param)

end
function UIHeroStrengthAttrCell:UnSelect(param)

end

return UIHeroStrengthAttrCell;
