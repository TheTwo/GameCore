local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')

---@class RadarToastInfoMediator : BaseUIMediator
local RadarToastInfoMediator = class('RadarToastInfoMediator', BaseUIMediator)


function RadarToastInfoMediator:OnCreate()
    self.textHint = self:Text('p_text_hint')
    self.p_icon_info = self:Image('p_icon_info')
end

function RadarToastInfoMediator:OnOpened(param)
    g_Game.SpriteManager:LoadSprite(param.icon, self.p_icon_info)
    if param.content then
        self.textHint.text = I18N.GetWithParams("Radar_discover_elite", param.content)
    end
    TimerUtility.DelayExecute(function()
        self:CloseSelf()
    end, 2, param)
end


function RadarToastInfoMediator:OnClose(param)
    --TODO
end


return RadarToastInfoMediator