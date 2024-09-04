local EventConst = require("EventConst")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")

local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")

---@class KingdomTouchInfoProviderFlexibleBuilding:KingdomTouchInfoProvider
---@field new fun():KingdomTouchInfoProviderFlexibleBuilding
---@field super KingdomTouchInfoProvider
local KingdomTouchInfoProviderFlexibleBuilding = class('KingdomTouchInfoProviderFlexibleBuilding', KingdomTouchInfoProvider)

function KingdomTouchInfoProviderFlexibleBuilding:CreateBasicInfo(tile)
    ---@type wds.TransferTower|wds.EnergyTower
    local entity = tile.entity
    local flexibleMapBuildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    local basicInfo = KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    basicInfo:SetTipsOnClick(function()
        g_Game.EventManager:TriggerEvent(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, I18N.Get(flexibleMapBuildingConfig:Des()))
    end)
    return basicInfo
end

---@return TouchMenuCellDatumBase[]
function KingdomTouchInfoProviderFlexibleBuilding:CreateDetailInfo(tile) 
    return KingdomTouchInfoCompHelper.GenerateBuildingDetailWindow(tile)
end

function KingdomTouchInfoProviderFlexibleBuilding:CreateButtonInfo(tile)
    return {}
end

return KingdomTouchInfoProviderFlexibleBuilding