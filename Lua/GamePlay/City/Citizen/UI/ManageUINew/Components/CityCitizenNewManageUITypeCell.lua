local BaseTableViewProCell = require ('BaseTableViewProCell')
local CityCitizenNewDefine = require('CityCitizenNewDefine')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Status = {Unselect = 0, Selected = 1}

---@class CityCitizenNewManageUITypeCell:BaseTableViewProCell
local CityCitizenNewManageUITypeCell = class('CityCitizenNewManageUITypeCell', BaseTableViewProCell)

---@class CityCitizenNewManageUITypeCellData
---@field icon string @图标
---@field toggleType number @类型 @see CityCitizenNewDefine.ManageToggleType
---@field onClick fun(number) @点击回调，参数传入自己的toggleType
---@field selected boolean @是否选中

function CityCitizenNewManageUITypeCell:OnCreate()
    self._statusRecordParent = self:StatusRecordParent("")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_icon_a = self:Image("p_icon_a")
    self._p_icon_c = self:Image("p_icon_c")
    self._p_text_all = self:Text("p_text_all", "#ALL")

    self._normalColor = self._p_icon_a.color
    self._selectedColor = self._p_icon_c.color
end

---@param data CityCitizenNewManageUITypeCellData
function CityCitizenNewManageUITypeCell:OnFeedData(data)
    self._dataDirty = self._data ~= data
    self._data = data
    self._statusRecordParent:ApplyStatusRecord(self._data.selected and Status.Selected or Status.Unselect)
    if self._data.toggleType == CityCitizenNewDefine.ManageToggleType.All then
        self._p_icon_c:SetVisible(false)
        self._p_icon_a:SetVisible(false)
        self._p_text_all:SetVisible(true)
        self._p_text_all.color = self._data.selected and self._selectedColor or self._normalColor
    end
    if self._dataDirty then
        g_Game.SpriteManager:LoadSprite(self._data.icon, self._p_icon_a)
        g_Game.SpriteManager:LoadSprite(self._data.icon, self._p_icon_c)
    end
end

function CityCitizenNewManageUITypeCell:OnClick()
    if self._data.onClick then
        self._data.onClick(self._data.toggleType)
    end
end

return CityCitizenNewManageUITypeCell