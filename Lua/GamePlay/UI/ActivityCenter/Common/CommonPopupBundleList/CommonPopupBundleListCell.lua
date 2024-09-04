local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
---@class CommonPopupBundleListCell : BaseTableViewProCell
local CommonPopupBundleListCell = class("CommonPopupBundleListCell", BaseTableViewProCell)

function CommonPopupBundleListCell:ctor()
end

function CommonPopupBundleListCell:OnCreate()
    self.p_text_name = self:Text("p_text_name")
    self.p_table_reward = self:TableViewPro("p_table_reward")

    ---@type BistateButton
    self.p_btn_free = self:LuaObject("p_btn_free")

    self.p_btn_buy = self:Button("p_btn_buy", Delegate.GetOrCreate(self, self.OnBtnBuyClick))
    self.p_text_e = self:Text("p_text_e")

    ---@type NotificationNode
    self.child_reddot_default = self:LuaObject("child_reddot_default")

    ---@type CommonDiscountTag
    self.child_shop_discount_tag = self:LuaObject("child_shop_discount_tag")

    self.p_sold_out = self:GameObject("p_sold_out")
    self.p_text_sold_out = self:Text("p_text_sold_out", "general_sold_out_txt")

    self.p_resouce_e = self:GameObject("p_resouce_e")
    self.p_icon_e = self:Image("p_icon_e")
    self.p_text_num_green_e = self:Text("p_text_num_green_e")
    self.p_text_num_red_e = self:Text("p_text_num_red_e")
    self.p_text_num_e = self:Text("p_text_num_e")
end

---@param parameter BasePopupBundleListCellParameter
function CommonPopupBundleListCell:OnFeedData(parameter)
    self.parameter = parameter
    self.p_text_name.text = parameter:GetName()

    self.p_table_reward:Clear()
    for _, reward in ipairs(parameter:GetRewards()) do
        self.p_table_reward:AppendData(reward)
    end

    self.p_btn_free:SetVisible(parameter:CanShowFreeBtn())
    self.p_btn_buy.gameObject:SetActive(not parameter:IsSoldOut() and not parameter:CanShowFreeBtn())

    if parameter:CanShowFreeBtn() then
        ---@type BistateButtonParameter
        local data = {}
        data.buttonText = parameter:GetFreeButtonEnableText()
        data.disableButtonText = parameter:GetFreeButtonDisableText()

        data.onClick = function ()
            parameter:OnFreeButtonClick()
        end

        data.disableClick = function ()
            parameter:OnFreeButtonDisableClick()
        end

        self.p_btn_free:OnFeedData(data)

        self.p_btn_free:SetEnabled(parameter:IsFreeButtonEnable())
    else
        self.p_text_e.text = parameter:GetPurchaseButtonText()
        local icon, need, have = parameter:GetPurchaseButtonItemInfo()
        self.p_resouce_e:SetActive(icon ~= nil)
        if icon then
            g_Game.SpriteManager:LoadSprite(icon, self.p_icon_e)
            self.p_text_num_e.text = need
        end
    end

    local notificationNode = parameter:GetNotificationNode()
    if notificationNode then
        ModuleRefer.NotificationModule:AttachToGameObject(notificationNode, self.child_reddot_default.go, self.child_reddot_default.redNew)
    else
        self.child_reddot_default:SetVisible(false)
    end

    self.p_sold_out:SetActive(parameter:IsSoldOut())
end

function CommonPopupBundleListCell:OnBtnBuyClick()
    self.parameter:OnClickPurchaseButton()
end

return CommonPopupBundleListCell