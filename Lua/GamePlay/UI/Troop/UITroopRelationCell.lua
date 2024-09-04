local BaseTableViewProCell = require('BaseTableViewProCell')
local UITroopHelper = require('UITroopHelper')
---@class UITroopRelationCell : BaseTableViewProCell
local UITroopRelationCell = class('UITroopRelationCell', BaseTableViewProCell)

---@class UITroopRelationCellData
---@field tiesId number
---@field isActivate boolean

function UITroopRelationCell:ctor()
end

function UITroopRelationCell:OnCreate()
    self.textEnable = self:Text('p_text_effect_now')
    self.textDisable = self:Text('p_text_effect_n')
    self.statusCtrler = self:StatusRecordParent('')
end

---@param data UITroopRelationCellData
function UITroopRelationCell:OnFeedData(data)
    self.tiesId = data.tiesId
    self.isActivate = data.isActivate
    self.statusCtrler:ApplyStatusRecord(self.tiesId)
    self.textEnable.text = UITroopHelper.GetTiesStrByTiesId(self.tiesId)
    self.textDisable.text = UITroopHelper.GetTiesStrByTiesId(self.tiesId)
    self.statusCtrler:ApplyStatusRecord(self.isActivate and 0 or 1)
end

return UITroopRelationCell