local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceCenterTransformListEmptyCell:BaseTableViewProCell
---@field new fun():AllianceCenterTransformListEmptyCell
---@field super BaseTableViewProCell
local AllianceCenterTransformListEmptyCell = class('AllianceCenterTransformListEmptyCell', BaseTableViewProCell)

function AllianceCenterTransformListEmptyCell:OnCreate(param)
    self._p_text_empty = self:Text("p_text_empty")
end

---@param data string
function AllianceCenterTransformListEmptyCell:OnFeedData(data)
    self._p_text_empty.text = data
end

return AllianceCenterTransformListEmptyCell