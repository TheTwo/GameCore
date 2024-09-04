local BaseGetMoreDataProvider = require("BaseGetMoreDataProvider")
local I18N = require("I18N")
local CityWorkI18N = require("CityWorkI18N")
local CitySpeedUpGetMoreItemCellDataProvider = require("CitySpeedUpGetMoreItemCellDataProvider")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local CitySpeedUpGetMoreSupplyCellDataProvider = require("CitySpeedUpGetMoreSupplyCellDataProvider")
---@class CitySpeedUpGetMoreProvider : BaseGetMoreDataProvider
local CitySpeedUpGetMoreProvider = class("CitySpeedUpGetMoreProviderreProvider", BaseGetMoreDataProvider)

function CitySpeedUpGetMoreProvider:ctor()
    CitySpeedUpGetMoreProvider.super.ctor(self)
    self.items = {}
end

function CitySpeedUpGetMoreProvider:SetItemList(itemList)
    Utils.CopyArray(itemList, self.items)
end

function CitySpeedUpGetMoreProvider:GetTitle()
    return I18N.Get(CityWorkI18N.UI_TitleFurnitureUpgrade_SpeedUp)
end

function CitySpeedUpGetMoreProvider:GetCellDatas()
    ---@type GetMoreCellData[]
    local ret = {}

    local itemList = {}
    for _, itemId in ipairs(self.items) do
        local isHave = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId) > 0
        itemList[#itemList + 1] = {itemId = itemId, isHave = isHave, time = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemId):SpeedTime()}
    end
    table.sort(itemList, function(a, b)
        if a.isHave ~= b.isHave then
            return a.isHave
        elseif a.time ~= b.time then
            return a.time < b.time
        else
            return a.itemId < b.itemId
        end
    end)

    if #itemList > 0 and itemList[1].isHave then
        ---@type GetMoreCellData
        local data = {}
        data.provider = CitySpeedUpGetMoreSupplyCellDataProvider.new()
        data.provider:SetHolder(self.holder)
        data.provider:SetItemList(self.items)
        data.cellType = 0
        table.insert(ret, data)
    end

    for _, item in ipairs(itemList) do
        ---@type GetMoreCellData
        local data = {}
        data.provider = CitySpeedUpGetMoreItemCellDataProvider.new(item.itemId)
        data.provider:SetHolder(self.holder)
        data.cellType = 0
        table.insert(ret, data)
    end

    return ret
end

function CitySpeedUpGetMoreProvider:OnPay(transform)
    local currencyId = 2 -- 等待getmore配置
    local curInventory = ModuleRefer.InventoryModule:GetAmountByConfigId(currencyId)
    local remainTime = self.holder:GetRemainTime()
    local cost = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
    if curInventory < cost then
        ModuleRefer.ConsumeModule:GotoShop()
        return
    end
    self.holder:RequestConsume(transform)
end

return CitySpeedUpGetMoreProvider