local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')

---@class TouchMenuCellSkill : BaseUIComponent
---@field p_league_logo CommonAllianceLogoComponent
local TouchMenuCellSkill = class("TouchMenuCellSkill", BaseUIComponent)

function TouchMenuCellSkill:OnCreate()
    self.root = self:RectTransform("")
    self.p_text_title = self:Text('p_text_skill')
    ---@type BaseSkillIcon[]
    self.p_skillIcons = {}
    self.p_skillIcons[1] = self:LuaObject('child_item_skill_1')
    self.p_skillIcons[2] = self:LuaObject('child_item_skill_2')
    self.p_skillIcons[3] = self:LuaObject('child_item_skill_3')
    self.p_skillIcons[4] = self:LuaObject('child_item_skill_4')
    self.p_skillIcons[5] = self:LuaObject('child_item_skill_5')
    
    self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClicked))    
end

---@param data TouchMenuCellSkillDatum
function TouchMenuCellSkill:OnFeedData(data)
    self.data = data
    self.p_text_title.text = self.data.label
    self.p_text_title.color = self.data.labelColor or CS.UnityEngine.Color.white

    for i = 1, 5 do
        local skillId = self.data.skillIds[i]
        if skillId then
            self.p_skillIcons[i]:SetVisible(true)
            ---@type BaseSkillIconData
            local skillIconData = {}
            skillIconData.skillId = skillId
            skillIconData.isSlg = true
            self.p_skillIcons[i]:FeedData(skillIconData)
        else
            self.p_skillIcons[i]:SetVisible(false)
        end
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.root)

end

function TouchMenuCellSkill:OnClose()
    self.data = nil
end

function TouchMenuCellSkill:OnGotoClicked()
    if self.data and self.data.clickCallback then
        self.data.clickCallback()
    end
end

return TouchMenuCellSkill