
---@type table<string, CityExplorerPetState>
local CityExplorerPetStateSet = {
    ["CityExplorerPetStateEnter"] = require("CityExplorerPetStateEnter"),
    ["CityExplorerPetStateFollow"] = require("CityExplorerPetStateFollow"),
    ["CityExplorerPetStateHideInBattle"] = require("CityExplorerPetStateHideInBattle"),
    ["CityExplorerPetStateCollect"] = require("CityExplorerPetStateCollect"),
    ["CityExplorerPetStateRecoverFromSeBattle"] = require("CityExplorerPetStateRecoverFromSeBattle"),
}

return CityExplorerPetStateSet