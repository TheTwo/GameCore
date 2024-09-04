local ModuleRefer = require("ModuleRefer")
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")

local TouchMenuMainBtnGroupData = require("TouchMenuMainBtnGroupData")
local TouchMenuCellRewardDatum = require("TouchMenuCellRewardDatum")
local TouchMenuPageDatum = require("TouchMenuPageDatum")
local TouchMenuCellLeagueDatum = require("TouchMenuCellLeagueDatum")
local TouchMenuUIDatum = require("TouchMenuUIDatum")
local UIMediatorNames = require("UIMediatorNames")
local TimerUtility = require("TimerUtility")


local TouchMenuHelper = {}

function TouchMenuHelper.CommonTimerCallback()
    TimerUtility.DelayExecuteInFrame(function()
        g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)
    end, 1)
end

---@return CommonTimerData
function TouchMenuHelper.GetSecondTickCommonTimerData(time, callback)
    return {endTime = time, needTimer = true, intervalTime = 1, callBack = callback}
end

---@param entity wds.Village
function TouchMenuHelper.GetAllianceLogoDatum(entity, clickCallback)
    local allianceStr = string.Empty
    local color
    if entity.Owner.AllianceID > 0 then
        allianceStr = ModuleRefer.PlayerModule.FullName(entity.Owner.AllianceAbbr.String, entity.Owner.AllianceName.String)
        if ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
            color = UIHelper.TryParseHtmlString(ColorConsts.army_blue)
        else
            color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        end
    else
        allianceStr = I18N.Get("village_info_No_Occupation")
    end
    local appear = entity.Owner.AllianceBadgeAppearance
    local pattern = entity.Owner.AllianceBadgePattern
    local pairOccupiedAlliances = TouchMenuCellLeagueDatum.new(allianceStr, color, appear, pattern, clickCallback)
    return pairOccupiedAlliances
end

---@param btns TouchMenuMainBtnDatum[]
function TouchMenuHelper.GetRecommendButtonGroupDataArray(btns)
    local btnCount = #btns
    if btnCount <= 0 then
        return {}
    elseif btnCount <= 3 then
        return {TouchMenuMainBtnGroupData.new(table.unpack(btns))}
    elseif btnCount == 4 then
        return {TouchMenuMainBtnGroupData.new(btns[1], btns[2]), TouchMenuMainBtnGroupData.new(btns[3], btns[4])}
    elseif btnCount == 5 then
        return {TouchMenuMainBtnGroupData.new(btns[1], btns[2]), TouchMenuMainBtnGroupData.new(btns[3], btns[4], btns[5])}
    else
        return {TouchMenuMainBtnGroupData.new(btns[1], btns[2], btns[3]), TouchMenuMainBtnGroupData.new(btns[4], btns[5], btns[6])}
    end
end

---@param rewards ItemIconData[]
---@param text string
---@return TouchMenuCellRewardDatum
function TouchMenuHelper.GetCellRewardDatum(rewards, text)
    local ret = TouchMenuCellRewardDatum.new(text)
    for i, v in ipairs(rewards) do
        ret:AppendItemIconData(v)
    end
    return ret
end

---@param basic TouchMenuBasicInfoDatum
---@param powerData TouchMenuPowerDatum
---@return TouchMenuUIDatum
function TouchMenuHelper.GetSinglePageUIDatum(basic, compsData, buttonGroupData, buttonTipsData, shareClick, toggleImage, pollutedData, powerData)
    local page = TouchMenuPageDatum.new(basic, compsData, buttonGroupData, buttonTipsData, shareClick, toggleImage, pollutedData, powerData)
    return TouchMenuUIDatum.new(page)
end

return TouchMenuHelper