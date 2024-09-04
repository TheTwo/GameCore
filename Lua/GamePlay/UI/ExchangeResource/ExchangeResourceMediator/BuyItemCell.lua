local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local BuyItemCell = class('BuyItemCell',BaseTableViewProCell)

function BuyItemCell:OnCreate(param)
    self.textWay = self:Text('p_text_way', I18N.Get("getmore_text_03"))
    self.textNum = self:Text('p_text_num')
    self.compChildCompBS = self:LuaObject('child_comp_btn_b_s')
    self.imgIcon = self:Image('p_icon_resource')
end

function BuyItemCell:OnFeedData(data)
    self.data = data
    local costItemId = data.costItem
    local totalCost = math.tointeger(data.totalCost)
    local upButton = {}
    upButton.buttonText = totalCost
    upButton.disableClick = Delegate.GetOrCreate(self, self.OnClickDisableBtn)
    upButton.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)

    self.compChildCompBS:FeedData(upButton)
    local isEnough = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId) >= totalCost
    self.compChildCompBS:SetEnabled(isEnough)
    self.textNum.text = totalCost
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(costItemId):Icon(), self.imgIcon)
end

function BuyItemCell:OnClickBtn()
    local parameter = ExchangeMultiItemParameter.new()
    parameter.args.TargetItemConfigId:Add(self.data.itemId)
    parameter.args.TargetItemCount:Add(self.data.exchangeNum)
    parameter:Send()
end

function BuyItemCell:OnClickDisableBtn()

end

return BuyItemCell
