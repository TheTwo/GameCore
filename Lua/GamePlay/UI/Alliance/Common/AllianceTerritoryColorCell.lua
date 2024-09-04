local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryColorCellData
---@field Id number
---@field color CS.UnityEngine.Color

---@class AllianceTerritoryColorCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryColorCell
---@field super BaseTableViewProCell
local AllianceTerritoryColorCell = class('AllianceTerritoryColorCell', BaseTableViewProCell)

function AllianceTerritoryColorCell:OnCreate(data)
    self._p_btn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_icon_color = self:Image("p_icon_color")
    self._p_img_select_color = self:Image("p_img_select_color")
end

---@param data AllianceTerritoryColorCellData
function AllianceTerritoryColorCell:OnFeedData(data)
    self._p_icon_color.color = data.color
end

function AllianceTerritoryColorCell:Select(param)
    self._p_img_select_color:SetVisible(true)
end

function AllianceTerritoryColorCell:UnSelect(param)
    self._p_img_select_color:SetVisible(false)
end

function AllianceTerritoryColorCell:OnClickSelf()
    self:SelectSelf()
end

return AllianceTerritoryColorCell