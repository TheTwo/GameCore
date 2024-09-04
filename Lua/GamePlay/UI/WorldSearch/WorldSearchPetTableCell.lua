local BaseTableViewProCell = require("BaseTableViewProCell")

---@class WorldSearchPetTableData
---@field petData CommonPetIconBaseData
---@field isNew boolean 

---@class WorldSearchPetTableCell : BaseTableViewProCell
---@field petIcon CommonPetIconSmall
local WorldSearchPetTableCell = class("WorldSearchPetTableCell", BaseTableViewProCell)

function WorldSearchPetTableCell:OnCreate(param)
    self.petIcon = self:LuaObject("child_card_pet_circle")
    self.goNew = self:GameObject("child_reddot_default")
end

---@param data WorldSearchPetTableData
function WorldSearchPetTableCell:OnFeedData(data)
    self.goNew:SetVisible(data.isNew)
    self.petIcon:FeedData(data.petData)
end

return WorldSearchPetTableCell