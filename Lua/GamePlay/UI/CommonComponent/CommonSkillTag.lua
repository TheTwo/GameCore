local BaseUIComponent = require ('BaseUIComponent')
local I18N = require("I18N")

---@class CommonSkillTag : BaseUIComponent
local CommonSkillTag = class('CommonSkillTag', BaseUIComponent)

function CommonSkillTag:ctor()

end

function CommonSkillTag:OnCreate()
    self.baseTag = self:Image("p_base_tag")
    self.iconTag = self:Image("p_icon_tag")
    self.skillText = self:Text("p_text_skill")
end

function CommonSkillTag:OnFeedData(param)
    self.skillText.text = I18N.Get(param.text)
    if param.icon then
        g_Game.SpriteManager:LoadSprite(param.icon, self.iconTag)
    end
end

return CommonSkillTag
