local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require("ModuleRefer")
local HeroCardSkipMediator = class('HeroCardSkipMediator',BaseUIMediator)

function HeroCardSkipMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.goBase = self:GameObject('p_base')
    self.btnSkip = self:Button('p_btn_skip', Delegate.GetOrCreate(self, self.OnBtnSkipClicked))
    self.textSkip = self:Text('p_text_skip', I18N.Get("gacha_skip"))
    self.goBase:SetActive(false)
end

function HeroCardSkipMediator:OnOpened()

end

function HeroCardSkipMediator:OnBtnSkipClicked(args)
    ModuleRefer.HeroCardModule:SkipTimeline()
end

function HeroCardSkipMediator:ShowBase(param)
    self.goBase:SetActive(true)
    self.btnSkip.gameObject:SetActive(false)
end


function HeroCardSkipMediator:OnClose(param)

end


return HeroCardSkipMediator
