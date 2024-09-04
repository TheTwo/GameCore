local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityCitizenChooseTypeCellData
---@field id number
---@field type number
---@field icon string
---@field hasWarning boolean
---@field count number
---@field onSelected fun(id)

---@class CityCitizenChooseTypeCell:BaseTableViewProCell
---@field new fun():CityCitizenChooseTypeCell
---@field super BaseTableViewProCell
local CityCitizenChooseTypeCell = class('CityCitizenChooseTypeCell', BaseTableViewProCell)

function CityCitizenChooseTypeCell:OnCreate(_)
    self._p_selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_img_select = self:Image("p_img_select")
    self._p_text_number = self:Text("p_text_number")
    self._p_text_number_select = self:Text("p_text_number_select")
    self._p_icon_a = self:Image("p_icon_a")
    self._p_icon_b = self:Image("p_icon_b")
    self._p_icon_tip_b = self:Image("p_icon_tip_b")
end

---@param data CityCitizenChooseTypeCellData
function CityCitizenChooseTypeCell:OnFeedData(data)
    self._id = data.id
    self._callback = data.onSelected
    if data.hasWarning then
        self._p_icon_a:SetVisible(false)
        self._p_icon_b:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_b)
    else
        self._p_icon_a:SetVisible(true)
        self._p_icon_b:SetVisible(false)
        g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_a)
    end
    local v = tostring(data.count)
    self._p_text_number.text = v
    self._p_text_number_select.text = v
end

function CityCitizenChooseTypeCell:OnClickSelf()
    self._callback(self._id)
end

function CityCitizenChooseTypeCell:Select(_)
    self._p_img_select:SetVisible(true)
    self._p_text_number:SetVisible(false)
    self._p_text_number_select:SetVisible(true)
end

function CityCitizenChooseTypeCell:UnSelect(_)
    self._p_img_select:SetVisible(false)
    self._p_text_number:SetVisible(true)
    self._p_text_number_select:SetVisible(false)
end

return CityCitizenChooseTypeCell

