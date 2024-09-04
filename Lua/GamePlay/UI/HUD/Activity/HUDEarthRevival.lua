local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
---@class HUDEarthRevival : BaseUIComponent
local HUDEarthRevival = class('HUDEarthRevival', BaseUIComponent)

function HUDEarthRevival:ctor()
    self.isReddotDirty = false
end

function HUDEarthRevival:OnCreate()
    self.goRoot = self:GameObject('')
    self.btnRoot = self:Button('p_btn_world_trend', Delegate.GetOrCreate(self, self.OnClicked))
    self.textName = self:Text('p_text_world_trend', "worldstage_news")
    self.notifyNode = self:LuaObject('child_reddot_default')
end

function HUDEarthRevival:OnOpened()
    ModuleRefer.EarthRevivalModule:RefreshRedDot()
    local redNode = ModuleRefer.EarthRevivalModule.btnRedDot
	ModuleRefer.NotificationModule:AttachToGameObject(redNode, self.notifyNode.go, self.notifyNode.redDot)
    g_Game.EventManager:AddListener(EventConst.HUD_TYPE_VISIBLE, Delegate.GetOrCreate(self, self.RefreshReddot))
    self:UpdateShow()
end

function HUDEarthRevival:OnShow()
    self:UpdateShow()
end

function HUDEarthRevival:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.HUD_TYPE_VISIBLE, Delegate.GetOrCreate(self, self.RefreshReddot))
end

function HUDEarthRevival:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.HUD_TYPE_VISIBLE, Delegate.GetOrCreate(self, self.RefreshReddot))
end

function HUDEarthRevival:UpdateShow()
    local isOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(31)
    self.goRoot:SetActive(isOpen)
end

function HUDEarthRevival:OnClicked()
    ModuleRefer.EarthRevivalModule:OpenEarthRevivalMediator()
end

function HUDEarthRevival:RefreshReddot()
    if ModuleRefer.PlayerModule:GetPlayer() then
        ModuleRefer.EarthRevivalModule:RefreshRedDot()
    end
end

return HUDEarthRevival