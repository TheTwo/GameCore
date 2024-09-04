local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceWarTabButtonData
---@field index number
---@field text string
---@field selected boolean
---@field isLocked boolean
---@field onClick fun(index)

---@class AllianceWarTabButton:BaseUIComponent
---@field new fun():AllianceWarTabButton
---@field super BaseUIComponent
local AllianceWarTabButton = class('AllianceWarTabButton', BaseUIComponent)

function AllianceWarTabButton:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    ---@type CS.StatusRecordParent
    self._selfStatus = self:BindComponent("", typeof(CS.StatusRecordParent))
    self._p_text_b = self:Text("p_text_b")
    self._p_text_a = self:Text("p_text_a")
    self._p_text_c = self:Text("p_text_c")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param data AllianceWarTabButtonData
function AllianceWarTabButton:OnFeedData(data)
    self._data = data
    if data.isLocked then
        self._selfStatus:SetState(2)
        self._child_reddot_default:SetVisible(false)
    else
        self._selfStatus:SetState(data.selected and 0 or 1)
    end
    self._p_text_a.text = data.text
    self._p_text_b.text = data.text
    self._p_text_c.text = data.text
end

function AllianceWarTabButton:SetSelected(selected)
    if self._data.isLocked then
        return
    end
    self._data.selected = selected
    self._selfStatus:SetState(self._data.selected and 0 or 1)
end

function AllianceWarTabButton:OnClickSelf()
    if self._data.onClick then
        self._data.onClick(self._data.index)
    end
end

return AllianceWarTabButton