local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local ConfigTimeUtility = require('ConfigTimeUtility')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIMediatorNames = require("UIMediatorNames")
local DoNotShowAgainHelper = require("DoNotShowAgainHelper")

---@class ConsumeModule:BaseModule
local ConsumeModule = class('ConsumeModule', BaseModule)

function ConsumeModule:OnRegister()
    
end

function ConsumeModule:OnRemove()
    
end

function ConsumeModule:GetSpeedUpCommonItemCfg()
    local itemId = ConfigRefer.CityConfig:SpeedUpCommonItem()
    return ConfigRefer.Item:Find(itemId)
end

---@return number @返回时间对应的开销
function ConsumeModule:CalculateFurnitureLevelUpCost(time)
    local unit = ConfigTimeUtility.NsToSeconds(ConfigRefer.CityConfig:SpeedUpTimeUnit())
    local frequency = math.ceil(time / unit)
    if frequency == 0 then
        return 0
    end

    local unitPrice = ConfigRefer.CityConfig:SpeedUpCostCountPerUnit()
    return frequency * unitPrice
end

function ConsumeModule:GetOwnedConsumeCoin()
    local coinItemId = ConfigRefer.CityConfig:SpeedUpCommonItem()
    return ModuleRefer.InventoryModule:GetAmountByConfigId(coinItemId)
end

function ConsumeModule:CanSpeedUpFurnitureLevelUpCostWithMoney(time)
    local cost = self:CalculateFurnitureLevelUpCost(time)
    if cost == 0 then return true end

    local coinItemId = ConfigRefer.CityConfig:SpeedUpCommonItem()
    local own = ModuleRefer.InventoryModule:GetAmountByConfigId(coinItemId)
    return own >= cost
end

---@param time number
---@param callback fun():boolean
function ConsumeModule:OpenCommonConfirmUIForLevelUpCost(time, callback)
    local cost = self:CalculateFurnitureLevelUpCost(time)
    local threshold = ConfigRefer.CityConfig:LowestConsumption() or 0
    local shouldShowDoubleCheck = DoNotShowAgainHelper.CanShowAgain("FurnitureLevelUpCost", DoNotShowAgainHelper.Cycle.Daily)
    if cost == 0 or cost < threshold or not shouldShowDoubleCheck then
        if callback then
            callback()
        end
        return
    end

    local itemCfg = self:GetSpeedUpCommonItemCfg()
    ---@type CommonConfirmPopupMediatorParameter
    local confirmParameter = {}
    confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel |
    CommonConfirmPopupMediatorDefine.Style.ExitBtn |
    CommonConfirmPopupMediatorDefine.Style.Toggle
    confirmParameter.title = I18N.Get("Pay_FurUpTime_Titile")
    confirmParameter.content = I18N.GetWithParams("Pay_FurUpTime_Des", I18N.Get(itemCfg:NameKey()), cost)
    confirmParameter.confirmLabel = I18N.Get("Pay_FurUpTime_Confirm")
    confirmParameter.cancelLabel = I18N.Get("Pay_FurUpTime_Cancel")
    confirmParameter.toggleDescribe = I18N.Get("alliance_battle_confirm2")

    -- ---@type CommonPairsQuantityParameter
    -- local iconInfo = {}
    -- iconInfo.customQuality = itemCfg:Quality()
    -- iconInfo.itemIcon = UIHelper.IconOrMissing(itemCfg:Icon())
    -- iconInfo.num2 = cost
    -- iconInfo.num1 = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfg:Id())
    -- iconInfo.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
    -- confirmParameter.items = {iconInfo}

    confirmParameter.toggleClick = function(_, check)
        if check then
            DoNotShowAgainHelper.SetDoNotShowAgain("FurnitureLevelUpCost")
            return true
        else
            DoNotShowAgainHelper.RemoveDoNotShowAgain("FurnitureLevelUpCost")
            return false
        end
    end

    confirmParameter.onConfirm = function()
        if callback then
            return callback()
        end
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
end

function ConsumeModule:GotoShop()
    ---GotoCall-Id 来自赵薏寒
    ModuleRefer.GuideModule:CallGuide(5240)
end

return ConsumeModule