local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
---@type MailModule
local Mail = ModuleRefer.MailModule

---@class SkillTipNameCell : BaseTableViewProCell
local SkillTipNameCell = class('SkillTipNameCell', BaseTableViewProCell)

function SkillTipNameCell:ctor()
    self.id = 0
end

function SkillTipNameCell:OnCreate(param)
    self.textName = self:Text("p_text_skill_name")
    self.heroIcon = self:LuaObject("child_card_hero_s")
end

function SkillTipNameCell:OnShow(param)
end

function SkillTipNameCell:OnOpened(param)
end

function SkillTipNameCell:OnClose(param)
end

function SkillTipNameCell:OnFeedData(param)
    if (param) then
        self.textName.text = param.name
        local heroCfg = ConfigRefer.Heroes:Find(param.heroConfigId)
        if (not heroCfg) then
            self.heroIcon.CSComponent.gameObject:SetActive(false)
        else
            self.heroIcon.CSComponent.gameObject:SetActive(true)
            self.heroIcon:FeedData(param.heroConfigId)
        end
    end
end

function SkillTipNameCell:Select(param)

end

function SkillTipNameCell:UnSelect(param)

end

return SkillTipNameCell;
