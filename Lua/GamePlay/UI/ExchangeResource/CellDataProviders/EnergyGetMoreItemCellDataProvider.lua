local GetMoreItemCellDataProvider = require("GetMoreItemCellDataProvider")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local UseItemParameter = require("UseItemParameter")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
---@class EnergyGetMoreItemCellDataProvider : GetMoreItemCellDataProvider
local EnergyGetMoreItemCellDataProvider = class("EnergyGetMoreItemCellDataProvider", GetMoreItemCellDataProvider)

function EnergyGetMoreItemCellDataProvider:GetStatusIndex()
    if self:GetItemInventory() > 0 then
        return 2
    else
        return 3
    end
end

function EnergyGetMoreItemCellDataProvider:GetGotoText()
    return I18N.Get("energy_btn_use")
end

function EnergyGetMoreItemCellDataProvider:GetNeededNum()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curAddedPPP = player and player.PlayerWrapper2.Radar.PPP.ItemAddPPP
    local maxPPP = ConfigRefer.ConstMain:ItemAddPPPDayMax()
    local remain = math.max(maxPPP - (curAddedPPP or 0), 0)
    return math.min(remain / 30, 1)
end

function EnergyGetMoreItemCellDataProvider:OnGoto()
    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("skincollection_unlockwithitem")
    local nameStr = string.format("<b>%s</b>", I18N.Get(self.itemCfg:NameKey()))
    dialogParam.content = I18N.GetWithParams("skincollection_use_makesure", nameStr)
    dialogParam.onConfirm = function()
        local msg = UseItemParameter.new()
        msg.args.ComponentID = ModuleRefer.InventoryModule:GetUidByConfigId(self.itemId)
        msg.args.Num = 1
        msg:Send()
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

return EnergyGetMoreItemCellDataProvider