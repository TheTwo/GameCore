local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CatchPetResultCellData
---@field isNew boolean
---@field petIconData CommonPetIconBaseData

---@class CatchPetResultCell:BaseTableViewProCell
---@field new fun():CatchPetResultCell
---@field super BaseTableViewProCell
local CatchPetResultCell = class('CatchPetResultCell', BaseTableViewProCell)

function CatchPetResultCell:OnCreate()
    ---@type CommonPetIcon
    self._child_card_pet_s = self:LuaObject("child_card_pet_s")
    self.goNew = self:GameObject('child_reddot_default')
    self.vxTrigger = self:AnimTrigger('trigger_cell')
end

---@param data CatchPetResultCellData
function CatchPetResultCell:OnFeedData(data)
    self.data = data
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self:RefreshUI()
end

function CatchPetResultCell:RefreshUI()
    self._child_card_pet_s:FeedData(self.data.petIconData)
    self.goNew:SetVisible(self.data.isNew)
end

return CatchPetResultCell