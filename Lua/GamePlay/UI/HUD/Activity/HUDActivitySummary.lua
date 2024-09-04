local BaseUIComponent = require('BaseUIComponent')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local DBEntityPath = require('DBEntityPath')
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local TimeFormatter = require('TimeFormatter')
---@class HUDActivitySummary : BaseUIComponent
local HUDActivitySummary = class('HUDActivitySummary', BaseUIComponent)

function HUDActivitySummary:ctor()
    self.popIds = {}
    self.startTimer = false
    self.openPopId = nil
end

function HUDActivitySummary:OnCreate()
    self.goRoot = self:GameObject('')
    self.textTime = self:Text('p_text_time')
    self.goTipsFade = self:GameObject('tips_fade')
    self.textFade = self:Text('p_text_fade')
    self.goNum = self:GameObject('p_base_num')
    self.textNum = self:Text('p_text_num')
    self.imgBanner = self:Image('p_img_gift_banner')
    self.btn = self:Button('p_btn_popup_summary', Delegate.GetOrCreate(self, self.OnClick))
end

function HUDActivitySummary:OnShow()
    self:Init()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.Init))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function HUDActivitySummary:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.Init))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function HUDActivitySummary:Init()
    self.popIds = {}
    local popIds = ModuleRefer.LoginPopupModule:GetPopIdsByMediatorName(UIMediatorNames.UIFirstRechargeMediator, false, true)
    for _, id in ipairs(popIds) do
        local pop = ConfigRefer.PopUpWindow:Find(id)
        local groupId = pop:PayGroup()
        local isGroupAvaliable = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
        if isGroupAvaliable then
            table.insert(self.popIds, id)
        end
    end
    local isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Global_pop_windows)
    local hasPops = (self.popIds and #self.popIds > 0)
    self.goRoot:SetActive(hasPops)
    if not self.popIds or #self.popIds <= 0 then
        return
    end
    local packNum = #self.popIds
    local showPack, time = self:GetShowPack()
    if not showPack then
        return
    end
    local icon = showPack:PopUpIcon()
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(icon), self.imgBanner)
    self.goNum:SetActive(packNum > 1)
    self.textNum.text = I18N.Get(string.format('%d', packNum))
    if not time or time <= 0 or time == math.huge then
        self.textTime.gameObject:SetActive(false)
        self.startTimer = false
    else
        self.textTime.gameObject:SetActive(true)
        self.textTime.text = TimeFormatter.SimpleFormatTime(time)
        self.startTimer = true
    end
end

function HUDActivitySummary:OnSecondTick()
    if not self.startTimer then
        return
    end
    local showPack, time = self:GetShowPack()
    if not showPack then
        return
    end
    if not time or time <= 0 or time == math.huge then
        self.textTime.gameObject:SetActive(false)
        self.startTimer = false
    else
        self.textTime.text = TimeFormatter.SimpleFormatTime(time)
    end
end

function HUDActivitySummary:GetShowPack()
    local minReTime = math.huge
    local showPack = nil
    for i, popId in ipairs(self.popIds) do
        local pop = ConfigRefer.PopUpWindow:Find(popId)
        if not pop then
            goto continue
        end
        local payGroup = ConfigRefer.PayGoodsGroup:Find(pop:PayGroup())
        local pack = ConfigRefer.PayGoods:Find(payGroup:Goods(1))
        local reTime = ModuleRefer.ActivityShopModule:GetRemainingTime(payGroup:Id())
        if i == 1 then
            showPack = pack
            self.openPopId = popId
        end
        if reTime <= 0 then reTime = math.huge end
        if reTime < minReTime then
            minReTime = reTime
            showPack = pack
            self.openPopId = popId
        end
        ::continue::
    end
    return showPack, minReTime
end

function HUDActivitySummary:OnClick()
    g_Game.UIManager:Open(UIMediatorNames.UIFirstRechargeMediator, {
        isFromHud = true,
        openPopId = self.openPopId,
    })
end

return HUDActivitySummary