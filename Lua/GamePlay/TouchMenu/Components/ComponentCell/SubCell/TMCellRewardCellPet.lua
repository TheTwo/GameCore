local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class TMCellRewardCellPet:BaseTableViewProCell
local TMCellRewardCellPet = class('TMCellRewardCellPet', BaseTableViewProCell)

function TMCellRewardCellPet:OnCreate()
    self._child_card_pet_s = self:LuaBaseComponent("child_card_pet_s")
end

---@param data UIPetIconData
function TMCellRewardCellPet:OnFeedData(data)
    self._child_card_pet_s:FeedData(data)
end

return TMCellRewardCellPet