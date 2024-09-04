local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SkillTipAttributeCell : BaseTableViewProCell
local SkillTipAttributeCell = class('SkillTipAttributeCell', BaseTableViewProCell)

---@class SkillTipAttributeCellData
---@field icon number
---@field text string
---@field number number
---@field extra string
---@field showPercent boolean
---@field showArrow boolean

function SkillTipAttributeCell:ctor()
    self.id = 0
end

function SkillTipAttributeCell:OnCreate(param)
    self.icon = self:Image("p_icon_injure")
    self.text = self:Text("p_text_injure")
    self.number = self:Text("p_text_num_injure")
    self.extra = self:Text("p_text_add")
end

function SkillTipAttributeCell:OnShow(param)
end

function SkillTipAttributeCell:OnOpened(param)
end

function SkillTipAttributeCell:OnClose(param)
end

---@param param SkillTipAttributeCellData
function SkillTipAttributeCell:OnFeedData(param)
    if (param) then
        if (param.icon) then
            self:LoadSprite(param.icon, self.icon)
        end
        self.text.text = param.text
        if param.showPercent then
            self.number.text = CS.System.String.Format("{0:#0.#}%", param.number * 100)
        elseif param.showString then
            self.number.text = param.number
        else
            self.number.text = CS.System.String.Format("{0:#0.#}", param.number)
        end
        if param.showArrow then
            self.number.text = self.number.text .. " ->"
        end
        self.extra.text = param.extra
    end
end

function SkillTipAttributeCell:Select(param)

end

function SkillTipAttributeCell:UnSelect(param)

end

return SkillTipAttributeCell;
