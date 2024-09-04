local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local UIHeroLocalData = require('UIHeroLocalData')
local I18N = require('I18N')

local CommonBattleLabel = class('CommonBattleLabel', BaseUIComponent)

function CommonBattleLabel:OnCreate()
    self.imgIconPosition = self:Image('p_icon_position')
    self.textPosition = self:Text('p_text_position')
    self.btnPosition = self:Button('p_btn_position', Delegate.GetOrCreate(self, self.OnBtnPositionClicked))
end

function CommonBattleLabel:OnClose()

end

function CommonBattleLabel:OnBtnPositionClicked(args)
    -- body
end

function CommonBattleLabel:OnFeedData(param)
    if not param then
        return
    end
    local battleInfo = UIHeroLocalData.BATTLE_LABEL[param.battleType]
    self.textPosition.text = I18N.Get(battleInfo.text)
    g_Game.SpriteManager:LoadSprite(battleInfo.icon, self.imgIconPosition)
end

return CommonBattleLabel