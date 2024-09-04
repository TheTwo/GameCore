local GetMoreSupplyCellDataProvider = require("GetMoreSupplyCellDataProvider")
local ExchangeResourceStatic = require("ExchangeResourceStatic")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local ClientDataKeys = require("ClientDataKeys")
local ConfigTimeUtility = require("ConfigTimeUtility")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
---@class CitySpeedUpGetMoreSupplyCellDataProvider : GetMoreSupplyCellDataProvider
local CitySpeedUpGetMoreSupplyCellDataProvider = class("CitySpeedUpGetMoreSupplyCellDataProvider", GetMoreSupplyCellDataProvider)

function CitySpeedUpGetMoreSupplyCellDataProvider:ctor()
    CitySpeedUpGetMoreSupplyCellDataProvider.super.ctor(self)
    self.itemList = {}
    self.itemData = {}
end

function CitySpeedUpGetMoreSupplyCellDataProvider:SetItemList(itemList)
    Utils.CopyArray(itemList, self.items)
    self.itemList = {}
    for _, itemId in ipairs(self.items) do
        local isHave = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId) > 0
        self.itemList[#self.itemList + 1] = {itemId = itemId, isHave = isHave, time = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemId):SpeedTime()}
    end

    table.sort(self.itemList, function(a, b)
        if a.isHave ~= b.isHave then
            return a.isHave
        elseif a.time ~= b.time then
            return a.time < b.time
        else
            return a.itemId < b.itemId
        end
    end)

    local itemData = {}
    for _, item in ipairs(self.itemList) do
        if item.isHave then
            itemData[#itemData + 1] = {
                id = item.itemId,
                supplyNum = ConfigTimeUtility.NsToSeconds(ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(item.itemId):SpeedTime()),
                inventory = ModuleRefer.InventoryModule:GetAmountByConfigId(item.itemId)
            }
        end
    end
    self.itemData = itemData
end

function CitySpeedUpGetMoreSupplyCellDataProvider:GetDesc()
    local supplyNum = 0
    local remainTime = self.holder:GetRemainTime()
    for _, item in ipairs(self.itemData) do
        supplyNum = supplyNum + item.supplyNum * item.inventory
    end
    return I18N.GetWithParams("speedup_desc_01", TimeFormatter.SimpleFormatTime(math.min(supplyNum, remainTime)))
end

function CitySpeedUpGetMoreSupplyCellDataProvider:GetName()
    return I18N.Get("speedup_title_2")
end

function CitySpeedUpGetMoreSupplyCellDataProvider:GetIcon()
    local cfg = ConfigRefer.Item:Find(self.itemList[1].itemId)
    return cfg:Icon()
end

function CitySpeedUpGetMoreSupplyCellDataProvider:OnSupply()

    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local noMoreDisplayConfirmTimeSec = tonumber(ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.NoMoreDisplayExchangePanel_SpeedUp))
    local hasNoMoreDisplayConfirmExpired = not noMoreDisplayConfirmTimeSec or not TimeFormatter.InSameDayBySeconds(curTimeSec, noMoreDisplayConfirmTimeSec)

    local holder = self:GetHolder()
    local remainTime = holder:GetRemainTime()

    local costItems = ExchangeResourceStatic.GetOneKeySupplyCost(self.itemData, remainTime)
    if not hasNoMoreDisplayConfirmExpired then
        local itemCfgId2Count = {}
        for _, item in ipairs(costItems) do
            itemCfgId2Count[item.id] = item.num
        end
        holder:UseMultiItemSpeedUp(itemCfgId2Count)
    else
        local supplyTime = 0
        for _, item in ipairs(costItems) do
            supplyTime = supplyTime + item.num * item.supplyNum
        end
        local isOverflow = supplyTime - remainTime > 60
        ---@type ExchangeResourceDirectMediatorParam
        local exchangeData = {}
        exchangeData.itemInfos = costItems
        exchangeData.type = ExchangeResourceStatic.DirectExchangePanelType.SpeedUp
        exchangeData.userData = holder
        exchangeData.isOverflow = isOverflow
        g_Game.UIManager:Open(UIMediatorNames.ExchangeResourceDirectMediator, exchangeData)
    end
end

function CitySpeedUpGetMoreSupplyCellDataProvider:ShouldTickUpdate()
    return true
end

return CitySpeedUpGetMoreSupplyCellDataProvider