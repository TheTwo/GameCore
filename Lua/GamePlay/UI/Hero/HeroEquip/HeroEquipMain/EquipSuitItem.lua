local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

local EquipSuitItem = class('EquipSuitItem', BaseUIComponent)

function EquipSuitItem:OnCreate()
    self.btn = self:Button("", Delegate.GetOrCreate(self, self.onClick))
    self.imgIconSuit = self:Image('p_icon_suit')
    self.textSuit = self:Text('p_text_suit')
    self.textSuitNumber = self:Text('p_text_suit_number')
end

function EquipSuitItem:OnFeedData(param)
    self.param = param
    local suitCfg = ConfigRefer.Suit:Find(param.id)
    self:LoadSprite(suitCfg:Icon(), self.imgIconSuit)
    self.textSuit.text = I18N.Get(suitCfg:Name())
    self.textSuitNumber.text = param.num
end

function EquipSuitItem:onClick()
    if self.param.onClick then
        self.param.onClick()
    end
end

return EquipSuitItem
