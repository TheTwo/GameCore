local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ItemType = require("ItemType")

local PayConfirmHelper = {}

--- 打开一个支付道具不足的弹窗
---@param itemId number @所需道具的configId
---@param insufficientCount number @缺少道具的数量
---@param onConfirm fun()
function PayConfirmHelper.ShowSimpleConfirmationPopupForInsufficientItem(itemId, insufficientCount, onConfirm)
    ModuleRefer.InventoryModule:OpenExchangePanel({{id = itemId, num = insufficientCount}})
end

return PayConfirmHelper