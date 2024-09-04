local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')
local BattlePassConst = require('BattlePassConst')
---@class HUDRescueBeauty : BaseUIComponent
local HUDRescueBeauty = class('HUDRescueBeauty', BaseUIComponent)

function HUDRescueBeauty:OnCreate()
    self.goRoot = self:GameObject('')
    self.p_btn_send_hero = self:Button('p_btn_send_hero', Delegate.GetOrCreate(self, self.OnButtonClick))
    self.p_text_activity_first = self:Text('p_text_activity_first', "new_activity_egirl9")
    self.notifyNode = self:LuaObject('child_reddot_default')

end

function HUDRescueBeauty:OnShow()
    local reddotNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("RescueBeauty_1_", NotificationType.RESCUE_BEAUTY_USE_ITEM)
    ModuleRefer.NotificationModule:AttachToGameObject(reddotNode, self.notifyNode.go, self.notifyNode.redDot)
end

function HUDRescueBeauty:OnButtonClick()
    g_Game.UIManager:Open(UIMediatorNames.HeroRescueMediator)
end

return HUDRescueBeauty
