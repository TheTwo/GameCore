---@sceneName:scene_getmore_popup_resources_use
local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local TimerUtility = require('TimerUtility')
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require('ModuleRefer')
---@class UseResourceMediator:BaseUIMediator
local UseResourceMediator = class('UseResourceMediator', BaseUIMediator)

function UseResourceMediator:ctor()
    self.tick = false
    self.useOrPayCellDatas = {}
end

function UseResourceMediator:OnCreate()
    self.goProgressbar = self:GameObject('p_progressbar')
    self.compChildPopupBaseM = self:LuaObject('child_popup_base_m')

    self.sliderProgress = self:Slider('p_progress')
    self.textTime = self:Text('p_text_time')
    self.btnPay = self:Button('p_btn_buy', Delegate.GetOrCreate(self, self.OnBtnPayClicked))
    self.textBtnPay = self:Text('p_text_buy')
    self.textBuyNum = self:Text('p_text_buy_num')
    self.imgIconBuy = self:Image('p_icon_buy')

    self.btnBase = self:Button('p_btn_base', Delegate.GetOrCreate(self, self.OnBtnBaseClicked))
    self.imgBase = self:Image('p_icon_base')

    self.tableviewproTable = self:TableViewPro('p_table')

    self.rectContent = self:RectTransform('ui_common_content')
end

---@param param BaseGetMoreDataProvider
function UseResourceMediator:OnShow(param)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.rectContent)
    self.provider = param
    self:UpdateUI()
    for _, itemId in ipairs(self.items) do
        ModuleRefer.InventoryModule:AddCountChangeListener(itemId, Delegate.GetOrCreate(self, self.RefreshItems))
    end

    g_Game.ServiceManager:AddResponseCallback(require("UseItemParameter").GetMsgId(), Delegate.GetOrCreate(self, self.UpdateUI))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

function UseResourceMediator:OnHide(param)
    local holder = self.provider:GetHolder()
    if holder then
        holder:OnMediatorHide(self)
    end
    self:ClearTimer()
    for _, itemId in ipairs(self.items) do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(itemId, Delegate.GetOrCreate(self, self.RefreshItems))
    end

    g_Game.ServiceManager:RemoveResponseCallback(require("UseItemParameter").GetMsgId(), Delegate.GetOrCreate(self, self.UpdateUI))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

function UseResourceMediator:OnSecTick()
    if not self.tick then return end
    self:SetupPayBtn()
    for _, data in ipairs(self.cellDatas) do
        if data.provider:ShowBubble() or data.provider:ShouldTickUpdate() then
            self.tableviewproTable:UpdateChild(data)
        end
    end
end

function UseResourceMediator:UpdateUI()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.rectContent)

    self.compChildPopupBaseM:FeedData({title = self.provider:GetTitle()})

    self.goProgressbar:SetActive(self.provider:ShowProgress())

    self.items = self.provider:GetItemList()
    self:RefreshItems()

    local holder = self.provider:GetHolder()
    if holder then
        self.tick = true
        holder:OnMediatorShow(self)
        self.btnPay.gameObject:SetActive(true)
        self:SetupPayBtn()
    else
        self.btnPay.gameObject:SetActive(false)
        self.sliderProgress.value = self.provider:GetProgress()
        self.textTime.text = self.provider:GetProgressStr()
    end
end

function UseResourceMediator:SetupPayBtn()
    local holder = self.provider:GetHolder()
    self.textBtnPay.text = holder:GetPayButtonText()
    local currencyId = 2 -- 等待getmore配置
    local currencyCfg = ConfigRefer.Item:Find(currencyId)
    g_Game.SpriteManager:LoadSprite(currencyCfg:Icon(), self.imgIconBuy)
    local remainTime = holder:GetRemainTime()
    local cost = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
    self.textBuyNum.text = ("%d"):format(cost)
end

function UseResourceMediator:RefreshItems()
    self.cellDatas = self.provider:GetCellDatas()
    self.tableviewproTable:Clear()
    for _, data in ipairs(self.cellDatas) do
        if data.cellType == 2 then -- 偷个懒，titleCell不写provider了
            self.tableviewproTable:AppendData(data, data.cellType)
        else
            self.tableviewproTable:AppendData(data.provider, data.cellType)
        end
    end
end

function UseResourceMediator:ClearTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function UseResourceMediator:OnBtnPayClicked()
    self.provider:OnPay(self.btnPay.transform)
end

return UseResourceMediator