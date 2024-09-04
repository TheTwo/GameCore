local KingdomPlacingType = require("KingdomPlacingType")

---@class KingdomPlacingStateFactory
local KingdomPlacingStateFactory = class("KingdomPlacingStateFactory")

local TypeToStateMap =
{
    [KingdomPlacingType.AllianceBuilding] = require("KingdomPlacingStateAllianceBuilding"),
    [KingdomPlacingType.Relocate] = require("KingdomPlacingStateRelocate"),
    [KingdomPlacingType.Behemoth] = require("KingdomPlacingStateBehemoth"),
}

---@param type number
function KingdomPlacingStateFactory.Create(type)
    local stateClass = TypeToStateMap[type]
    if stateClass then
        return stateClass.new()
    end
    g_Logger.Error("no placing state found to create!")
    return nil
end

return KingdomPlacingStateFactory