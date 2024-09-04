local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local SliderItemCell = class('SliderItemCell',BaseTableViewProCell)

function SliderItemCell:OnCreate(param)
    self.textWay = self:Text('p_text_way', I18N.Get("getmore_text_03"))
    ---@type BistateButton
    self.compChildCompBS = self:LuaObject('child_comp_btn_b_s')
    self.compChildSetBar = self:LuaBaseComponent('child_set_bar')
    self.inputfieldInputQuantity = self:InputField('p_Input_quantity', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.textInput = self:Text('p_text_input')
    self.textNumBuy = self:Text('p_text_num_buy')
    self.imgIconResource = self:Image('p_icon_resource_buy')

end

function SliderItemCell:OnFeedData(data)
    if not data then
        return
    end
    self.itemId = data.itemId

    local itemCfg = ConfigRefer.Item:Find(self.itemId)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    local costItemId = getMoreCfg:Exchange():Currency()
    self.costNum = getMoreCfg:Exchange():CurrencyCount()
    self.exchangeNum = getMoreCfg:Exchange():Count()
    local curMoneyNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
    self.maxNum = math.floor(curMoneyNum / self.costNum) * self.exchangeNum
    local costCfg = ConfigRefer.Item:Find(costItemId)
    g_Game.SpriteManager:LoadSprite(costCfg:Icon(), self.imgIconResource)
    local upButton = {}
    upButton.buttonText = self.costNum
    upButton.disableClick = Delegate.GetOrCreate(self, self.OnClickDisableBtn)
    upButton.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)

    self.compChildCompBS:FeedData(upButton)
    self.compChildCompBS:SetEnabled(self.maxNum > 0)
    if self.maxNum == 0 then
        self.maxNum = self.exchangeNum
    end
    local setBarData = {}
    setBarData.minNum = self.exchangeNum
    setBarData.maxNum = self.maxNum
    setBarData.oneStepNum = self.exchangeNum
    setBarData.curNum = self.exchangeNum
    setBarData.intervalTime = 0.1
    setBarData.callBack = function(value)
        self:OnEndEdit(value)
    end
    self.compChildSetBar:FeedData(setBarData)
    self.textInput.text = self.exchangeNum
    self.inputfieldInputQuantity.text = self.exchangeNum
    self.textNumBuy.text = self.costNum
end

function SliderItemCell:OnEndEdit(inputText)
    local inputNum = tonumber(inputText)
    if not inputNum or inputNum < self.exchangeNum then
        inputNum = self.exchangeNum
    end
    if inputNum > self.maxNum then
        inputNum = self.maxNum
    end
    inputNum = math.floor(inputNum / self.exchangeNum) * self.exchangeNum
    self.textInput.text = inputNum
    self.inputfieldInputQuantity.text = inputNum
    self.compChildSetBar.Lua:OutInputChangeSliderValue(inputNum)
    self.textNumBuy.text = math.tointeger((inputNum / self.exchangeNum) * self.costNum)
end

function SliderItemCell:OnClickDisableBtn()

end

function SliderItemCell:OnClickBtn()
    local parameter = ExchangeMultiItemParameter.new()
    parameter.args.TargetItemConfigId:Add(self.itemId)
    parameter.args.TargetItemCount:Add(tonumber(self.textInput.text))
    parameter:Send()
    g_Game.UIManager:CloseByName("ExchangeResourceMediator")
end

return SliderItemCell
