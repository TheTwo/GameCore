local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local AddAdormentDataProvider = require("AddAdormentDataProvider")
local ProtectItemDataProvider = require("ProtectItemDataProvider")
local GotoItemDataProvider = require("GotoItemDataProvider")
local AllianceExpeditionDataProvider = require("AllianceExpeditionDataProvider")
local AddPPPItemDataProvider = require("AddPPPItemDataProvider")
local OpenBoxItemDataProvider = require("OpenBoxItemDataProvider")
local FunctionClass = require("FunctionClass")
---@class ItemDataProviderSimpleFactory
local ItemDataProviderSimpleFactory = class("ItemDataProviderSimpleFactory")

---@param itemCfg ItemConfigCell
---@return FunctionalItemDataProvider
function ItemDataProviderSimpleFactory:Create(itemCfg)
    if itemCfg:UseGoto() > 0 then
        return GotoItemDataProvider.new(itemCfg)
    elseif itemCfg:FunctionClass() == FunctionClass.AddAdornment then
        return AddAdormentDataProvider.new(itemCfg)
    elseif itemCfg:FunctionClass() == FunctionClass.SetProtection then
        return ProtectItemDataProvider.new(itemCfg)
    elseif itemCfg:FunctionClass() == FunctionClass.AllianceExpedition then
        return AllianceExpeditionDataProvider.new(itemCfg)
    elseif itemCfg:FunctionClass() == FunctionClass.AddPPP then
        return AddPPPItemDataProvider.new(itemCfg)
    elseif itemCfg:FunctionClass() == FunctionClass.OpenBox then
        return OpenBoxItemDataProvider.new(itemCfg)
    else
        return FunctionalItemDataProvider.new(itemCfg)
    end
end

return ItemDataProviderSimpleFactory