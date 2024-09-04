local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local NumberFormatter = require('NumberFormatter')
local UIHelper = require('UIHelper')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local ItemType = require('ItemType')
local EventConst = require('EventConst')

local HudResourceCoinItemCell = class('HudResourceCoinItemCell',BaseTableViewProCell)

function HudResourceCoinItemCell:OnCreate()
    self.coinIcon = self:Image('p_icon')
    self.textName = self:Text('p_text_name')
    self.textQuantity = self:Text('p_text_quantity')
    self.btnGetMore = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnGetMoreClicked))
    self.btnUse = self:Button('p_comp_btn_use', Delegate.GetOrCreate(self, self.OnUseClick))
    self.textUse = self:Text('p_text_use')
end

function HudResourceCoinItemCell:OnClose()
end

---@param currencyInfoCell CurrencyInfoConfigCell
function HudResourceCoinItemCell:OnFeedData(currencyInfoCell)
    self.currencyInfoCell = currencyInfoCell
    -- 图标
    self.itemCell = ConfigRefer.Item:Find(self.currencyInfoCell:RelItem())
    local icon = UIHelper.GetFitItemIcon(self.coinIcon, self.itemCell)
    g_Game.SpriteManager:LoadSprite(icon, self.coinIcon)

    -- 名字
    self.textName.text = g_Game.LocalizationManager:Get(self.itemCell:NameKey())

    -- 数量
    local count = ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemCell:Id())
    self.textQuantity.text = NumberFormatter.Normal(count)

    -- 使用按钮显示
    self.textUse.text = g_Game.LocalizationManager:Get(self.currencyInfoCell:UseText())

    -- 货币类型，没有配置跳转，则隐藏GetMore
    local hideGetMore = self.itemCell:Type() == ItemType.Currency and string.IsNullOrEmpty(self.currencyInfoCell:GetGoto())
    self.btnGetMore:SetVisible(not hideGetMore)
end

function HudResourceCoinItemCell:CloseTips()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_CLOSE_COIN_TIPS)
end

function HudResourceCoinItemCell:OnGetMoreClicked()
    self:CloseTips()

    local gotoParam = self.currencyInfoCell:GetGoto()
    -- 打开配置的获取页面
    if not string.IsNullOrEmpty(gotoParam) then
        local params = string.split(gotoParam, '@')
        local targetUI = gotoParam
        if #params == 2 then
            -- 打开指定UI的指定tab页
            targetUI = params[1]
            local uiParam = params[2]
            g_Game.UIManager:Open(targetUI, uiParam)
        else
            g_Game.UIManager:Open(targetUI)
        end

        return
    end

    if self.itemCell:Type() == ItemType.Currency then
        g_Logger.Log('货币类型, 没有配置GetMore逻辑')
        return
    end

    -- 非货币道具，没有配置跳转，打开通用的GetMore页面
    local param = {}
    param.id = self.itemCell:Id()
    param.num = 0
    ModuleRefer.InventoryModule:OpenExchangePanel(param)
end

function HudResourceCoinItemCell:OnUseClick()
    self:CloseTips()

    local useParam = self.currencyInfoCell:UseGoto()
    if not string.IsNullOrEmpty(useParam) then
        local params = string.split(useParam, '@')
        local targetUI = useParam
        if #params == 2 then
            -- 打开指定UI的指定tab页
            targetUI = params[1]
            local tabIndex = tonumber(params[2])
            local uiParam = {}
            uiParam.tabIndex = tabIndex
            g_Game.UIManager:Open(targetUI, uiParam)
        else
            g_Game.UIManager:Open(targetUI)
        end

        return
    end

    g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator)
end

return HudResourceCoinItemCell
