local BaseGetMoreCellDataProvider = require("BaseGetMoreCellDataProvider")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local ExchangeResourceStatic = require("ExchangeResourceStatic")
local UIMediatorNames = require("UIMediatorNames")
---@class GetMoreItemCellDataProvider : BaseGetMoreCellDataProvider
local GetMoreItemCellDataProvider = class("GetMoreItemCellDataProvider", BaseGetMoreCellDataProvider)

--- override functions ---

---@param itemId number
function GetMoreItemCellDataProvider:ctor(itemId)
    self.itemId = itemId
    self.itemCfg = ConfigRefer.Item:Find(itemId)
end

---override
---@return string @translated
function GetMoreItemCellDataProvider:GetName()
    return I18N.Get(self.itemCfg:NameKey())
end

---override
---@return string
function GetMoreItemCellDataProvider:GetIcon()
    return self.itemCfg:Icon()
end

---override
function GetMoreItemCellDataProvider:GetIconData()
    ---@type ItemIconData
    local data = {}
    data.configCell = self.itemCfg
    data.count = self:GetItemInventory()
    return data
end

---override
function GetMoreItemCellDataProvider:GetDesc()
    return I18N.Get(self.itemCfg:DescKey())
end

---override
function GetMoreItemCellDataProvider:OnPay()
    ---@type ExchangeResourceDirectMediatorParam
    local exchangeData = {}
    local maxNum = self:GetNeededNum()
    exchangeData.itemInfos = {{id = self.itemId, num = maxNum}}
    exchangeData.type = ExchangeResourceStatic.DirectExchangePanelType.PayAndUse
    exchangeData.userData = self.holder
    g_Game.UIManager:Open(UIMediatorNames.ExchangeResourceDirectMediator, exchangeData)
end

---override
function GetMoreItemCellDataProvider:IsItemCell()
    return true
end

-----------------------

---@return number
function GetMoreItemCellDataProvider:GetItemInventory()
    return ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemId)
end

function GetMoreItemCellDataProvider:GetNeededNum()
    return 99
end

function GetMoreItemCellDataProvider:GetCurrencyCfg()
    local getMoreCfg = ConfigRefer.GetMore:Find(self.itemCfg:GetMoreConfig())
    if not getMoreCfg then return nil end
    local exchangeCfg = getMoreCfg:Exchange()
    if not exchangeCfg then return nil end
    local currencyId = exchangeCfg:Currency()
    local currencyCfg = ConfigRefer.Item:Find(currencyId)
    return currencyCfg
end

function GetMoreItemCellDataProvider:GetCurrencyInventory()
    local currencyCfg = self:GetCurrencyCfg()
    if not currencyCfg then return 0 end
    return ModuleRefer.InventoryModule:GetAmountByConfigId(currencyCfg:Id())
end

function GetMoreItemCellDataProvider:GetCurrencyIcon()
    local currencyCfg = self:GetCurrencyCfg()
    if not currencyCfg then return "" end
    return currencyCfg:Icon()
end

function GetMoreItemCellDataProvider:GetSinglePrice()
    local getMoreCfg = ConfigRefer.GetMore:Find(self.itemCfg:GetMoreConfig())
    if not getMoreCfg then return 0 end
    local exchangeCfg = getMoreCfg:Exchange()
    if not exchangeCfg then return 0 end
    return exchangeCfg:CurrencyCount()
end

function GetMoreItemCellDataProvider:GetExchangeBtnText()
    return string.Empty
end

function GetMoreItemCellDataProvider:GetPayButtonText()
    return I18N.Get("getmore_name_buyanduse")
end

return GetMoreItemCellDataProvider