
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBuildingDetailItemCellData
---@field icon string
---@field name string
---@field value string

---@class AllianceBuildingDetailItemCell:BaseTableViewProCell
---@field new fun():AllianceBuildingDetailItemCell
---@field super BaseTableViewProCell
local AllianceBuildingDetailItemCell = class('AllianceBuildingDetailItemCell', BaseTableViewProCell)

function AllianceBuildingDetailItemCell:OnCreate(param)
    self._p_icon = self:Image("p_icon")
    self._p_text = self:Text("p_text")
    self._p_text_number = self:Text("p_text_number")
end

---@param data AllianceBuildingDetailItemCell
function AllianceBuildingDetailItemCell:OnFeedData(data)
    if string.IsNullOrEmpty(data.icon) then
        self._p_icon:SetVisible(false)
    else
        self._p_icon:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon)
    end
    self._p_text.text = data.name
    self._p_text_number.text = data.value
end

return AllianceBuildingDetailItemCell