local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ProtocolId = require('ProtocolId')
local GetForbidSwitchParameter = require('GetForbidSwitchParameter')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
---@class ActivityShopPurchaseGems : BaseUIComponent
local ActivityShopPurchaseGems = class('ActivityShopPurchaseGems', BaseUIComponent)

function ActivityShopPurchaseGems:OnCreate()
    self.textTitlePay1 = self:Text('p_title_pay_1')
    self.textTitlePay2 = self:Text('p_title_pay_2')
    self.tableviewproTablePay = self:TableViewPro('p_table_pay')
    self.textHintPay = self:Text('p_text_hint_pay')
    self.firstPayStateOfCells = {}
end

function ActivityShopPurchaseGems:OnFeedData(param)
    local getForbidSwitchParam = GetForbidSwitchParameter.new()
    getForbidSwitchParam.args.ActivityId = ConfigRefer.ConstMain:PayActivity()
    getForbidSwitchParam:Send()
    self.packGroups = param.openedPackGroups
    self:InitGoodsId()
    self:RefreshAllPanel()
end

function ActivityShopPurchaseGems:InitGoodsId()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local productId2Times = player.PlayerWrapper2.PlayerPay.ProductId2Times
    self.goodsId = {}
    for _, groupId in ipairs(self.packGroups) do
        local goodId = ConfigRefer.PayGoodsGroup:Find(groupId):Goods(1)
        local v = ConfigRefer.PayGoods:Find(goodId)
        self.goodsId[#self.goodsId + 1] = {id = v:Id(), sort = v:Sort()}
        self.firstPayStateOfCells[v:Id()] = (not productId2Times[v:Id()] or productId2Times[v:Id()] <= 0)
    end
    table.sort(self.goodsId, function(a, b)
        if a.sort ~= b.sort then
            return a.sort < b.sort
        else
            return a.id < b.id
        end
    end)
end

function ActivityShopPurchaseGems:RefreshAllPanel()
    self:RefreshHintText()
    self:RefreshFirstChargeHint()
    self:RefreshGoodsCell()
end

function ActivityShopPurchaseGems:RefreshHintText()
    if self.isforbid then
        self.textHintPay.text = I18N.Get("top_up_disable_desc_txt")
    else
        local player = ModuleRefer.PlayerModule:GetPlayer()
        local payNumber = player.PlayerWrapper2.PlayerPay.AccPay or 0
        self.textHintPay.text = I18N.GetWithParams("top_up_limit_txt", string.format("%.2f", ConfigRefer.ConstMain:PayMaxNumber()), string.format("%.2f", payNumber))
    end
end

function ActivityShopPurchaseGems:RefreshFirstChargeHint()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local productId2Times = player.PlayerWrapper2.PlayerPay.ProductId2Times
    local isHasZeroTime = false
    for _, v in ipairs(self.goodsId) do
        if not productId2Times[v.id] then
            isHasZeroTime = true
            break
        end
        if productId2Times[v.id] <= 0 then
            isHasZeroTime = true
            break
        end
    end
    if isHasZeroTime then
        self.textTitlePay1.text = I18N.Get("top_up_store_slogan_txt_1_1")
        self.textTitlePay2.text = I18N.Get("top_up_store_slogan_txt_1_2")
    else
        self.textTitlePay1.text = I18N.Get("top_up_store_slogan_txt_2_1")
        self.textTitlePay2.text = I18N.Get("top_up_store_slogan_txt_2_2")
    end
end

function ActivityShopPurchaseGems:RefreshGoodsCell()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local productId2Times = player.PlayerWrapper2.PlayerPay.ProductId2Times
    self.tableviewproTablePay:Clear()
    for _, v in ipairs(self.goodsId) do
        local isFirstPay = (not productId2Times[v.id] or productId2Times[v.id] <= 0)
        local shouldPlayAnim = (isFirstPay ~= self.firstPayStateOfCells[v.id])
        self.firstPayStateOfCells[v.id] = isFirstPay
        self.tableviewproTablePay:AppendData({goodId = v.id, isforbid = self.isforbid, shouldPlayAnim = shouldPlayAnim})
    end
end

function ActivityShopPurchaseGems:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.RefreshAllPanel))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.GetForbidSwitch, Delegate.GetOrCreate(self, self.RefreshState))
end

function ActivityShopPurchaseGems:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.RefreshAllPanel))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.GetForbidSwitch, Delegate.GetOrCreate(self, self.RefreshState))
end

function ActivityShopPurchaseGems:RefreshState(isSuccess, reply, rpc)
    if not isSuccess then return end
    self.isforbid = reply.Forbid
end

return ActivityShopPurchaseGems
