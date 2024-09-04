local GetMoreItemCellDataProvider = require("GetMoreItemCellDataProvider")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local ConvertPieceToAdornmentParameter = require("ConvertPieceToAdornmentParameter")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UseItemParameter = require("UseItemParameter")
local ModuleRefer = require("ModuleRefer")
---@class AdornmentGetMoreItemCellDataProvider : GetMoreItemCellDataProvider
local AdornmentGetMoreItemCellDataProvider = class("AdornmentGetMoreItemCellDataProvider", GetMoreItemCellDataProvider)

function AdornmentGetMoreItemCellDataProvider:GetStatusIndex()
    return 2
end

function AdornmentGetMoreItemCellDataProvider:GetExchangeBtnText()
    if self.itemCfg:NeedPieceNum() > 0 then
        return I18N.Get("skincollection_fragmentsplice")
    else
        return I18N.Get("energy_btn_use")
    end
end

function AdornmentGetMoreItemCellDataProvider:GetDesc()
    return I18N.GetWithParams(self.itemCfg:DescKey(), self.itemCfg:NeedPieceNum())
end

function AdornmentGetMoreItemCellDataProvider:CanExchage()
    return self:GetItemInventory() >= self.itemCfg:NeedPieceNum()
end

function AdornmentGetMoreItemCellDataProvider:ShouldOverrideStatus()
    return true
end

function AdornmentGetMoreItemCellDataProvider:ShowExchange()
    return true
end

function AdornmentGetMoreItemCellDataProvider:OnExchange()
    if self.itemCfg:NeedPieceNum() > 0 then
        self:ConvertPieceToAdornment()
    else
        self:UnlockAdornment()
    end
end

---@private
function AdornmentGetMoreItemCellDataProvider:ConvertPieceToAdornment()
    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("skincollection_fragmentsplice")
    local nameStr = string.format("<b>%s</b>", I18N.Get(self.itemCfg:NameKey()))
    dialogParam.content = I18N.GetWithParams("skincollection_fragmentsplice_makesure", nameStr)
    dialogParam.onConfirm = function()
        local configID = tonumber(self.itemCfg:UseParam(1))
        local parameter = ConvertPieceToAdornmentParameter.new()
        parameter.args.AdornmentCfgId = configID
        parameter.args.Use = true
        parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
            if isSuccess then
                local mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
                if mediator then
                    mediator:InitTypeItem(mediator:GetCurFilterData())
                end
            end
        end)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

function AdornmentGetMoreItemCellDataProvider:UnlockAdornment()
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
        msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
            if isSuccess then
                local mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
                if mediator then
                    -- mediator:UpdateSelectedItem()
                    mediator:InitTypeItem(mediator:GetCurFilterData())
                end
            end
        end)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

return AdornmentGetMoreItemCellDataProvider