local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryEmptyCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryEmptyCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryEmptyCell = class('AllianceTerritoryMainSummaryEmptyCell', BaseTableViewProCell)

return AllianceTerritoryMainSummaryEmptyCell