local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local TradeCostItemCell = class('TradeCostItemCell',BaseTableViewProCell)

function TradeCostItemCell:OnCreate()
    self.btnItem = self:Button("", Delegate.GetOrCreate(self, self.OnBtnItemClicked))
    self.goImgSelect = self:GameObject('p_img_select')
    self.imgIconItem = self:Image('p_icon_item')
    self.sliderProgressQuantity = self:Slider('p_progress_quantity')
    self.textHint = self:Text('p_text_hint')
    self.goIconFinish = self:GameObject('p_icon_finish')
    self.goIconArrow = self:GameObject('p_icon_arrow')
    self.textQuantity = self:Text('p_text_quantity', I18N.Get("npc_give_item_own"))
    self.textNum = self:Text('p_text_num')
end

function TradeCostItemCell:Select()
    self.goImgSelect:SetActive(true)
    self.goIconArrow:SetActive(true)
end

function TradeCostItemCell:UnSelect()
    self.goImgSelect:SetActive(false)
    self.goIconArrow:SetActive(false)
end

function TradeCostItemCell:OnFeedData(itemId)
    local storyPopupTradeMediator = self:GetParentBaseUIMediator()
    local curItemInfos = storyPopupTradeMediator:GetServicesInfo()
    local submitCount = curItemInfos[itemId] or 0
    local needCount = storyPopupTradeMediator:GetNeedCount(itemId)
    self.itemId = itemId
    local itemData = ConfigRefer.Item:Find(itemId)
    g_Game.SpriteManager:LoadSprite(itemData:Icon(),self.imgIconItem)
    local isSubmitAll = submitCount >= needCount
    self.sliderProgressQuantity.gameObject:SetActive(not isSubmitAll)
    self.goIconFinish:SetActive(isSubmitAll)
    if not isSubmitAll then
        self.sliderProgressQuantity.value = submitCount / needCount
        self.textHint.text = submitCount .. "/" .. needCount
    end
    local haveNum = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
    self.textNum.text = haveNum
end

function TradeCostItemCell:OnBtnItemClicked()
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_TRADE_COST_CELL, self.itemId)
end

return TradeCostItemCell
