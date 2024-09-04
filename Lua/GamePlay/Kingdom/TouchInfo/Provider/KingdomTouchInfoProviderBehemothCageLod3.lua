local ConfigRefer = require("ConfigRefer")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local I18N = require("I18N")
local EventConst = require("EventConst")
local SlgTouchMenuInfoProviderBehemoth = require("SlgTouchMenuInfoProviderBehemoth")
local KingdomTouchInfoProviderVillage = require("KingdomTouchInfoProviderVillage")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")

local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")

---@class KingdomTouchInfoProviderBehemothCageLod3:KingdomTouchInfoProvider
---@field super KingdomTouchInfoProvider
local KingdomTouchInfoProviderBehemothCageLod3 = class('KingdomTouchInfoProviderBehemothCageLod3', KingdomTouchInfoProvider)

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderBehemothCageLod3:CreateBasicInfo(tile)
    ---@type wds.BehemothCage
    local entity = tile.entity
    local fixedMapBuildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.BehemothCage.ConfigId)
    local basicInfo = KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    basicInfo:SetTipsOnClick(function()
        g_Game.EventManager:TriggerEvent(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, I18N.Get(fixedMapBuildingConfig:Des()))
    end)
    return basicInfo
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderBehemothCageLod3:CreateDetailInfo(tile)
    ---@type wds.BehemothCage
    local entity = tile.entity

    local ret = {}
    local pairOccupiedAlliances = KingdomTouchInfoProviderVillage.GetOccupyInfoPart(entity)
    table.insert(ret, pairOccupiedAlliances)
    return ret
end

---@param tile MapRetrieveResult
---@return TouchMenuButtonTipsData
function KingdomTouchInfoProviderBehemothCageLod3:CreateTipData(tile)
    return SlgTouchMenuInfoProviderBehemoth.GetButtonTipByEntity(tile.entity)
end

function KingdomTouchInfoProviderBehemothCageLod3:CreateButtonInfo(tile)
    local buttons = {}
    local gotoBtn = TouchMenuMainBtnDatum.new(I18N.Get("alliance_behemoth_button_goto"), KingdomTouchInfoOperation.LookAt, tile)
    table.insert(buttons, gotoBtn)
    return buttons
end

return KingdomTouchInfoProviderBehemothCageLod3