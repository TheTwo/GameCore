---sence: scene_activity_popup_first_charge
local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
---@class FirstRechargePopUpMediator : BaseUIMediator
local FirstRechargePopUpMediator = class("FirstRechargePopUpMediator", BaseUIMediator)

---@class FirstRechargePopUpMediatorParam
---@field isFromHud boolean
---@field popIds number[]

function FirstRechargePopUpMediator:ctor()
end

function FirstRechargePopUpMediator:OnCreate()
    ---@see ActivityHeroPackFirstRecharge
    self.luaActivityPack = self:LuaObject("child_shop_activity")
end

---@param param FirstRechargePopUpMediatorParam
function FirstRechargePopUpMediator:OnOpened(param)
    self.isFromHud = (param or {}).isFromHud
    self.popIds = (param or {}).popIds
    self:UpdateContent()
end

function FirstRechargePopUpMediator:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnPayGroupChange))
end

function FirstRechargePopUpMediator:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnPayGroupChange))
end

function FirstRechargePopUpMediator:OnClose()
    if not self.isFromHud and self.popIds then
        ModuleRefer.LoginPopupModule:OnPopupShown(self.popIds)
    end
end

function FirstRechargePopUpMediator:OnPayGroupChange()
    local popId = self.popIds[1]
    local pop = ConfigRefer.PopUpWindow:Find(popId)
    if not pop then return end
    local groupId = pop:PayGroup()
    local isGroupAvaliable = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
    if not isGroupAvaliable then
        self:CloseSelf()
    else
        self:UpdateContent()
    end
end

function FirstRechargePopUpMediator:UpdateContent()
    ---@type PopUpTabCellParam
    local data = {}
    data.popId = self.popIds[1]
    data.isShop = false
    self.luaActivityPack:FeedData(data)
end

return FirstRechargePopUpMediator