local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
---@class UIPetSkillTabComp : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetSkillTabComp = class('UIPetSkillTabComp', BaseTableViewProCell)

function UIPetSkillTabComp:ctor()

end

function UIPetSkillTabComp:OnCreate()
    self.p_child_tab = self:StatusRecordParent("p_child_tab")
    self.btn = self:Button('p_child_tab', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_text_a = self:Text('p_text_a')
    self.p_text_b = self:Text('p_text_b')
end

function UIPetSkillTabComp:OnFeedData(param)
    self.param = param
    local name = ModuleRefer.PetModule:GetSkillTypeStr(param.type)
    self.p_text_a.text = name
    self.p_text_b.text = name

    if self.param.selected then
        self.p_child_tab:SetState(0)
    else
        self.p_child_tab:SetState(1)
    end
end

function UIPetSkillTabComp:OnBtnClick()
    if self.param.selected then
        self.p_child_tab:SetState(0)
    else
        self.p_child_tab:SetState(1)
    end
    self.param.onClick(self.param.index)
end

return UIPetSkillTabComp
