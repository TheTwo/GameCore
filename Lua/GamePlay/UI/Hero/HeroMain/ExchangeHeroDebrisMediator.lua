local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local ConfigRefer = require("ConfigRefer")
local Utils = require('Utils')
local I18N = require('I18N')

local ExchangeHeroDebrisMediator = class('ExchangeHeroDebrisMediator', BaseUIMediator)

function ExchangeHeroDebrisMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaObject('child_popup_base_m')
    self.goHint = self:GameObject("base_hint")
    self.textHint = self:Text('p_text_debris')
    self.compChildCommonQuantity = self:LuaObject('child_common_quantity')
    self.compChildItemCommon = self:LuaObject('child_item_common')
    self.textQuantityCommon = self:Text('p_text_quantity_common')
    self.compChildItemHero = self:LuaObject('child_item_hero')
    self.textQuantityHero = self:Text('p_text_quantity_hero')
    self.textInputQuantity = self:Text('p_text_input_quantity')
    self.inputfieldInputQuantity = self:InputField('p_Input_quantity', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.compChildSetBar = self:LuaObject('child_set_bar')
    self.textCancelLb = self:Text('p_btn_cancel_lb', I18N.Get("hero_piece_exchange_cancel"))
    self.compConfirmA = self:LuaObject('p_btn_confirm_a')
end

function ExchangeHeroDebrisMediator:OnClickExchangeBtn()
    local parameter = ExchangeMultiItemParameter.new()
    parameter.args.TargetItemConfigId:Add(self.heroPieceId)
    parameter.args.TargetItemCount:Add(tonumber(self.textQuantityHero.text))
    parameter:Send()
    g_Game.UIManager:Close(self.runtimeId)
end

function ExchangeHeroDebrisMediator:OnEndEdit(inputText)
    local inputNum = tonumber(inputText)
    local heroPieceCfg = ConfigRefer.Item:Find(self.heroPieceId)
    local getMoreCfg = ConfigRefer.GetMore:Find(heroPieceCfg:GetMoreConfig())
    local costItemId = getMoreCfg:Exchange():Currency()
    local commonNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
    if not inputNum or inputNum < 1 then
        inputNum =  math.min(1, commonNum)
    end
    if inputNum > self.maxNum then
        inputNum = self.maxNum
    end
    self.inputfieldInputQuantity.text = inputNum
    self.compChildSetBar:OutInputChangeSliderValue(inputNum)
    local costNum = getMoreCfg:Exchange():CurrencyCount()
    local exchangeNum = getMoreCfg:Exchange():Count()
    self.textQuantityCommon.text = "-" .. costNum * inputNum
    self.textQuantityHero.text = "+" .. exchangeNum * inputNum
    self:RefreshPieceNums()
end

function ExchangeHeroDebrisMediator:OnOpened(params)
    local curHero = params.curHero
    local strengthLv = curHero.dbData.StarLevel + 1
    local strengthenConfig = ConfigRefer.HeroStrengthen:Find(curHero.configCell:StrengthenCfg())
    local info = strengthenConfig:StrengthenInfoList(strengthLv)
    local itemGroupId = info:CostItemGroupCfgId()
    local itemGroup = ConfigRefer.ItemGroup:Find(itemGroupId)
    local itemInfo = itemGroup:ItemGroupInfoList(1)
    self.heroPieceId = itemInfo:Items()
    self.needNums = itemInfo:Nums()
    self.compChildPopupBaseM:FeedData({title = I18N.Get("hero_piece_exchange")})
    local exchangeButton = {}
    exchangeButton.buttonText =  I18N.Get("hero_piece_exchange_confirm")
    exchangeButton.disabledButtonText = I18N.Get("hero_piece_exchange_confirm")
    exchangeButton.onClick = Delegate.GetOrCreate(self, self.OnClickExchangeBtn)
    self.compConfirmA:FeedData(exchangeButton)


    local heroPieceCfg = ConfigRefer.Item:Find(self.heroPieceId)
    local getMoreCfg = ConfigRefer.GetMore:Find(heroPieceCfg:GetMoreConfig())
    local costItemId = getMoreCfg:Exchange():Currency()
    local costNum = getMoreCfg:Exchange():CurrencyCount()
    local exchangeNum = getMoreCfg:Exchange():Count()
    if exchangeNum <= 0 then
        exchangeNum = 1
    end
    local costCfg = ConfigRefer.Item:Find(costItemId)
    local commonNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)

    self.compConfirmA:SetEnabled(commonNum > 0)

    self.compChildItemCommon:FeedData({configCell = costCfg, count = commonNum, showTips = true})
    self.compChildItemHero:FeedData({configCell = heroPieceCfg, showCount = false, showTips = true})
    self.maxNum = commonNum
    local setBarData = {}
    setBarData.minNum = math.min(1, commonNum)
    setBarData.maxNum = commonNum
    setBarData.oneStepNum = costNum
    setBarData.curNum = setBarData.minNum
    setBarData.intervalTime = 0.1
    setBarData.callBack = function(value)
        self:OnEndEdit(value)
    end
    self.compChildSetBar:FeedData(setBarData)
    self.inputfieldInputQuantity.text = math.min(1, commonNum)
    self.textQuantityCommon.text = "-" .. costNum * setBarData.curNum
    self.textQuantityHero.text = "+" .. exchangeNum * setBarData.curNum
    self.textInputQuantity.text = "/" .. self.maxNum
    self:RefreshPieceNums()
end

function ExchangeHeroDebrisMediator:RefreshPieceNums()
    local heroPieceNum = ModuleRefer.InventoryModule:GetAmountByConfigId(self.heroPieceId)
    local lackPiece = self.needNums - heroPieceNum
    if lackPiece <= 0 then
        self.textHint.gameObject:SetActive(false)
        self.compChildCommonQuantity:FeedData({compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST, itemId = self.heroPieceId, num1 = heroPieceNum, num2 = self.needNums})
    else
        self.textHint.gameObject:SetActive(true)
        local curNum = self.compChildSetBar.curNum
        local maxNum = self.compChildSetBar.maxNum
        if curNum == maxNum and ((maxNum + heroPieceNum) < self.needNums) then
            self.compChildCommonQuantity:FeedData({compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST, itemId = self.heroPieceId, num1 = maxNum + heroPieceNum, num2 = self.needNums})
            self.textHint.text = I18N.GetWithParams("hero_strengthen_piece_exchange_notenough_2", self.needNums - (maxNum + heroPieceNum))
        else
            local totalNum = curNum + heroPieceNum
            if totalNum >= self.needNums then
                self.compChildCommonQuantity:FeedData({compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST, itemId = self.heroPieceId, num1 = totalNum, num2 = self.needNums})
                self.textHint.text = I18N.Get("hero_strengthen_piece_exchange_enough")
            else
                self.compChildCommonQuantity:FeedData({compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST, itemId = self.heroPieceId, num1 = totalNum, num2 = self.needNums})
                self.textHint.text = I18N.GetWithParams("hero_strengthen_piece_exchange_notenough_1", self.needNums - totalNum)
            end
        end
    end

end

function ExchangeHeroDebrisMediator:OnClose()

end

return ExchangeHeroDebrisMediator
