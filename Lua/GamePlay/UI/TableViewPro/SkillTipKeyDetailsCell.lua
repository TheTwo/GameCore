local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SkillTipKeyDetailsCell : BaseTableViewProCell
local SkillTipKeyDetailsCell = class('SkillTipKeyDetailsCell', BaseTableViewProCell)

function SkillTipKeyDetailsCell:ctor()

end

function SkillTipKeyDetailsCell:OnCreate(param)
    self.root = self:GameObject("")
    self.textTitle = self:Text('p_text_title')
    self.textDetail = self:Text('p_text_detail')
end

function SkillTipKeyDetailsCell:GetHeightRight(showText)
    local settings = self.textDetail:GetGenerationSettings(CS.UnityEngine.Vector2(self.textDetail:GetPixelAdjustedRect().size.x, 0))
    local height = self.textDetail.cachedTextGeneratorForLayout:GetPreferredHeight(showText, settings) / self.textDetail.pixelsPerUnit
    return height + 70
end

function SkillTipKeyDetailsCell:OnShow(param)
end

function SkillTipKeyDetailsCell:OnOpened(param)
end

function SkillTipKeyDetailsCell:OnClose(param)
end

function SkillTipKeyDetailsCell:OnFeedData(param)
    if (param) then
        self.textTitle.text = param.title
        self.textDetail.text = param.detail
        local hight = self:GetHeightRight(param.detail)
        self.root.transform.sizeDelta = CS.UnityEngine.Vector2(self.root.transform.sizeDelta.x, hight)
    end
end

function SkillTipKeyDetailsCell:Select(param)

end

function SkillTipKeyDetailsCell:UnSelect(param)

end

return SkillTipKeyDetailsCell
