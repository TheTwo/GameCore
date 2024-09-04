local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceCenterTransformListTitleCell:BaseTableViewProCell
---@field new fun():AllianceCenterTransformListTitleCell
---@field super BaseTableViewProCell
local AllianceCenterTransformListTitleCell = class('AllianceCenterTransformListTitleCell', BaseTableViewProCell)

function AllianceCenterTransformListTitleCell:OnCreate(param)
    self._p_text_title = self:Text("p_text_title")
end

---@param data string
function AllianceCenterTransformListTitleCell:OnFeedData(data)
    self._p_text_title.text = data
end

return AllianceCenterTransformListTitleCell