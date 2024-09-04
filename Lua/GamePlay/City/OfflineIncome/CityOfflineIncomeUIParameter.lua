---@class CityOfflineIncomeUIParameter
---@field new fun():CityOfflineIncomeUIParameter
local CityOfflineIncomeUIParameter = class("CityOfflineIncomeUIParameter")
local TimeFormatter = require("TimeFormatter")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local CastleGetStockRoomResParameter = require("CastleGetStockRoomResParameter")

---@param city City
function CityOfflineIncomeUIParameter:ctor(city)
    self.city = city
end

---@return number
function CityOfflineIncomeUIParameter:GetOfflineIncomeProgress()
    local maxTime = self:GetMaxOfflineIncomeTime()
    local offlineTime = self:OfflineTimeSum()
    return math.min(offlineTime / maxTime, 1)
end

function CityOfflineIncomeUIParameter:OfflineTimeSum()
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastOfflineIncomeTime = self.city:GetCastle().GlobalData.OfflineData.LastGetOfflineBenefitTime.ServerSecond
    return math.max(0, now - lastOfflineIncomeTime)
end

function CityOfflineIncomeUIParameter:GetStrictOfflineIncomeTime()
    local origin = self:OfflineTimeSum()
    local maxTime = self:GetMaxOfflineIncomeTime()
    return math.min(origin, maxTime)
end

function CityOfflineIncomeUIParameter:GetMaxOfflineIncomeTime()
    return ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime)
end

---@return string
function CityOfflineIncomeUIParameter:GetOfflineIncomeTimeText()
    return TimeFormatter.TimerStringFormat(self:GetStrictOfflineIncomeTime())
end

---@return ItemIconData[]
function CityOfflineIncomeUIParameter:GetIncomeList()
    local furniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
    local castleFurniture = furniture:GetCastleFurniture()
    local stockInfo = castleFurniture.StockRoomInfo.Benefits
    local list = {}
    for itemId, count in pairs(stockInfo) do
        if math.floor(count) <= 0 then goto continue end
        local itemIconData = {
            configCell = ConfigRefer.Item:Find(itemId),
            count = math.floor(count),
            showCount = true,
        }
        table.insert(list, itemIconData)
        ::continue::
    end
    return list
end

function CityOfflineIncomeUIParameter:RequestClaimOfflineIncome()
    local furniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
    local param = CastleGetStockRoomResParameter.new()
    param.args.FurnitureId = furniture.singleId
    param:Send()
end

return CityOfflineIncomeUIParameter