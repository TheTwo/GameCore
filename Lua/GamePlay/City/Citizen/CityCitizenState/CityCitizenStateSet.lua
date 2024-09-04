---@type table<string, CityCitizenState>
local CityCitizenStateSet = {
    CityCitizenStateSyncFromServerData = require("CityCitizenStateSyncFromServerData"),
    CityCitizenStateNotAssigned = require("CityCitizenStateNotAssigned"),
    CityCitizenStateAssigned = require("CityCitizenStateAssigned"),
    CityCitizenStateFainting = require("CityCitizenStateFainting"),
    CityCitizenStateWaitSync = require("CityCitizenStateWaitSync"),
    CityCitizenStateSyncToServer = require("CityCitizenStateSyncToServer"),
}

return CityCitizenStateSet

