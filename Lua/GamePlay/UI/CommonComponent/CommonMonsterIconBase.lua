local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')

---@class CommonMonsterIconBase : BaseUIComponent
local CommonMonsterIconBase = class('CommonMonsterIconBase', BaseUIComponent)

function CommonMonsterIconBase:ctor()

end

function CommonMonsterIconBase:OnCreate()
    self.p_img_hero = self:Image("p_img_hero")
    self.base_frame = self:Image('base_frame')
    self.p_text_lv = self:Text("p_text_lv")
    self.p_img_select = self:Image("p_img_select")
    self.p_btn_monster = self:Button('p_btn_monster', Delegate.GetOrCreate(self, self.OnBtnClick))

end

function CommonMonsterIconBase:OnFeedData(param)
    self.param = param

    if param.level then
        self.p_text_lv.text = param.level
    end

    if param.sprite then
        g_Game.SpriteManager:LoadSprite(param.sprite, self.p_img_hero)
    end

    if param.frame then
        g_Game.SpriteManager:LoadSprite(param.frame, self.base_frame)
    else
        g_Game.SpriteManager:LoadSprite("sp_hero_frame_circle_1", self.base_frame)
    end

end

function CommonMonsterIconBase:ShowCustomIcon(customIcon)
    g_Game.SpriteManager:LoadSprite(customIcon, self.p_img_hero)
end

function CommonMonsterIconBase:OnBtnClick()
    if self.param.onClick then
        self.param.onClick()
    end
end

return CommonMonsterIconBase
