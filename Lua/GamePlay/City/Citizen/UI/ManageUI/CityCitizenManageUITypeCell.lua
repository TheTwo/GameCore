local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityCitizenManageUITypeCellData
---@field id number
---@field type CityCitizenManageUITypeCellDataDefine.Type
---@field icon string
---@field count number
---@field onSelected fun(id)

---@class CityCitizenManageUITypeCell:BaseTableViewProCell
---@field new fun():CityCitizenChooseTypeCell
---@field super BaseTableViewProCell
local CityCitizenManageUITypeCell = class('CityCitizenManageUITypeCell', BaseTableViewProCell)

function CityCitizenManageUITypeCell:OnCreate(_)
    self._p_selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_img_select = self:Image("p_img_select")
    self._p_icon_a = self:Image("p_icon_a")
    self._p_icon_c = self:Image("p_icon_c")
    self._p_icon_tip_b = self:Image("p_icon_tip_b")
end

---@param data CityCitizenManageUITypeCellData
function CityCitizenManageUITypeCell:OnFeedData(data)
    self._id = data.id
    self._callback = data.onSelected
    self._p_icon_a:SetVisible(true)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_a)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_c)
    self._p_icon_c:SetVisible(false)
end

function CityCitizenManageUITypeCell:OnClickSelf()
    self._callback(self._id)
end

function CityCitizenManageUITypeCell:Select(_)
    self._p_img_select:SetVisible(true)
    self._p_icon_c:SetVisible(true)
end

function CityCitizenManageUITypeCell:UnSelect(_)
    self._p_icon_c:SetVisible(false)
    self._p_img_select:SetVisible(false)
end

return CityCitizenManageUITypeCell

