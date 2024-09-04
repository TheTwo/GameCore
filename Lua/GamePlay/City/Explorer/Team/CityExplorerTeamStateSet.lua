---@class CityExplorerTeamStateSet
local CityExplorerTeamStateSet = {}

---@type table<string, CityExplorerTeamState>
CityExplorerTeamStateSet.TeamState = {
    ["CityExplorerTeamStateSyncFromData"] = require("CityExplorerTeamStateSyncFromData"),
    ["CityExplorerTeamStateIdle"] = require("CityExplorerTeamStateIdle"),
    ["CityExplorerTeamStateGoToTarget"] = require("CityExplorerTeamStateGoToTarget"),
    ["CityExplorerTeamStateInteractTarget"] = require("CityExplorerTeamStateInteractTarget"),
    ["CityExplorerTeamStateWaitEnterSeBattle"] = require("CityExplorerTeamStateWaitEnterSeBattle"),
    ["CityExplorerTeamStateWaitSeBattleEnd"] = require("CityExplorerTeamStateWaitSeBattleEnd"),
    ["CityExplorerTeamStateBackToBase"] = require("CityExplorerTeamStateBackToBase"),
}

return CityExplorerTeamStateSet

