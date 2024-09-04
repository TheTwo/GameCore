local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceActivityWarMainRewardCell:BaseTableViewProCell
---@field new fun():AllianceActivityWarMainRewardCell
---@field super BaseTableViewProCell
local AllianceActivityWarMainRewardCell = class('AllianceActivityWarMainRewardCell', BaseTableViewProCell)

function AllianceActivityWarMainRewardCell:OnCreate(param)
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
end

---@param data ItemGroupInfo
function AllianceActivityWarMainRewardCell:OnFeedData(data)
    ---@type ItemIconData
    local iconData = {}
    iconData.configCell = ConfigRefer.Item:Find(data:Items())
    iconData.count = data:Nums()
    iconData.useNoneMask = false
    iconData.showTips = true
    self._child_item_standard_s:FeedData(iconData)
end

return AllianceActivityWarMainRewardCell