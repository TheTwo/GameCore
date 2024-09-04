local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ArtResourceUtils = require('ArtResourceUtils')

---@class RadarFindTraceMediator : BaseUIMediator
local RadarFindTraceMediator = class('RadarFindTraceMediator', BaseUIMediator)

function RadarFindTraceMediator:OnCreate()
    self.p_text_content = self:Text('p_text_content')
    self.p_img = self:Image('p_img')
    self.p_btn_trace = self:Button('p_btn_trace', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_text = self:Text('p_text','radar_btn_new_clues')
    self.p_title = self:Text('p_title',"radar_title_new_clues")
end

function RadarFindTraceMediator:OnOpened(param)
    self.closeCallback = param.closeCallback
    self.p_text_content.text = I18N.Get(param.desc)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(param.image), self.p_img)
end

function RadarFindTraceMediator:OnClose()
    if self.closeCallback then
        self.closeCallback()
    end
end

function RadarFindTraceMediator:OnBtnClick()
    if self.closeCallback then
        self.closeCallback()
        self.closeCallback = nil
    end
    self:CloseSelf()
end

return RadarFindTraceMediator
