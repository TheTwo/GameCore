---@type table<string, CityCitizenState>
local CityCitizenStateSubSet = {
    CityCitizenStateSubRandomWait = require("CityCitizenStateSubRandomWait"),
    CityCitizenStateSubRandomTarget = require("CityCitizenStateSubRandomTarget"),
    CityCitizenStateSubSelectWorkTarget = require("CityCitizenStateSubSelectWorkTarget"),
    CityCitizenStateSubGoToTarget = require("CityCitizenStateSubGoToTarget"),
    CityCitizenStateSubInteractTarget = require("CityCitizenStateSubInteractTarget"),
    CityCitizenStateSubNotWorking = require("CityCitizenStateSubNotWorking"),
    CityCitizenStateSubWorkingLoop = require("CityCitizenStateSubWorkingLoop"),
    CityCitizenStateSubEscape = require("CityCitizenStateSubEscape"),
}

return CityCitizenStateSubSet

