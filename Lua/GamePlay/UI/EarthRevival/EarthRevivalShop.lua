local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require("ModuleRefer")
local TimerUtility = require('TimerUtility')
local TimeFormatter = require('TimeFormatter')
local ConfigRefer = require('ConfigRefer')
local ConfigTimeUtility = require("ConfigTimeUtility")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")

---@class EarthRevivalShop : BaseUIComponent
local EarthRevivalShop = class('EarthRevivalShop', BaseUIComponent)

---@class EarthRevivalShopData
---@field shopId number

function EarthRevivalShop:ctor()
end

function EarthRevivalShop:OnCreate()
    self.table = self:TableViewPro('p_table')
    self.p_text_cd = self:Text('p_text_cd','shop_refreshtime')
    self.p_text_ad_time = self:Text('p_text_ad_time')
end

function EarthRevivalShop:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Store.MsgPath, Delegate.GetOrCreate(self, self.UpdateStore))
end

function EarthRevivalShop:OnHide()
    self:StopTimer()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Store.MsgPath, Delegate.GetOrCreate(self, self.UpdateStore))
end

---@param data EarthRevivalShopData
function EarthRevivalShop:OnFeedData(data)
    self.shopId = data.shopId
    self:UpdateStore()
    local shop = ConfigRefer.Shop:Find(self.shopId)
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    local openSystemTimes = kingdom.SystemEntry.OpenSystemTime
    local time = openSystemTimes[shop:SystemSwitch()]
    if time then
        local startT = time.Seconds
        local duration = ConfigTimeUtility.NsToSeconds(shop:OpenDuration())
        self.endT = startT + duration

        self:SetCountDown()
        self:SetCountDownTimer()
    else
        self.p_text_cd:SetVisible(false)
        self.p_text_ad_time:SetVisible(false)
    end
end

function EarthRevivalShop:UpdateStore()
    self.table:Clear()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local storeInfos = player.PlayerWrapper.Store.Stores or {}
    local products = storeInfos[self.shopId].Products
    local freeProducts = storeInfos[self.shopId].FreeProducts
    local showIds = {}
    for itemId, _ in pairs(products) do
        showIds[#showIds + 1] = {id = itemId, isFree = freeProducts[itemId] ~= nil}
    end
    table.sort(showIds, function(a, b)
        if a.isFree ~= b.isFree then
            return a.isFree
        else
            return a.id < b.id
        end
    end)
    for _, item in ipairs(showIds) do
        local isFree = item.isFree
        local buyNum = products[item.id]
        if isFree then
            buyNum = freeProducts[item.id]
            if buyNum >= 2 then
                isFree = false
                buyNum = products[item.id]
            end
        end
        self.table:AppendData({isFree = isFree , commodityId = item.id, buyNum = buyNum, tabId = self.shopId})
    end
end

function EarthRevivalShop:SetCountDown()
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local seconds = self.endT - curT
    if seconds > 0 then
        self.p_text_cd:SetVisible(true)
        self.p_text_ad_time:SetVisible(true)
        self.p_text_ad_time.text = TimeFormatter.SimpleFormatTimeWithDay(seconds)
    else
        self.p_text_cd:SetVisible(false)
        self.p_text_ad_time:SetVisible(false)
        self:StopTimer()
    end
end

function EarthRevivalShop:SetCountDownTimer()
    if not self.countdownTimer then
        self.countdownTimer = TimerUtility.IntervalRepeat(function()
            self:SetCountDown()
        end, 1, -1, true)
    end
end

function EarthRevivalShop:StopTimer()
    if self.countdownTimer then
        TimerUtility.StopAndRecycle(self.countdownTimer)
        self.countdownTimer = nil
    end
end

return EarthRevivalShop