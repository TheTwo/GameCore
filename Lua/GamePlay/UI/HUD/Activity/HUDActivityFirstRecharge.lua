local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
---@class HUDActivityFirstRecharge : BaseUIComponent
local HUDActivityFirstRecharge = class("HUDActivityFirstRecharge", BaseUIComponent)

local JaydenUSD1 = 1
local JaydenUSD5 = 2

function HUDActivityFirstRecharge:ctor()
    self.popId = nil
    self.groupId = nil
end

function HUDActivityFirstRecharge:OnCreate()
    self.root = self:GameObject("")
    self.textTitle = self:Text("p_text_activity_first", "first_pay_hub_name")
    self.btnRoot = self:Button("p_btn_first_charge", Delegate.GetOrCreate(self, self.OnClick))
    self.luaNotifyNode = self:LuaObject("child_reddot_default")
end

function HUDActivityFirstRecharge:OnShow()
    self.luaNotifyNode:SetVisible(false)
    self:Init()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Window.MsgPath,Delegate.GetOrCreate(self,self.OnPopupListChange))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnPayGroupChange))
end

function HUDActivityFirstRecharge:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Window.MsgPath,Delegate.GetOrCreate(self,self.OnPopupListChange))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnPayGroupChange))
end

function HUDActivityFirstRecharge:OnClick()
    ---@type FirstRechargePopUpMediatorParam
    local data = {}
    data.isFromHud = true
    data.popIds = {self.popId}
    g_Game.UIManager:Open(UIMediatorNames.FirstRechargePopUpMediator, data)
end

function HUDActivityFirstRecharge:OnPopupListChange()
    self:Init()
end

function HUDActivityFirstRecharge:OnPayGroupChange()
    self:Init()
end

function HUDActivityFirstRecharge:Init()
    local popIds = ModuleRefer.LoginPopupModule:GetAllAvailablePopIdsForPayGroups()
    if table.ContainsValue(popIds, JaydenUSD1) then
        self.popId = JaydenUSD1
    elseif table.ContainsValue(popIds, JaydenUSD5) then
        self.popId = JaydenUSD5
    else
        self.popId = nil
    end
    if self.popId then
        local pop = ConfigRefer.PopUpWindow:Find(self.popId)
        self.groupId = pop:PayGroup()
    end
    self.root:SetActive(self.popId ~= nil and ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(self.groupId))
end

return HUDActivityFirstRecharge