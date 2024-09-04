local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceAppointmentCellData
---@field Rank number
---@field IsCurrent boolean
---@field currentCount number
---@field maxCount number

---@class AllianceAppointmentCell:BaseTableViewProCell
---@field new fun():AllianceAppointmentCell
---@field super BaseTableViewProCell
local AllianceAppointmentCell = class('AllianceAppointmentCell', BaseTableViewProCell)

function AllianceAppointmentCell:OnCreate(param)
    self._p_btn = self:Button("p_btn", Delegate.GetOrCreate(self, self.SelectSelf))
    self._p_btn_img = self:Image("p_btn")
    self._p_icon = self:Image("p_icon")
    self._p_text = self:Text("p_text")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_img_select = self:GameObject("p_img_select")
    self._p_text_current = self:Text("p_text_current", "current")
end

---@param data AllianceAppointmentCellData
function AllianceAppointmentCell:OnFeedData(data)
    local rank = data.Rank
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetRankIcon(rank), self._p_icon)
    self._p_text.text = AllianceModuleDefine.GetRankName(rank)
    self._p_text_current:SetVisible(data.IsCurrent)
    if data.maxCount < 0 then
        self._p_text_quantity.text = string.format("%s", data.currentCount)
    else
        self._p_text_quantity.text = string.format("%s/%s", data.currentCount, data.maxCount)
    end
    self._p_btn_img.color = AllianceModuleDefine.RColor[rank] or AllianceModuleDefine.DefaultRColor
end

function AllianceAppointmentCell:Select(param)
    self._p_img_select:SetVisible(true)
end

function AllianceAppointmentCell:UnSelect(param)
    self._p_img_select:SetVisible(false)
end

return AllianceAppointmentCell