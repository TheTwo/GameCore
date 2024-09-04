local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local RPPType = require("RPPType")
local UIHelper = require("UIHelper")
local SlgBattlePowerHelper = class('SlgRaisePowerHelper')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CityWorkType = require("CityWorkType")

function SlgBattlePowerHelper.ShowRaisePowerPopup(type,onClickFunc,troopPresetIndex)
    type = type or RPPType.Slg
    if type ~= RPPType.Pet and ModuleRefer.TroopModule:CanFillTroop(troopPresetIndex) then
        SlgBattlePowerHelper.ShouldEditTroop(type,onClickFunc)
    else
        SlgBattlePowerHelper.ShouldStrength(type,onClickFunc)
    end
end

function SlgBattlePowerHelper.ShouldEditTroop(type,onClickFunc)

    local confirmStr = "power_goto_squad_name"
    local cancelStr = "bestrongwarning_btn2"
    local descStr = "power_squad_spare_des"
   

    ---@type CommonConfirmPopupMediatorParameter
    local data = {}
    data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    data.title = I18N.Get("bestrongwarning_title")
    data.content = I18N.Get(descStr)
    data.confirmLabel = I18N.Get(confirmStr)
    data.cancelLabel = I18N.Get(cancelStr)
    data.onConfirm = function(context)       
        g_Game.UIManager:Open(UIMediatorNames.UITroopMediator)        
        return true
    end
    data.onCancel = function(context)
        if onClickFunc then
            onClickFunc()
        end
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator,data,nil,true)
end

function SlgBattlePowerHelper.ShouldStrength(type,onClickFunc)

    local confirmStr = (type == RPPType.Pet) and "bestrongwarning_btn3" or "bestrongwarning_btn1"
    local cancelStr = (type == RPPType.Pet) and "bestrongwarning_btn4" or "bestrongwarning_btn2"
    local descStr = nil
    if type == RPPType.Pet then
        descStr = "bestrongwarning_text2"
    else
        descStr = "bestrongwarning_text1"
    end

    ---@type CommonConfirmPopupMediatorParameter
    local data = {}
    data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    data.title = I18N.Get("bestrongwarning_title")
    data.content = I18N.Get(descStr)
    data.confirmLabel = I18N.Get(confirmStr)
    data.cancelLabel = I18N.Get(cancelStr)
    data.onConfirm = function(context)
        if type == RPPType.Pet then
            SlgBattlePowerHelper.JumpToCityFourniture()
        else
            g_Game.UIManager:Open(UIMediatorNames.UIStrengthenMediator)
        end
        return true
    end
    data.onCancel = function(context)
        if onClickFunc then
            onClickFunc()
        end
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator,data,nil,true)
end


function SlgBattlePowerHelper.JumpToCityFourniture()
    local myCity = ModuleRefer.CityModule:GetMyCity()
    if not myCity then return end    
    local furniture = myCity.furnitureManager:GetFurnitureByTypeCfgId(1011)
    if not furniture then return end
    local furnitureId = furniture.singleId
    local CityUtils = require("CityUtils")
    CityUtils.TryLookAtToCityCoord(myCity, furniture.x, furniture.y, nil, function()
            myCity:ForceSelectFurniture(furnitureId)
            local workCfgId = furniture:GetWorkCfgId(CityWorkType.Process)
            local workCfg = ConfigRefer.CityWork:Find(workCfgId)
            if workCfg ~= nil and workCfg:GuideForOverviewCard() > 0 then
                ModuleRefer.GuideModule:CallGuide(workCfg:GuideForOverviewCard())
            end
        end,true
    )
end

---@param power number
---@param needPower number
---@param recommendPower number
---@return number @-1:无效 0:平局 1:胜利 2:失败
function SlgBattlePowerHelper.ComparePower(power,needPower,recommendPower)
    if not power or not needPower or needPower <= 0 or not recommendPower or recommendPower <= 0 then
        return -1
    end
    if power < needPower then
        return 2
    elseif power >= recommendPower then
        return 1
    else
        return 0
    end
end

---@param compareResult number
function SlgBattlePowerHelper.GetPowerCompareIcon(compareResult)
    local resIcon
    if compareResult == 1 then
        resIcon = 'sp_slg_icon_easy'      
    elseif compareResult == 2 then
        resIcon = 'sp_slg_icon_difficult'      
    else 
        resIcon = 'sp_slg_icon_medium'         
    end
    return resIcon
end
---@param compareResult number
function SlgBattlePowerHelper.GetPowerCompareTipString(compareResult,isPetCatch)
    local resStr
    local colorStr
    if compareResult == 1 then        
        if isPetCatch then
            resStr = 'petwild_winnerdecision'
        else
            resStr = 'slg_winnerdecision'
        end
        colorStr = '#6D9D3A'
    elseif compareResult == 2 then        
        if isPetCatch then
            resStr = 'petwild_pipdecision'
        else
            resStr = 'slg_losedecision'
        end
        colorStr = '#B8120E'
    else       
        resStr = 'slg_pipdecision'
        colorStr = '#CA9850'    
    end
    return UIHelper.GetColoredText(I18N.Get(resStr),colorStr)
end

return SlgBattlePowerHelper